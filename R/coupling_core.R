# The engine of the document-level coupling measures (coupling_angle(),
# coupling_strength(), coupling_similarity(), coupling_jaccard(),
# coupling_vladutz(), compute_couplings()) and, with the two columns swapped,
# of the co-citation measures. All these measures are functions of the same
# few quantities for a pair of nodes A and B, so they are computed once here
# and each exported function only applies its formula.
#
# How it works. Write B for the sparse matrix with one row per node (citing
# document) and one column per reference, B[i, j] = 1 if i cites j. For a
# weight w_j per reference, the matrix B diag(w) t(B) has, in (A, B), the sum
# of w_j over the references shared by A and B. With w = 1 it is the number
# of shared references; with w = log(N / f_j) the numerator of the coupling
# strength; with w = 1 / f_j the Vladutz-Cook sum. A cross-product of sparse
# matrices computes these sums for all the pairs at once, in compiled code,
# and only stores the pairs that share at least one reference. The previous
# implementation listed, for each reference cited by n documents, its
# n (n - 1) / 2 pairs in a table, and then counted them: a pair sharing k
# references was stored k times, with character identifiers, so that memory
# use was several times larger (see tests/benchmarks in NEWS.md).
#
# Returns a data.table with one row per pair of nodes sharing at least
# `weight_threshold` references, with:
#   Source, Target   the oriented pair (Source < Target)
#   N                number of shared references
#   sum_idf          sum over shared references of log(N_nodes / f_j)   [if "idf" in `needs`]
#   sum_inv_freq     sum over shared references of 1 / f_j              [if "inv_freq" in `needs`]
#   nb_ref_*         L(A): length of the bibliography of each node
#   Rs_*             S(A): sum of log(N_nodes / f_j) over ALL the references [if "Rs" in `needs`]
# with f_j the number of nodes linked to reference j. Only the quantities
# listed in `needs` are computed (each costs one more matrix product). If no
# pair is left, it warns (class `biblionetwork_no_edges`) and returns a
# zero-row table.
coupling_core <- function(dt, source, ref, weight_threshold,
                          needs = c("idf", "inv_freq", "Rs"),
                          nodes = "documents", call = rlang::caller_env()) {
  Source <- Target <- sum_idf <- sum_inv_freq <- NULL

  links <- prepare_links(dt, source, ref, call = call)

  # Sorting the identifiers makes the order of the indices the order of the
  # values: a pair (i, j) with i < j is oriented Source < Target.
  nodes_id <- sort(unique(links$id_art))
  refs_id <- unique(links$id_ref)
  i <- match(links$id_art, nodes_id)
  j <- match(links$id_ref, refs_id)
  nb_nodes <- length(nodes_id)

  # f_j: how many nodes are linked to each reference; L(A): the length of each
  # bibliography. N_nodes counts all the nodes, even those sharing nothing.
  f <- tabulate(j, nbins = length(refs_id))
  idf <- log(nb_nodes / f)
  nb_ref <- as.numeric(tabulate(i, nbins = nb_nodes))  # numeric: products of lengths can exceed the integer range
  Rs <- if ("Rs" %in% needs) rowsum(idf[j], i, reorder = TRUE)[, 1] else NULL

  # References cited once cannot create a tie
  refs_kept <- which(f > 1)
  shared <- f[j] > 1
  i <- i[shared]
  j <- match(j[shared], refs_kept)
  f_shared <- f[refs_kept]
  n_shared_refs <- length(f_shared)

  pairs <- NULL
  max_shared <- 0L
  if (n_shared_refs > 0) {
    # Number of shared references of every pair of nodes: B t(B)
    incidence <- function(x) Matrix::sparseMatrix(i = i, j = j, x = x, dims = c(nb_nodes, n_shared_refs))
    counts <- sparse_pairs(Matrix::tcrossprod(incidence(rep(1, length(i)))))
    max_shared <- if (length(counts$x) > 0) as.integer(max(counts$x)) else 0L
    above <- counts$x >= weight_threshold
    pairs <- data.table::data.table(i = counts$i[above], j = counts$j[above], N = as.integer(counts$x[above]))

    # Weighted sums over the shared references, B diag(w) t(B), computed as
    # the cross-product of B diag(sqrt(w)) with itself
    weighted_sum <- function(w) {
      product <- sparse_pairs(Matrix::tcrossprod(incidence(sqrt(w[j]))))
      if (identical(product$shape, counts$shape)) {
        values <- product$x[above]
      } else {
        # different patterns (a product dropped the zeros of idf = 0): match the cells
        nb <- counts$nrow
        values <- product$x[match((counts$i[above] - 1) * nb + counts$j[above],
                                  (product$i - 1) * nb + product$j)]
        # an entry absent from the product is a sum of zeros
        values[is.na(values)] <- 0
      }
      values
    }
    if (nrow(pairs) > 0) {
      if ("idf" %in% needs) pairs[, sum_idf := weighted_sum(log(nb_nodes / f_shared))]
      if ("inv_freq" %in% needs) pairs[, sum_inv_freq := weighted_sum(1 / f_shared)]
    }
  }

  if (is.null(pairs) || nrow(pairs) == 0) {
    warn_no_edges(
      max_shared, weight_threshold,
      none = paste0("No two ", nodes, " share a reference: nothing can be linked."),
      unit = "shared references",
      hint = "Check that {.arg source} and {.arg ref} are not inverted, and that references have the same identifiers across documents (same format, same database).",
      call = call
    )
    pairs <- data.table::data.table(i = integer(), j = integer(), N = integer())
    for (col in intersect(c("idf", "inv_freq"), needs)) {
      pairs[, (c(idf = "sum_idf", inv_freq = "sum_inv_freq")[[col]]) := numeric()]
    }
  }

  pairs[, `:=`(Source = nodes_id[i], Target = nodes_id[j],
               nb_ref_Source = nb_ref[i], nb_ref_Target = nb_ref[j])]
  if (!is.null(Rs)) pairs[, `:=`(Rs_Source = Rs[i], Rs_Target = Rs[j])]
  pairs[, c("i", "j") := NULL]
  data.table::setcolorder(pairs, c("Source", "Target"))
  pairs
}

# The pairs (i < j) stored in a sparse product, with their values. `shape` is
# the sparsity pattern: two products with the same shape (the usual case, as
# B and B diag(sqrt(w)) have the same non-zero cells) have their entries in the
# same order, which saves matching them.
sparse_pairs <- function(product) {
  product <- methods::as(product, "CsparseMatrix")
  i <- product@i + 1L
  j <- rep.int(seq_len(ncol(product)), diff(product@p))
  # a symmetric matrix stores one triangle; orient the pairs in all cases
  lower <- pmin(i, j)
  upper <- pmax(i, j)
  keep <- lower != upper
  if (!methods::is(product, "symmetricMatrix")) {
    keep <- keep & i < j
  }
  list(i = lower[keep], j = upper[keep], x = product@x[keep], keep = keep,
       shape = list(product@i, product@p), nrow = nrow(product))
}

# Sum over the shared features of x for every pair of nodes: the matrix
# B diag(x) t(B), as the cross-product of B diag(sqrt(x)) with itself, where
# B[node, feature] = 1 for each link (i, j). Returns the pairs (i < j) stored.
sparse_product <- function(i, j, x, nb_nodes, nb_features) {
  incidence <- Matrix::sparseMatrix(i = i, j = j, x = sqrt(x), dims = c(nb_nodes, nb_features))
  out <- sparse_pairs(Matrix::tcrossprod(incidence))
  out$nb_nodes <- nb_nodes
  out
}

# The values of the product `b` at the pairs of the product `a` (0 if absent)
match_pairs <- function(a, b) {
  values <- b$x[match((a$i - 1) * a$nb_nodes + a$j, (b$i - 1) * b$nb_nodes + b$j)]
  values[is.na(values)] <- 0
  values
}

# The measures computed from the output of coupling_core(), and the extra
# quantities each of them needs (`needs` of coupling_core()).
coupling_methods <- c("angle", "strength", "similarity", "jaccard", "vladutz")

coupling_needs <- function(methods) {
  c(
    if (any(c("strength", "similarity") %in% methods)) "idf",
    if ("similarity" %in% methods) "Rs",
    if ("vladutz" %in% methods) "inv_freq"
  )
}

# The weight of every pair of `pairs` (a table made by coupling_core()) for a method
coupling_weights <- function(pairs, method) {
  N <- sum_idf <- sum_inv_freq <- nb_ref_Source <- nb_ref_Target <- Rs_Source <- Rs_Target <- NULL
  switch(
    method,
    angle = pairs[, N / sqrt(nb_ref_Target * nb_ref_Source)],
    strength = pairs[, sum_idf / (nb_ref_Target * nb_ref_Source)],
    similarity = {
      # S = 0 only if all the references of a document are cited by all the
      # documents (so is sum_idf): 0 / 0 is set to 0
      w <- pairs[, sum_idf / sqrt(Rs_Target * Rs_Source)]
      w[is.nan(w)] <- 0
      w
    },
    jaccard = pairs[, N / (nb_ref_Target + nb_ref_Source - N)],
    vladutz = pairs[, 4 / (nb_ref_Target + nb_ref_Source) * sum_inv_freq]
  )
}

# A clear warning when a function finds no tie. It tells the user why, since
# the usual causes (a threshold that is too high, a corpus without overlap, an
# inverted `source` and `ref`) have different solutions.
#   max_shared  the largest number of shared items found before the threshold
#   none        what it means that nothing is shared (message)
#   unit        what is counted by the threshold, e.g. "shared references"
warn_no_edges <- function(max_shared, weight_threshold, none, unit,
                          hint = NULL, call = rlang::caller_env()) {
  if (max_shared == 0) {
    cause <- c("x" = none, if (!is.null(hint)) c("i" = hint))
  } else {
    cause <- c(
      "x" = paste0("No pair has at least ", weight_threshold, " ", unit, "."),
      "i" = paste0("The largest number of ", unit, " in a pair is ", max_shared,
                   ": lower {.arg weight_threshold}.")
    )
  }
  cli::cli_warn(
    c("No edge found: a table with zero rows is returned.", cause),
    class = "biblionetwork_no_edges",
    call = call
  )
}
