# Tools to compare the weights of different coupling measures on the same
# corpus. The measures of this package are all functions of a few quantities
# (number of shared references, length of the bibliographies, frequency of the
# references), but they do not have the same scale nor the same distribution:
# a cosine is bounded by 1, a coupling strength is not. Comparing them
# therefore requires looking at distributions and ranks, not raw values.

compute_couplings <- function(dt, source, ref, methods = c("angle", "strength", "similarity", "jaccard", "vladutz"), weight_threshold = 1, network = c("coupling", "cocitation"), title = NULL, descriptive_args = list())
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
  #' The article [comparing the measures](https://agoutsmedt.github.io/biblionetwork/articles/comparing_measures.html) does it on the stagflation corpus.
  #'
  #' @inheritParams coupling_angle
  #' @param methods Character vector, among `"angle"` ([coupling_angle()]),
  #'   `"strength"` ([coupling_strength()]), `"similarity"`
  #'   ([coupling_similarity()]), `"jaccard"` ([coupling_jaccard()]),
  #'   `"vladutz"` ([coupling_vladutz()]) and `"descriptive"`
  #'   ([coupling_descriptive()]). The first five are computed by default;
  #'   `"descriptive"` is not, since it is much more costly (see the details),
  #'   and it needs `title`.
  #' @param title Character scalar. The column with the title of the cited
  #'   references, needed (only) for `methods` including `"descriptive"`.
  #' @param descriptive_args A list of further arguments for
  #'   [coupling_descriptive()] (`targets`, `stopwords`, `min_weight`,
  #'   `max_documents`).
  #' @param network `"coupling"` (default): the nodes are the documents of
  #'   `source`. `"cocitation"`: the nodes are the references of `ref`, and
  #'   the measures are those of [biblio_cocitation()].
  #'
  #' @details
  #' The five measures that start from the shared references are computed on
  #' the same pairs of nodes (those sharing at least `weight_threshold`
  #' references), so that their weights can be compared pair by pair.
  #' `"descriptive"` (the DescriptiveBC measure of
  #' \insertCite{liu2017}{biblionetwork}) is different in two ways. It
  #' couples documents that cite *different but related* references, so its
  #' pairs are not the same ones: any pair of documents with similar titles of
  #' references is concerned, whatever the number of shared references (the
  #' `weight_threshold` does not apply to it). And its cost grows with the
  #' square of the number of documents: the function informs you when you
  #' ask for it, and you should give `targets` or work on a time window for a
  #' large corpus. [merge_weights()] puts the tables side by side, with `NA`
  #' for the pairs a measure does not have.
  #'
  #' @return A named list with one `data.table` per method, each with columns
  #'   `Source`, `Target` and `weight`. The tables of the five measures
  #'   describe the same pairs of nodes (those sharing at least
  #'   `weight_threshold` references, or co-cited at least `weight_threshold`
  #'   times), in the same order. The table of `"descriptive"` has its own pairs.
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
  #' # The titles-based measure is not computed by default; it needs the titles of the references
  #' \donttest{
  #' toy <- data.frame(
  #'   doc = c("a", "a", "b", "b"),
  #'   ref = c("r1", "r2", "r1", "r3"),
  #'   title = c("inflation expectations", "oil supply shocks",
  #'             "inflation expectations", "supply shocks prices")
  #' )
  #' compute_couplings(toy, "doc", "ref", methods = c("angle", "descriptive"), title = "title")
  #' }
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  Source <- Target <- NULL

  available <- c(coupling_methods, "descriptive")
  if (!is.character(methods) || length(methods) == 0 || !all(methods %in% available)) {
    cli::cli_abort(c(
      "{.arg methods} must be a subset of the available measures.",
      "i" = "Possible values: {.val {available}}."
    ))
  }
  methods <- unique(methods)
  network <- rlang::arg_match(network)
  check_threshold(weight_threshold)

  with_descriptive <- "descriptive" %in% methods
  if (with_descriptive) {
    if (network == "cocitation") {
      cli::cli_abort("{.val descriptive} is a measure of coupling: it cannot be used with {.code network = \"cocitation\"}.")
    }
    if (is.null(title)) {
      cli::cli_abort("{.arg title} (the column with the titles of the references) is needed for the {.val descriptive} measure.")
    }
    cli::cli_inform(c(
      "i" = "Computing the {.val descriptive} measure of Liu (2017), which is not part of the default measures.",
      "!" = "Its cost grows with the square of the number of documents, and its pairs are not those of the other measures: documents with no shared reference can be linked.",
      "i" = "For a large corpus, give {.code descriptive_args = list(targets = ...)} or work by time window."
    ), class = "biblionetwork_descriptive_cost")
  }

  core_methods <- setdiff(methods, "descriptive")
  weights <- list()
  if (length(core_methods) > 0) {
    pairs <- if (network == "coupling") {
      coupling_core(dt, source, ref, weight_threshold, needs = coupling_needs(core_methods))
    } else {
      coupling_core(dt, ref, source, weight_threshold, needs = coupling_needs(core_methods),
                    nodes = "references")
    }
    data.table::setorder(pairs, Source, Target)
    weights <- lapply(
      stats::setNames(core_methods, core_methods),
      function(method) {
        data.table::data.table(Source = pairs$Source, Target = pairs$Target,
                               weight = coupling_weights(pairs, method))
      }
    )
  }
  if (with_descriptive) {
    descriptive <- do.call(
      coupling_descriptive,
      c(list(dt = dt, source = source, ref = ref, title = title, output_in_character = FALSE), descriptive_args)
    )
    weights$descriptive <- data.table::data.table(Source = descriptive$Source, Target = descriptive$Target,
                                                  weight = descriptive$weight)
    data.table::setorder(weights$descriptive, Source, Target)
  }
  weights[methods]
}

# Checks that `edges` is a named list of edge tables and returns it as a list of data.tables
check_edge_list <- function(edges, min_length = 1, call = rlang::caller_env()) {
  if (!is.list(edges) || is.data.frame(edges) || length(edges) < min_length ||
      is.null(names(edges)) || any(names(edges) == "") || anyDuplicated(names(edges)) > 0) {
    cli::cli_abort(
      c("{.arg edges} must be a named list of at least {min_length} edge table{?s}.",
        "i" = "Build it with {.fn compute_couplings}, or with {.code list(angle = coupling_angle(...), strength = coupling_strength(...))}."),
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

merge_weights <- function(edges, rank = TRUE, rank_gap = NULL, ties = c("average", "min", "max", "first"))
{
  #' Put the weights of several measures side by side, with their ranks
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Joins a named list of edge tables (for instance the result of
  #' [compute_couplings()]) by pair of nodes, with one column of weights per
  #' element, and, by default, the rank of each pair under each measure and the
  #' gap between the ranks of two measures. It is the table behind the other
  #' comparison functions, and the tool to inspect the pairs on which two
  #' measures disagree.
  #'
  #' @details
  #' Weights of different measures do not have the same scale, but their ranks
  #' do: rank 1 is the strongest pair of the measure. A pair with a high weight
  #' for one measure and a low weight for another has a large *gap* between
  #' the two ranks. The gap is
  #'
  #' \deqn{\mathrm{rank\_gap}_{AB} = \mathrm{rank}_{2}(A, B) - \mathrm{rank}_{1}(A, B)}
  #'
  #' with 1 and 2 the first and second elements of `rank_gap`: it is positive
  #' when the second measure ranks the pair lower (as less close) than the
  #' first one, negative when it ranks it higher. Sorting the table on the gap
  #' (decreasing, then increasing) gives the pairs on which the measures
  #' disagree the most.
  #'
  #' Ranks are computed on the pairs present in *all* the tables, so that they
  #' are comparable: the pairs that a measure does not have (for instance
  #' those of [coupling_descriptive()], which links documents that share no
  #' reference) get `NA` ranks.
  #'
  #' @param edges A named list of edge tables, each with the columns `Source`,
  #'   `Target` and `weight`. The tables are not modified.
  #' @param rank Logical. If `TRUE` (default), adds one `rank_<name>` column per
  #'   element of `edges`.
  #' @param rank_gap Character vector of two names of `edges`, or `NULL`
  #'   (default). If given, adds the `rank_gap` column, `rank_<second> -
  #'   rank_<first>`. If `NULL` and `edges` has exactly two elements, the gap
  #'   between them (second minus first) is computed. It requires `rank = TRUE`.
  #' @param ties How ties are ranked, as in [data.table::frank()]
  #'   (`"average"` by default).
  #'
  #' @return A `data.table` with `Source`, `Target`, one column of weights per
  #'   element of `edges` and, according to the arguments, the `rank_<name>`
  #'   columns and `rank_gap`. A pair absent from a table (for instance because
  #'   tables were built with different thresholds) gets `NA`.
  #'
  #' @family tools to compare coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                            methods = c("angle", "strength"), weight_threshold = 2)
  #' merged <- merge_weights(edges)
  #' head(merged)
  #'
  #' # The pairs that the angle ranks high and the strength ranks low
  #' head(merged[order(-rank_gap)])
  #'
  #' @export

  Source <- Target <- NULL
  check_bool(rank, "rank")
  ties <- rlang::arg_match(ties)
  edges <- check_edge_list(edges)
  names_edges <- names(edges)
  if (!is.null(rank_gap)) {
    if (!rank) cli::cli_abort("{.arg rank_gap} needs {.code rank = TRUE}.")
    if (!is.character(rank_gap) || length(rank_gap) != 2 || !all(rank_gap %in% names_edges)) {
      cli::cli_abort("{.arg rank_gap} must be two names among {.val {names_edges}}.")
    }
  } else if (rank && length(edges) == 2) {
    rank_gap <- names_edges
  }

  tables <- Map(function(x, name) {
    x <- data.table::copy(x)
    data.table::setnames(x, "weight", name)
    x
  }, edges, names_edges)
  merged <- Reduce(function(a, b) merge(a, b, by = c("Source", "Target"), all = TRUE), tables)
  data.table::setorder(merged, Source, Target)

  if (rank) {
    common <- stats::complete.cases(merged[, names_edges, with = FALSE])
    for (name in names_edges) {
      ranks <- rep(NA_real_, nrow(merged))
      ranks[common] <- data.table::frank(-merged[[name]][common], ties.method = ties)
      data.table::set(merged, j = paste0("rank_", name), value = ranks)
    }
    if (!is.null(rank_gap)) {
      data.table::set(merged, j = "rank_gap",
                      value = merged[[paste0("rank_", rank_gap[2])]] - merged[[paste0("rank_", rank_gap[1])]])
    }
  }
  merged[]
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
  wide <- merge_weights(edges, rank = FALSE)
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
  wide <- merge_weights(edges, rank = FALSE)
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
    wide <- merge_weights(edges[unique(c(x, y))], rank = FALSE)
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
