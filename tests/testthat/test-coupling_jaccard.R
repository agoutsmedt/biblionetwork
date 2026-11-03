test_that("the Jaccard coupling matches the hand-computed values", {
  edges <- coupling_jaccard(toy_citations(), "doc", "ref")

  # d1 = {r1, r2, r3}, d2 = {r1, r2}: 2 shared out of a union of 3
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
  expect_equal(weight_of(edges, "d1", "d2"), 2 / 3)
  # d1 and d3 = {r3, r4}: 1 shared out of 4
  expect_equal(weight_of(edges, "d1", "d3"), 1 / 4)
  expect_equal(weight_of(edges, "d3", "d4"), 1 / 3)
})

test_that("the Jaccard index never exceeds the cosine", {
  jaccard <- sort_edges(coupling_jaccard(shen_citations(), "doc", "ref"))
  angle <- sort_edges(coupling_angle(shen_citations(), "doc", "ref"))

  expect_all_true(jaccard$weight <= angle$weight + 1e-12)
  expect_all_true(jaccard$weight > 0 & jaccard$weight <= 1)
})

test_that("it agrees with a slow implementation and respects the standard conventions", {
  links <- data.frame(doc = Ref_stagflation$Citing_ItemID_Ref, ref = Ref_stagflation$ItemID_Ref)
  fast <- sort_edges(coupling_jaccard(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                                      output_in_character = FALSE))
  slow <- data.table::as.data.table(slow_coupling(links, "jaccard"))[order(Source, Target)]

  expect_equal(fast$weight, slow$weight)
  expect_equal(nrow(coupling_jaccard(toy_citations(), "doc", "ref", weight_threshold = 2)), 1)
  expect_type(coupling_jaccard(toy_citations(), "doc", "ref", output_in_character = FALSE)$from, "character")
})
