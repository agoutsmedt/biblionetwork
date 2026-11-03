test_that("compute_couplings() returns the same values as the individual functions", {
  toy <- shen_citations()
  edges <- compute_couplings(toy, "doc", "ref")

  expect_named(edges, c("angle", "strength", "similarity", "jaccard", "vladutz"))
  expect_equal(sort_edges(edges$angle)$weight,
               sort_edges(coupling_angle(toy, "doc", "ref", output_in_character = FALSE))$weight)
  expect_equal(sort_edges(edges$strength)$weight,
               sort_edges(coupling_strength(toy, "doc", "ref", output_in_character = FALSE))$weight)
  expect_equal(sort_edges(edges$similarity)$weight,
               sort_edges(coupling_similarity(toy, "doc", "ref", output_in_character = FALSE))$weight)
  expect_equal(sort_edges(edges$jaccard)$weight,
               sort_edges(coupling_jaccard(toy, "doc", "ref", output_in_character = FALSE))$weight)
  expect_equal(sort_edges(edges$vladutz)$weight,
               sort_edges(coupling_vladutz(toy, "doc", "ref", output_in_character = FALSE))$weight)
  # all the tables describe the same pairs in the same order
  expect_equal(edges$angle$Source, edges$vladutz$Source)
  expect_equal(edges$angle$Target, edges$vladutz$Target)
})

test_that("compute_couplings() selects methods and checks its arguments", {
  edges <- compute_couplings(toy_citations(), "doc", "ref", methods = c("strength", "angle"),
                             weight_threshold = 2)

  expect_named(edges, c("strength", "angle"))
  expect_equal(nrow(edges$angle), 1)
  expect_error(compute_couplings(toy_citations(), "doc", "ref", methods = "cosine"), "methods")
})

test_that("merge_weights() puts the weights side by side", {
  edges <- compute_couplings(toy_citations(), "doc", "ref", methods = c("angle", "jaccard"))
  wide <- merge_weights(edges)

  expect_named(wide, c("Source", "Target", "angle", "jaccard", "rank_angle", "rank_jaccard", "rank_gap"))
  expect_equal(nrow(wide), 3)
  expect_named(merge_weights(edges, rank = FALSE), c("Source", "Target", "angle", "jaccard"))
  # pairs absent from one table are kept, with NA
  partial <- list(a = edges$angle, b = edges$angle[1:2])
  expect_equal(sum(is.na(merge_weights(partial)$b)), 1)
})

test_that("merge_weights() ranks the pairs (1 = strongest) and measures the gap between two measures", {
  edges <- list(
    a = data.frame(Source = 1:4, Target = 5:8, weight = c(4, 3, 2, 1)),
    b = data.frame(Source = 1:4, Target = 5:8, weight = c(1, 3, 2, 4)),
    c = data.frame(Source = 1:4, Target = 5:8, weight = c(4, 3, 2, 1))
  )
  wide <- merge_weights(edges, rank_gap = c("a", "b"))

  expect_equal(wide$rank_a, c(1, 2, 3, 4))
  expect_equal(wide$rank_b, c(4, 2, 3, 1))
  # second minus first: positive when b ranks the pair lower than a
  expect_equal(wide$rank_gap, c(3, 0, 0, -3))
  # no automatic gap with three measures, an automatic one with two
  expect_false("rank_gap" %in% names(merge_weights(edges)))
  expect_equal(merge_weights(edges[1:2])$rank_gap, c(3, 0, 0, -3))
  expect_error(merge_weights(edges, rank_gap = c("a", "z")), "rank_gap")
  expect_error(merge_weights(edges, rank = FALSE, rank_gap = c("a", "b")), "rank")
})

test_that("ranks are computed on the pairs that all the tables share", {
  edges <- list(
    a = data.frame(Source = 1:3, Target = 4:6, weight = c(3, 2, 1)),
    b = data.frame(Source = 1:2, Target = 4:5, weight = c(1, 2))
  )
  wide <- merge_weights(edges)

  expect_equal(wide$rank_a, c(1, 2, NA))
  expect_equal(wide$rank_b, c(2, 1, NA))
})

test_that("compute_couplings() can add the descriptive measure, with an information message", {
  toy <- data.frame(
    doc = c("a", "a", "b", "b"),
    ref = c("r1", "r2", "r1", "r3"),
    title = c("inflation expectations", "oil supply shocks", "inflation expectations", "supply shocks prices")
  )
  expect_named(compute_couplings(toy, "doc", "ref"), c("angle", "strength", "similarity", "jaccard", "vladutz"))
  expect_message(
    edges <- compute_couplings(toy, "doc", "ref", methods = c("angle", "descriptive"), title = "title"),
    class = "biblionetwork_descriptive_cost"
  )
  expect_named(edges, c("angle", "descriptive"))
  expect_equal(edges$descriptive$weight, (1 + 0.5 + 1 + 0.5) / 4)
  expect_error(suppressMessages(compute_couplings(toy, "doc", "ref", methods = "descriptive")), "title")
  expect_error(suppressMessages(compute_couplings(toy, "doc", "ref", methods = "descriptive", title = "title", network = "cocitation")), "cocitation")
})

test_that("summarise_weights() describes each distribution", {
  edges <- list(one = data.frame(Source = 1:4, Target = 5:8, weight = c(0, 1, 2, 3)),
                two = data.frame(Source = 1:4, Target = 5:8, weight = c(10, 10, 10, 10)))
  summary <- summarise_weights(edges)

  expect_equal(summary$method, c("one", "two"))
  expect_equal(summary$n_edges, c(4, 4))
  expect_equal(summary$mean, c(1.5, 10))
  expect_equal(summary$share_zero, c(0.25, 0))
  expect_equal(summary$q50, c(1.5, 10))
  expect_equal(summary$max, c(3, 10))
  expect_equal(summary$ratio_q99_median[2], 1)
  expect_error(summarise_weights(edges, probs = 2), "probabilities")
})

test_that("correlate_weights() recovers monotonic relations", {
  edges <- list(
    a = data.frame(Source = 1:6, Target = 7:12, weight = c(1, 2, 3, 4, 5, 6)),
    b = data.frame(Source = 1:6, Target = 7:12, weight = exp(c(1, 2, 3, 4, 5, 6))),
    c = data.frame(Source = 1:6, Target = 7:12, weight = c(6, 5, 4, 3, 2, 1))
  )
  spearman <- correlate_weights(edges)

  expect_equal(dim(spearman), c(3, 3))
  expect_equal(spearman["a", "b"], 1)
  expect_equal(spearman["a", "c"], -1)
  expect_equal(attr(spearman, "n_pairs"), 6)
  # the relation is monotonic but not linear
  expect_lt(correlate_weights(edges, method = "pearson")["a", "b"], 1)
  expect_error(correlate_weights(edges["a"]), "at least 2")
})

test_that("overlap_top_weights() compares the strongest edges", {
  edges <- list(
    a = data.frame(Source = 1:10, Target = 11:20, weight = 1:10),
    b = data.frame(Source = 1:10, Target = 11:20, weight = 10:1)
  )
  overlap <- overlap_top_weights(edges, top = 0.2)

  expect_equal(overlap["a", "a"], 1)
  expect_equal(overlap["a", "b"], 0)
  expect_equal(unname(attr(overlap, "n_top")), c(2, 2))
  expect_equal(overlap_top_weights(list(a = edges$a, b = edges$a), top = 0.5)["a", "b"], 1)
  expect_error(overlap_top_weights(edges, top = 0), "top")
})

test_that("the edge lists are checked", {
  expect_error(summarise_weights(list(data.frame(Source = 1, Target = 2, weight = 1))), "named list")
  expect_error(summarise_weights(list(a = data.frame(x = 1))), "Source")
  expect_error(summarise_weights(data.frame(Source = 1, Target = 2, weight = 1)), "named list")
})

test_that("plot_weights() builds plots", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  edges <- compute_couplings(shen_citations(), "doc", "ref")

  expect_s3_class(plot_weights(edges), "ggplot")
  expect_s3_class(plot_weights(edges, type = "scatter", x = "angle", y = "strength"), "ggplot")
  expect_error(plot_weights(edges, type = "scatter", x = "angle", y = "nope"), "must be names")
})

test_that("compute_couplings(network = 'cocitation') gives the co-citation weights", {
  toy <- shen_citations()
  edges <- compute_couplings(toy, "doc", "ref", network = "cocitation", methods = c("angle", "strength"))

  expect_equal(sort_edges(edges$angle)$weight,
               sort_edges(biblio_cocitation(toy, "doc", "ref", output_in_character = FALSE))$weight)
  expect_equal(sort_edges(edges$strength)$weight,
               sort_edges(biblio_cocitation(toy, "doc", "ref", method = "strength",
                                            output_in_character = FALSE))$weight)
  expect_error(compute_couplings(toy, "doc", "ref", network = "other"), "network")
})
