# Tools to compare the weights of different coupling measures on the same
# corpus. The measures of this package are all functions of a few quantities
# (number of shared references, length of the bibliographies, frequency of the
# references), but they do not have the same scale nor the same distribution:
# a cosine is bounded by 1, a coupling strength is not. Comparing them
# therefore requires looking at distributions and ranks, not raw values.

compute_couplings <- function(dt, source, ref, methods = c("angle", "strength", "similarity", "jaccard", "vladutz"), weight_threshold = 1, network = c("coupling", "cocitation"))
{
  #' Compute several coupling (or co-citation) measures at once
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Computes several measures of bibliographic coupling (or of co-citation)
  #' on the same table of citations and returns a named list of edge tables,
  #' ready for [summarise_weights()], [correlate_weights()],
  #' [overlap_top_weights()], [merge_weights()] and [plot_weights()]. The
  #' costly step (finding all the pairs of nodes that share a reference) is
  #' done only once, so computing the five measures costs little more than
  #' computing one.
  #'
  #' @section Why use it in research:
  #' The choice of a measure is a modelling choice, not a technical detail: it
  #' determines which pairs of documents look close, and thus the communities
  #' found. \insertCite{shen2019}{biblionetwork} show on one corpus that the
  #' measures can be very close (coupling angle and similarity) or quite
  #' different (Vladutz-Cook and the others). Whether it matters for *your*
  #' corpus can only be checked on your corpus: compute the measures with this
  #' function, and compare the distributions and the rankings of the weights.
  #' `vignette("comparing_measures")` does it on the stagflation corpus.
  #'
  #' @inheritParams biblio_coupling
  #' @param methods Character vector, among `"angle"` ([biblio_coupling()]),
  #'   `"strength"` ([coupling_strength()]), `"similarity"`
  #'   ([coupling_similarity()]), `"jaccard"` ([coupling_jaccard()]) and
  #'   `"vladutz"` ([coupling_vladutz()]).
  #' @param network `"coupling"` (default): the nodes are the documents of
  #'   `source`. `"cocitation"`: the nodes are the references of `ref`, and
  #'   the measures are those of [biblio_cocitation()].
  #'
  #' @return A named list with one `data.table` per method, each with columns
  #'   `Source`, `Target` and `weight`. All the tables describe the same
  #'   pairs of nodes (those sharing at least `weight_threshold` references,
  #'   or co-cited at least `weight_threshold` times), in the same order.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation,
  #'                            source = "Citing_ItemID_Ref",
  #'                            ref = "ItemID_Ref",
  #'                            weight_threshold = 2)
  #' names(edges)
  #' summarise_weights(edges)
  #' correlate_weights(edges)
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  Source <- Target <- NULL

  if (!is.character(methods) || length(methods) == 0 || !all(methods %in% coupling_methods)) {
    cli::cli_abort(c(
      "{.arg methods} must be a subset of the available measures.",
      "i" = "Possible values: {.val {coupling_methods}}."
    ))
  }
  methods <- unique(methods)
  network <- rlang::arg_match(network)
  check_threshold(weight_threshold)

  pairs <- if (network == "coupling") {
    coupling_core(dt, source, ref, weight_threshold, needs = coupling_needs(methods))
  } else {
    coupling_core(dt, ref, source, weight_threshold, needs = coupling_needs(methods),
                  nodes = "references")
  }
  data.table::setorder(pairs, Source, Target)

  lapply(
    stats::setNames(methods, methods),
    function(method) {
      data.table::data.table(Source = pairs$Source, Target = pairs$Target,
                             weight = coupling_weights(pairs, method))
    }
  )
}

# Checks that `edges` is a named list of edge tables and returns it as a list of data.tables
check_edge_list <- function(edges, min_length = 1, call = rlang::caller_env()) {
  if (!is.list(edges) || is.data.frame(edges) || length(edges) < min_length ||
      is.null(names(edges)) || any(names(edges) == "") || anyDuplicated(names(edges)) > 0) {
    cli::cli_abort(
      c("{.arg edges} must be a named list of at least {min_length} edge table{?s}.",
        "i" = "Build it with {.fn compute_couplings}, or with {.code list(angle = biblio_coupling(...), strength = coupling_strength(...))}."),
      call = call
    )
  }
  lapply(edges, function(x) {
    if (!is.data.frame(x)) {
      cli::cli_abort("Every element of {.arg edges} must be a data frame.", call = call)
    }
    check_columns(x, c("Source", "Target", "weight"), "each element of `edges`", call = call)
    data.table::as.data.table(x)[, c("Source", "Target", "weight"), with = FALSE]
  })
}

merge_weights <- function(edges)
{
  #' Put the weights of several measures side by side
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Joins a named list of edge tables (for instance the result of
  #' [compute_couplings()]) by pair of nodes, with one column of weights per
  #' element. It is the table behind the other comparison functions, and
  #' is useful to inspect the pairs on which two measures disagree.
  #'
  #' @param edges A named list of edge tables, each with the columns `Source`,
  #'   `Target` and `weight`. The tables are not modified.
  #'
  #' @return A `data.table` with `Source`, `Target` and one column per element
  #'   of `edges`. A pair absent from a table (for instance because tables were
  #'   built with different thresholds) gets `NA`.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                            methods = c("angle", "strength"), weight_threshold = 2)
  #' head(merge_weights(edges))
  #'
  #' @export

  Source <- Target <- NULL
  edges <- check_edge_list(edges)
  tables <- Map(function(x, name) {
    x <- data.table::copy(x)
    data.table::setnames(x, "weight", name)
    x
  }, edges, names(edges))
  merged <- Reduce(function(a, b) merge(a, b, by = c("Source", "Target"), all = TRUE), tables)
  data.table::setorder(merged, Source, Target)
  merged
}

summarise_weights <- function(edges, probs = c(0.01, 0.25, 0.5, 0.75, 0.99))
{
  #' Summarise the distribution of the weights of each measure
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Describes the distribution of the weights of each measure: number of
  #' edges, mean, standard deviation, extremes, quantiles, and the share of
  #' weights equal to zero. \insertCite{shen2019}{biblionetwork} compare the
  #' measures through the shape of their distributions (they report a smooth,
  #' right-skewed distribution, well fitted by a lognormal, for the idf-weighted
  #' similarity, and more scattered and irregular ones for the other measures
  #' except the raw count), which matters when the weights are used by a
  #' community detection algorithm or filtered by a threshold. Read the
  #' summaries with the scales in mind: a cosine is bounded by 1, the
  #' coupling strength is not, so means and quantiles of different measures are
  #' not comparable. The `ratio_q99_median` column, a scale-free indicator of
  #' how heavy the right tail is, is.
  #'
  #' @param edges A named list of edge tables with a `weight` column, for
  #'   instance from [compute_couplings()].
  #' @param probs Numeric vector of probabilities for the quantiles.
  #'
  #' @return A `data.table` with one row per measure: `method`, `n_edges`,
  #'   `mean`, `sd`, `min`, one column per quantile (`q01`, `q25`...), `max`,
  #'   `share_zero` and `ratio_q99_median`.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                            weight_threshold = 2)
  #' summarise_weights(edges)
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  edges <- check_edge_list(edges)
  if (!is.numeric(probs) || anyNA(probs) || any(probs < 0 | probs > 1)) {
    cli::cli_abort("{.arg probs} must be a numeric vector of probabilities between 0 and 1.")
  }
  rows <- lapply(names(edges), function(name) {
    w <- edges[[name]]$weight
    q <- if (length(w) > 0) stats::quantile(w, probs = probs, names = FALSE) else rep(NA_real_, length(probs))
    names(q) <- sprintf("q%02d", round(100 * probs))
    q99 <- if (length(w) > 0) stats::quantile(w, 0.99, names = FALSE) else NA_real_
    med <- if (length(w) > 0) stats::median(w) else NA_real_
    data.table::data.table(
      method = name,
      n_edges = length(w),
      mean = if (length(w) > 0) mean(w) else NA_real_,
      sd = if (length(w) > 1) stats::sd(w) else NA_real_,
      min = if (length(w) > 0) min(w) else NA_real_,
      data.table::as.data.table(as.list(q)),
      max = if (length(w) > 0) max(w) else NA_real_,
      share_zero = if (length(w) > 0) mean(w == 0) else NA_real_,
      ratio_q99_median = if (length(w) > 0 && isTRUE(med > 0)) q99 / med else NA_real_
    )
  })
  data.table::rbindlist(rows)
}

correlate_weights <- function(edges, method = c("spearman", "pearson", "kendall"))
{
  #' Correlate the weights of several measures
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Computes the correlation between the weights of each pair of measures,
  #' over the pairs of nodes present in all the tables, as
  #' \insertCite{shen2019}{biblionetwork} do with Pearson correlations. The
  #' default is the Spearman rank correlation, which compares the *rankings*
  #' of the pairs and does not depend on the scale of the weights: it is the
  #' relevant one when the weights are only used to order or filter edges, as
  #' in most community detection settings. Pearson correlations (the paper's
  #' choice) are sensitive to the scale and to extreme values, and thus differ
  #' much more between a bounded cosine and an unbounded strength.
  #'
  #' @param edges A named list of at least two edge tables, for instance from
  #'   [compute_couplings()].
  #' @param method `"spearman"` (default), `"pearson"` or `"kendall"`.
  #'
  #' @return A correlation matrix, with the number of pairs of nodes used in
  #'   the attribute `"n_pairs"`.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                            weight_threshold = 2)
  #' correlate_weights(edges)
  #' correlate_weights(edges, method = "pearson")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  method <- rlang::arg_match(method)
  edges <- check_edge_list(edges, min_length = 2)
  wide <- merge_weights(edges)
  methods <- names(edges)
  wide <- wide[stats::complete.cases(wide[, methods, with = FALSE])]
  if (nrow(wide) < 2) {
    cli::cli_abort("Fewer than two pairs of nodes are present in all the tables: no correlation can be computed.")
  }
  correlations <- suppressWarnings(
    stats::cor(as.data.frame(wide[, methods, with = FALSE]), method = method)
  )
  attr(correlations, "n_pairs") <- nrow(wide)
  correlations
}

overlap_top_weights <- function(edges, top = 0.1)
{
  #' Overlap between the strongest edges of several measures
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' For each pair of measures, the Jaccard index between the sets of their
  #' strongest edges (the `top` share of the edges with the highest weights).
  #' Correlations summarise all the edges, but a network analysis often relies
  #' on the strongest ones (after a filtering of the weak ties). This function
  #' tells how many of the strongest ties two measures have in common:
  #' 1 means the same strongest edges, 0 none in common.
  #'
  #' @param edges A named list of at least two edge tables, for instance from
  #'   [compute_couplings()].
  #' @param top Share of edges kept for each measure, between 0 and 1 (0.1 by
  #'   default: the top 10% of the edges). Ties at the threshold are all kept.
  #'
  #' @return A symmetric matrix of Jaccard indices, with the number of edges
  #'   kept by each measure in the attribute `"n_top"`.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                            weight_threshold = 2)
  #' overlap_top_weights(edges, top = 0.1)
  #'
  #' @export

  if (!is.numeric(top) || length(top) != 1 || is.na(top) || top <= 0 || top > 1) {
    cli::cli_abort("{.arg top} must be a number in ]0, 1].")
  }
  edges <- check_edge_list(edges, min_length = 2)
  wide <- merge_weights(edges)
  methods <- names(edges)
  wide <- wide[stats::complete.cases(wide[, methods, with = FALSE])]
  if (nrow(wide) == 0) {
    cli::cli_abort("No pair of nodes is present in all the tables.")
  }
  # The identifiers of the strongest edges of each measure; ties at the
  # threshold are kept
  n_keep <- max(1, ceiling(top * nrow(wide)))
  top_sets <- lapply(methods, function(m) {
    w <- wide[[m]]
    which(w >= sort(w, decreasing = TRUE)[n_keep])
  })
  names(top_sets) <- methods
  overlap <- outer(methods, methods, Vectorize(function(a, b) {
    length(intersect(top_sets[[a]], top_sets[[b]])) / length(union(top_sets[[a]], top_sets[[b]]))
  }))
  dimnames(overlap) <- list(methods, methods)
  attr(overlap, "n_top") <- vapply(top_sets, length, integer(1))
  overlap
}

plot_weights <- function(edges, type = c("distribution", "scatter"), x = NULL, y = NULL, bins = 50)
{
  #' Plot the weights of several coupling measures
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Two plots to compare coupling measures, in the spirit of the histograms
  #' and scatterplots of \insertCite{shen2019}{biblionetwork}:
  #'
  #' * `type = "distribution"`: one histogram of the weights per measure, each
  #'   with its own horizontal scale (the measures do not share a scale);
  #' * `type = "scatter"`: the ranks of the pairs of nodes according to two
  #'   measures (`x` and `y`). Points on the diagonal are ranked identically by
  #'   both measures; ranks, rather than raw weights, are used because the
  #'   scales differ.
  #'
  #' It needs the `ggplot2` and `scico` packages.
  #'
  #' @param edges A named list of edge tables, for instance from
  #'   [compute_couplings()].
  #' @param type `"distribution"` (default) or `"scatter"`.
  #' @param x,y For `type = "scatter"`, the names of the two measures in
  #'   `edges` (by default the first two).
  #' @param bins Number of bins of the histograms.
  #'
  #' @return A `ggplot` object.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examplesIf requireNamespace("ggplot2", quietly = TRUE) && requireNamespace("scico", quietly = TRUE)
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                            weight_threshold = 2)
  #' plot_weights(edges)
  #' plot_weights(edges, type = "scatter", x = "angle", y = "strength")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  method <- weight <- rank_x <- rank_y <- NULL

  type <- rlang::arg_match(type)
  rlang::check_installed(c("ggplot2", "scico"), reason = "to plot the weights.")
  edges <- check_edge_list(edges)

  if (type == "distribution") {
    long <- data.table::rbindlist(lapply(names(edges), function(name) {
      data.table::data.table(method = name, weight = edges[[name]]$weight)
    }))
    long[, method := factor(method, levels = names(edges))]
    ggplot2::ggplot(long, ggplot2::aes(x = weight, fill = method)) +
      ggplot2::geom_histogram(bins = bins, show.legend = FALSE) +
      ggplot2::facet_wrap(ggplot2::vars(method), scales = "free") +
      scico::scale_fill_scico_d(palette = "batlow") +
      ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.02))) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.05))) +
      ggplot2::labs(x = "Weight", y = "Number of edges") +
      ggplot2::theme_minimal(base_size = 16)
  } else {
    if (length(edges) < 2) {
      cli::cli_abort("A scatter plot needs at least two measures in {.arg edges}.")
    }
    x <- if (is.null(x)) names(edges)[1] else x
    y <- if (is.null(y)) names(edges)[2] else y
    if (!all(c(x, y) %in% names(edges))) {
      cli::cli_abort("{.arg x} and {.arg y} must be names of {.arg edges}: {.val {names(edges)}}.")
    }
    wide <- merge_weights(edges[unique(c(x, y))])
    wide <- wide[stats::complete.cases(wide[, unique(c(x, y)), with = FALSE])]
    plot_data <- data.frame(
      rank_x = rank(wide[[x]]) / nrow(wide),
      rank_y = rank(wide[[y]]) / nrow(wide)
    )
    ggplot2::ggplot(plot_data, ggplot2::aes(x = rank_x, y = rank_y)) +
      ggplot2::geom_point(alpha = 0.3, colour = scico::scico(1, palette = "batlow", begin = 0.2)) +
      ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
      ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.01, 0.02))) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.01, 0.02))) +
      ggplot2::labs(x = paste("Rank according to", x), y = paste("Rank according to", y)) +
      ggplot2::theme_minimal(base_size = 16)
  }
}
