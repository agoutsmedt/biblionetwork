# Tokenising titles into sets of terms (lower case words, without stop words)
title_terms <- function(titles, stopwords = NULL) {
  titles[is.na(titles)] <- ""
  terms <- strsplit(tolower(titles), "[^\\p{L}\\p{N}]+", perl = TRUE)
  lapply(terms, function(x) setdiff(x[nchar(x) > 0], stopwords))
}

# One title per reference: the first one (with a warning if a reference has several)
reference_titles <- function(dt, ref, title, call = rlang::caller_env()) {
  id_ref <- N <- NULL
  titles <- unique(data.table::as.data.table(dt)[, c(ref, title), with = FALSE])
  data.table::setnames(titles, c("id_ref", "title"))
  titles <- titles[!is.na(id_ref)]
  n_conflicts <- titles[, .N, by = id_ref][N > 1, .N]
  if (n_conflicts > 0) {
    cli::cli_warn(
      "{n_conflicts} reference{?s} ha{?s/ve} several different titles: the first one is used.",
      call = call
    )
  }
  titles[!duplicated(id_ref)]
}

coupling_descriptive <- function(dt, source, ref, title, targets = NULL, min_weight = 0, output_in_character = TRUE, stopwords = NULL, max_documents = 5000)
{
  #' Bibliographic coupling edges using the titles of the references (DescriptiveBC)
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' The *DescriptiveBC* measure of \insertCite{liu2017}{biblionetwork}. In the
  #' standard bibliographic coupling, two references are either the same or
  #' completely different. Here two *different* references can be partly
  #' similar if their titles share words, so that two documents can be coupled
  #' even if they cite few identical references.
  #'
  #' @section Why use it in research:
  #' Two papers on the same question often cite different but related works
  #' (the same idea in a working paper and in a journal article, two papers on
  #' the same model). Classical coupling misses them, and the sparsity of
  #' citations makes it dominated by a few shared references
  #' \insertCite{liu2017}{biblionetwork}. Using the words of the titles of the
  #' references recovers part of this relatedness. It also lets you say *why*
  #' two documents are related: see [descriptive_terms()]. The price is a
  #' dependence on the quality of the titles (language, abbreviations, missing
  #' titles) and a much higher computing cost, since almost any two documents
  #' can have some similarity (see below). Liu evaluates the measure on
  #' biomedical articles, against expert judgements of relatedness: check on
  #' your own field that title words are informative (in the social sciences
  #' titles are often metaphorical).
  #'
  #' @section Intuition:
  #' Imagine that you compare two reading lists, and that you are allowed to
  #' match each book of the first list with its *closest* book in the second:
  #' the same book is a perfect match (1), a book whose title shares half of its
  #' words is a half match, unrelated titles do not match (0). The measure is
  #' the average quality of the best matches, in both directions.
  #'
  #' @details
  #' The similarity of two references \eqn{r_1} and \eqn{r_2} is 1 if they are
  #' the same reference, and otherwise the Jaccard index of the sets of terms
  #' of their titles,
  #' \eqn{\mathrm{Sim}(r_1, r_2) = |T(r_1) \cap T(r_2)| / |T(r_1) \cup T(r_2)|}.
  #' The weight between documents \eqn{A} and \eqn{B}, with reference sets
  #' \eqn{R_A} and \eqn{R_B}, is
  #'
  #' \deqn{w_{AB} = \frac{\sum_{r \in R_A} \max_{r' \in R_B} \mathrm{Sim}(r, r') + \sum_{r' \in R_B} \max_{r \in R_A} \mathrm{Sim}(r, r')}{|R_A| + |R_B|}}
  #'
  #' (Eq. 5 of the paper). It lies between 0 and 1. If no two references are
  #' similar except identical ones, it is \eqn{2 |R_A \cap R_B| / (|R_A| + |R_B|)},
  #' the Dice coefficient of the bibliographies.
  #'
  #' Terms are the words of the titles, in lower case, without the
  #' `stopwords` that you give (for instance `stopwords::stopwords("en")`):
  #' without them, words such as "the" or "of" create similarities between
  #' unrelated titles. The paper does not specify other pre-processing (no
  #' stemming here). A reference without title is only similar to itself. If a
  #' reference has several titles in the table, the first is used, with a
  #' warning.
  #'
  #' *Computing cost.* Unlike the other coupling measures, there is no
  #' natural set of candidate pairs: two documents sharing no reference can be
  #' similar through the words of the titles. All the pairs of documents are
  #' therefore potentially concerned, and the cost grows with the square of the
  #' number of documents. The function (i) computes the similarity of the pairs
  #' of references sharing a term with sparse matrices, and (ii) for each
  #' target document, finds the best matches of its references. With a very
  #' large corpus, give the `targets` (the documents for which you want the
  #' neighbours, as in the paper, where each article is compared with
  #' candidates) or restrict the corpus by time windows. Removing stop words
  #' reduces the number of similar references a lot. By default, more than
  #' `max_documents` documents without `targets` is an error.
  #'
  #' @inheritParams coupling_angle
  #' @param title Character scalar. The column with the title of the cited
  #'   reference (one title per reference).
  #' @param targets Optional vector of identifiers of documents (values of
  #'   `source`). If given, only the pairs involving at least one target are
  #'   computed.
  #' @param min_weight Number. Only pairs with a weight strictly above it are
  #'   returned (0 by default: all the pairs with some similarity). There is no
  #'   `weight_threshold` here, since two documents need not share any reference.
  #' @param stopwords Character vector of words to ignore in the titles
  #'   (`NULL`: none).
  #' @param max_documents Number. The maximum number of documents allowed
  #'   without `targets`.
  #'
  #' @return A `data.table` with one row per pair of documents with a weight
  #'   above `min_weight`: `from` and `to` (character if
  #'   `output_in_character = TRUE`), the `weight`, and the original
  #'   identifiers in `Source` and `Target` (`Source < Target`).
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' # a and b cite different references, with partly shared title words
  #' toy <- data.frame(
  #'   doc = c("a", "a", "b", "b"),
  #'   ref = c("r1", "r2", "r1", "r3"),
  #'   title = c("inflation expectations", "oil supply shocks",
  #'             "inflation expectations", "supply shocks prices")
  #' )
  #' # 1 for r1; r2 and r3 share 2 of 4 terms: w = (1 + 0.5 + 1 + 0.5) / 4
  #' coupling_descriptive(toy, source = "doc", ref = "ref", title = "title")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  id_ref <- N <- weight <- Source <- Target <- i <- j <- s <- r1 <- r2 <- m <- fwd <- bwd <- NULL

  check_bool(output_in_character, "output_in_character")
  if (!is.numeric(min_weight) || length(min_weight) != 1 || is.na(min_weight)) {
    cli::cli_abort("{.arg min_weight} must be a single number.")
  }
  if (!is.data.frame(dt)) cli::cli_abort("{.arg dt} must be a data frame or a data.table.")
  check_column_name(title, "title")
  check_columns(dt, c(source, ref, title), "dt")

  titles <- reference_titles(dt, ref, title)
  links <- prepare_links(dt, source, ref)
  nodes_id <- sort(unique(links$id_art))
  refs_id <- unique(links$id_ref)
  if (is.null(targets) && length(nodes_id) > max_documents) {
    cli::cli_abort(c(
      "{length(nodes_id)} documents are too many to compare all of them with the titles.",
      "i" = "Give {.arg targets}, split the corpus (for instance by time window), or raise {.arg max_documents}."
    ))
  }
  target_index <- if (is.null(targets)) seq_along(nodes_id) else match(targets, nodes_id)
  if (anyNA(target_index)) {
    cli::cli_abort("Some {.arg targets} are not documents of {.arg dt}.")
  }

  # Terms of the titles of the references, as a sparse reference x term matrix
  terms <- title_terms(titles$title[match(refs_id, titles$id_ref)], stopwords)
  term_id <- unique(unlist(terms))
  term_sizes <- lengths(terms)
  ref_similarity <- ref_similarity_table(terms, term_id, term_sizes, length(refs_id))

  li <- match(links$id_art, nodes_id)
  lj <- match(links$id_ref, refs_id)
  doc_length <- tabulate(li, nbins = length(nodes_id))
  by_ref <- data.table::data.table(j = lj, i = li)
  data.table::setkey(by_ref, j)
  by_reference <- split(lj, li)

  results <- lapply(target_index, function(a) {
    # similarities of the references of document a with all the references
    similar <- ref_similarity[list(by_reference[[as.character(a)]]), nomatch = NULL]
    # a's references -> best match in each other document b
    forward <- by_ref[similar, on = c(j = "r2"), allow.cartesian = TRUE, nomatch = NULL]
    forward <- forward[, list(m = max(s)), by = list(r1, i)][, list(fwd = sum(m)), by = i]
    # references of b -> best match among the references of a
    best <- similar[, list(m = max(s)), by = r2]
    backward <- by_ref[best, on = c(j = "r2"), allow.cartesian = TRUE, nomatch = NULL]
    backward <- backward[, list(bwd = sum(m)), by = i]
    both <- merge(forward, backward, by = "i", all = TRUE)
    both[is.na(fwd), fwd := 0]
    both[is.na(bwd), bwd := 0]
    both <- both[i != a]
    both[, list(i = pmin(i, a), j = pmax(i, a),
                weight = (fwd + bwd) / (doc_length[a] + doc_length[i]))]
  })
  # A pair compared from both of its documents appears twice, with weights that
  # are equal up to floating point error (unique() would keep both): keep one
  pairs <- data.table::rbindlist(results)
  pairs <- pairs[, list(weight = mean(weight)), by = list(i, j)]
  pairs <- pairs[weight > min_weight]

  if (nrow(pairs) == 0) {
    cli::cli_warn(
      c("No edge found: a table with zero rows is returned.",
        "x" = "No two documents have references with similar titles above {.arg min_weight}.",
        "i" = "Check the {.arg title} column and the {.arg stopwords}."),
      class = "biblionetwork_no_edges"
    )
  }
  edges <- data.table::data.table(Source = nodes_id[pairs$i], Target = nodes_id[pairs$j], weight = pairs$weight)
  finalise_edges(edges, output_in_character = output_in_character)
}

# Similarity of the pairs of references whose titles share a term (Eq. 3 of
# Liu 2017): the Jaccard index of the sets of terms; 1 for a reference with
# itself. Returns a table (r1, r2, s) keyed on r1, with both orientations.
ref_similarity_table <- function(terms, term_id, term_sizes, nb_refs) {
  r1 <- r2 <- s <- inter <- NULL
  identity <- data.table::data.table(r1 = seq_len(nb_refs), r2 = seq_len(nb_refs), s = 1)
  if (length(term_id) > 0 && sum(term_sizes) > 0) {
    incidence <- Matrix::sparseMatrix(
      i = rep.int(seq_len(nb_refs), term_sizes),
      j = match(unlist(terms), term_id),
      x = 1, dims = c(nb_refs, length(term_id))
    )
    shared <- methods::as(Matrix::tcrossprod(incidence), "TsparseMatrix")
    pairs <- data.table::data.table(r1 = shared@i + 1L, r2 = shared@j + 1L, inter = shared@x)
    pairs <- pairs[r1 != r2]
    if (methods::is(shared, "symmetricMatrix")) {
      pairs <- data.table::rbindlist(list(pairs, data.table::data.table(r1 = pairs$r2, r2 = pairs$r1, inter = pairs$inter)))
    }
    pairs[, s := inter / (term_sizes[r1] + term_sizes[r2] - inter)]
    identity <- data.table::rbindlist(list(identity, pairs[, list(r1, r2, s)]))
  }
  data.table::setkey(identity, r1)
  identity
}

descriptive_terms <- function(dt, source, ref, title, from, to, n_terms = 10, stopwords = NULL)
{
  #' Terms that describe why a document is related to another (DTerms)
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' The second contribution of \insertCite{liu2017}{biblionetwork}: given two
  #' documents, it extracts the words of the titles of the references of one
  #' (`to`) that best indicate in what respect it is related to the other
  #' (`from`). It complements [coupling_descriptive()]: the weight says *how
  #' much* two documents are related, the terms say *why*.
  #'
  #' @section Intuition:
  #' A document cites references for each of its issues. The references of
  #' `to` that have a close match among the references of `from` are the
  #' issues the two documents have in common, and the words of their titles
  #' name these issues. A word is a good descriptor if it appears in many
  #' references of `to`, and if these references are close to references of
  #' `from`.
  #'
  #' @details
  #' The descriptive strength of a term \eqn{t} is (Eq. 6 of the paper)
  #'
  #' \deqn{D(t) = \frac{\sum_{r' \in R_{to},\, t \in T(r')} \max_{r \in R_{from}} \mathrm{Sim}(r, r')}{|R_{to}|}}
  #'
  #' with \eqn{\mathrm{Sim}} the reference similarity of [coupling_descriptive()].
  #' The `n_terms` terms with the highest strength are returned (the paper
  #' suggests about 10, the length of a title). The relation is not symmetric:
  #' swap `from` and `to` to explain the relation the other way.
  #'
  #' @inheritParams coupling_descriptive
  #' @param from,to Identifiers of two documents (values of `source`).
  #' @param n_terms Number of terms to return.
  #'
  #' @return A `data.table` with the `term` and its `strength`, in decreasing order.
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' toy <- data.frame(
  #'   doc = c("a", "a", "b", "b"),
  #'   ref = c("r1", "r2", "r1", "r3"),
  #'   title = c("inflation expectations", "oil supply shocks",
  #'             "inflation expectations", "supply shocks prices")
  #' )
  #' descriptive_terms(toy, "doc", "ref", "title", from = "a", to = "b")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  if (!is.data.frame(dt)) cli::cli_abort("{.arg dt} must be a data frame or a data.table.")
  check_column_name(title, "title")
  check_columns(dt, c(source, ref, title), "dt")
  titles <- reference_titles(dt, ref, title)
  links <- prepare_links(dt, source, ref)
  refs_from <- unique(links$id_ref[links$id_art == from])
  refs_to <- unique(links$id_ref[links$id_art == to])
  if (length(refs_from) == 0 || length(refs_to) == 0) {
    cli::cli_abort("{.arg from} and {.arg to} must be documents of {.arg dt} with references.")
  }
  terms_of <- function(refs) title_terms(titles$title[match(refs, titles$id_ref)], stopwords)
  terms_from <- terms_of(refs_from)
  terms_to <- terms_of(refs_to)

  # best similarity of each reference of `to` with the references of `from`
  best <- vapply(seq_along(refs_to), function(k) {
    max(vapply(seq_along(refs_from), function(l) {
      if (refs_to[k] == refs_from[l]) return(1)
      union_size <- length(union(terms_to[[k]], terms_from[[l]]))
      if (union_size == 0) 0 else length(intersect(terms_to[[k]], terms_from[[l]])) / union_size
    }, numeric(1)))
  }, numeric(1))

  strength <- tapply(rep(best, lengths(terms_to)), unlist(terms_to), sum) / length(refs_to)
  strength <- strength[order(-strength, names(strength))]
  strength <- utils::head(strength, n_terms)
  data.table::data.table(term = names(strength), strength = as.numeric(strength))
}
