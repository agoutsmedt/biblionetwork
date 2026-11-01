test_that("the coupling strength matches the hand-computed values", {
  edges <- coupling_strength(toy_citations(), "doc", "ref")

  # N = 4 documents, all the shared references are cited by 2 of them
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
  expect_equal(nrow(edges), 3)
  expect_equal(weight_of(edges, "d1", "d2"), 2 * log(4 / 2) / (3 * 2))
  expect_equal(weight_of(edges, "d1", "d3"), log(4 / 2) / (3 * 2))
  expect_equal(weight_of(edges, "d3", "d4"), log(4 / 2) / (2 * 2))
})

test_that("rare shared references weigh more than popular ones", {
  # N = 5. x is cited by 5 documents, y by 2: the pair (a, b) shares both.
  # Pair (c, d) shares only x, the very popular reference.
  links <- data.frame(
    doc = c("a", "a", "b", "b", "c", "d", "e"),
    ref = c("x", "y", "x", "y", "x", "x", "x")
  )
  edges <- coupling_strength(links, "doc", "ref")

  expect_equal(weight_of(edges, "a", "b"), (log(5 / 5) + log(5 / 2)) / (2 * 2))
  expect_equal(weight_of(edges, "c", "d"), log(5 / 5) / (1 * 1))
  expect_equal(weight_of(edges, "c", "d"), 0)
})

test_that("N counts all the citing documents, even those without a shared reference", {
  # d5 cites a reference nobody else cites: it must still count in N
  toy <- rbind(toy_citations(), data.frame(doc = "d5", ref = "r9"))
  edges <- coupling_strength(toy, "doc", "ref")

  expect_equal(weight_of(edges, "d1", "d2"), 2 * log(5 / 2) / (3 * 2))
})

test_that("weight_threshold and output_in_character work", {
  edges <- coupling_strength(toy_citations(), "doc", "ref", weight_threshold = 2)
  expect_equal(nrow(edges), 1)

  toy <- toy_citations()
  toy$doc <- as.integer(sub("d", "", toy$doc))
  toy$ref <- 100L + as.integer(sub("r", "", toy$ref))
  numeric_edges <- coupling_strength(toy, "doc", "ref", output_in_character = FALSE)
  expect_type(numeric_edges$from, "integer")
  expect_type(coupling_strength(toy, "doc", "ref")$from, "character")
})

test_that("the input is not modified and the order of rows does not matter", {
  toy <- toy_citations()
  toy_before <- data.table::copy(toy)
  reference <- sort_edges(coupling_strength(toy, "doc", "ref"))
  expect_identical(toy, toy_before)

  withr::local_seed(3)
  noisy <- rbind(toy, toy[2, ], data.frame(doc = "d2", ref = "d2"))
  expect_equal(sort_edges(coupling_strength(noisy[sample(nrow(noisy)), ], "doc", "ref")), reference)
})

test_that("an empty result is a zero-row table, not an error", {
  expect_warning(
    edges <- coupling_strength(data.frame(doc = c("a", "b"), ref = c("x", "y")), "doc", "ref"),
    class = "biblionetwork_no_edges"
  )

  expect_equal(nrow(edges), 0)
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
})

test_that("a document identifier that is also a reference identifier is not a problem", {
  # Documents cite each other: 'b' is both a citing document and a reference.
  links <- data.frame(doc = c("a", "a", "b", "b", "c"), ref = c("b", "x", "x", "y", "x"))
  edges <- coupling_strength(links, "doc", "ref")

  # N = 3 citing documents (a, b, c); x is cited 3 times: log(3 / 3) = 0
  expect_equal(nrow(edges), 3)
  expect_all_equal(edges$weight, 0)
})

test_that("it agrees with a slow implementation on the stagflation data", {
  links <- data.frame(doc = Ref_stagflation$Citing_ItemID_Ref, ref = Ref_stagflation$ItemID_Ref)
  fast <- sort_edges(coupling_strength(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                                       output_in_character = FALSE))
  slow <- data.table::as.data.table(slow_coupling(links, "strength"))[order(Source, Target)]

  expect_equal(nrow(fast), nrow(slow))
  expect_equal(fast$weight, slow$weight)
})
