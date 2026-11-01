test_that("the similarity is the idf-weighted cosine, with hand-computed values", {
  edges <- coupling_similarity(toy_citations(), "doc", "ref")

  # N = 4. Every reference but r5 is cited by 2 documents (idf = log 2);
  # r5 is cited once (idf = log 4 = 2 log 2). The informational lengths are
  # S(d1) = 3 log 2, S(d2) = 2 log 2, S(d3) = 2 log 2, S(d4) = 3 log 2.
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
  expect_equal(nrow(edges), 3)
  expect_equal(weight_of(edges, "d1", "d2"), 2 * log(2) / sqrt(3 * log(2) * 2 * log(2)))
  expect_equal(weight_of(edges, "d1", "d3"), log(2) / sqrt(3 * log(2) * 2 * log(2)))
  expect_equal(weight_of(edges, "d3", "d4"), log(2) / sqrt(2 * log(2) * 3 * log(2)))
})

test_that("it reproduces the definition of Shen et al. (Eq. 8) on their artificial example", {
  edges <- coupling_similarity(shen_citations(), "doc", "ref")

  # Articles I and II share A, B, C, D (cited by 7, 9, 5, 5 of the 10 articles);
  # their other references are E (2 citations) and F (1 citation).
  idf <- function(freq) log10(10 / freq)
  numerator <- sum(idf(c(7, 9, 5, 5)))
  s_i <- sum(idf(c(7, 9, 5, 5, 2)))
  s_ii <- sum(idf(c(7, 9, 5, 5, 1)))
  expect_equal(weight_of(edges, "I", "II"), numerator / sqrt(s_i * s_ii))
  # a cosine is bounded by 1, whatever the base of the logarithm
  expect_all_true(edges$weight > 0 & edges$weight <= 1)
})

test_that("each reference is weighted by its own idf (regression test)", {
  # With the bug of the versions <= 0.1.1, the idf of the first reference was
  # given to every reference. Here r1 is cited by 3 of 4 documents, r2 by 2.
  links <- data.frame(
    doc = c("a", "a", "b", "b", "c", "c", "d"),
    ref = c("r1", "r2", "r1", "r2", "r1", "r3", "r4")
  )
  edges <- coupling_similarity(links, "doc", "ref")
  idf <- c(r1 = log(4 / 3), r2 = log(4 / 2), r3 = log(4 / 1), r4 = log(4 / 1))

  s_a <- idf[["r1"]] + idf[["r2"]]
  s_b <- idf[["r1"]] + idf[["r2"]]
  s_c <- idf[["r1"]] + idf[["r3"]]
  expect_equal(weight_of(edges, "a", "b"), (idf[["r1"]] + idf[["r2"]]) / sqrt(s_a * s_b))
  expect_equal(weight_of(edges, "a", "c"), idf[["r1"]] / sqrt(s_a * s_c))
  expect_equal(weight_of(edges, "b", "c"), idf[["r1"]] / sqrt(s_b * s_c))
})

test_that("two documents with the same bibliography have a similarity of 1", {
  links <- data.frame(doc = rep(c("a", "b", "c"), each = 2),
                      ref = c("x", "y", "x", "y", "z", "w"))
  edges <- coupling_similarity(links, "doc", "ref")

  expect_equal(weight_of(edges, "a", "b"), 1)
})

test_that("it is not proportional to the coupling strength (regression test)", {
  links <- data.frame(
    doc = c("a", "a", "b", "b", "c", "c", "d"),
    ref = c("r1", "r2", "r1", "r2", "r1", "r3", "r4")
  )
  similarity <- sort_edges(coupling_similarity(links, "doc", "ref"))
  strength <- sort_edges(coupling_strength(links, "doc", "ref"))

  ratio <- similarity$weight / strength$weight
  expect_gt(diff(range(ratio)), 1e-6)
})

test_that("documents whose references are cited by all documents get a weight of 0, not NaN", {
  links <- data.frame(doc = rep(c("a", "b"), each = 2), ref = rep(c("x", "y"), 2))
  edges <- coupling_similarity(links, "doc", "ref")

  expect_equal(nrow(edges), 1)
  expect_equal(edges$weight, 0)
})

test_that("weight_threshold and validation work", {
  expect_equal(nrow(coupling_similarity(toy_citations(), "doc", "ref", weight_threshold = 2)), 1)
  expect_error(coupling_similarity(toy_citations(), "doc", "nope"), "nope")
})

test_that("the input is not modified and the order of rows does not matter", {
  toy <- toy_citations()
  toy_before <- data.table::copy(toy)
  reference <- sort_edges(coupling_similarity(toy, "doc", "ref"))
  expect_identical(toy, toy_before)

  withr::local_seed(4)
  expect_equal(sort_edges(coupling_similarity(toy[sample(nrow(toy)), ], "doc", "ref")), reference)
})

test_that("it agrees with a slow implementation on the stagflation data", {
  links <- data.frame(doc = Ref_stagflation$Citing_ItemID_Ref, ref = Ref_stagflation$ItemID_Ref)
  fast <- sort_edges(coupling_similarity(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                                         output_in_character = FALSE))
  slow <- data.table::as.data.table(slow_coupling(links, "similarity"))[order(Source, Target)]

  expect_equal(nrow(fast), nrow(slow))
  expect_equal(fast$weight, slow$weight)
})
