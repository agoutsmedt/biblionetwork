test_that("the Vladutz-Cook coupling matches the hand-computed values", {
  edges <- coupling_vladutz(toy_citations(), "doc", "ref")

  # all the shared references of the toy example are cited by 2 documents
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
  expect_equal(weight_of(edges, "d1", "d2"), 4 / (3 + 2) * (1 / 2 + 1 / 2))
  expect_equal(weight_of(edges, "d1", "d3"), 4 / (3 + 2) * (1 / 2))
  expect_equal(weight_of(edges, "d3", "d4"), 4 / (2 + 2) * (1 / 2))
})

test_that("it is bounded by 1, which is reached for identical bibliographies cited twice", {
  twins <- data.frame(doc = rep(c("a", "b"), each = 3), ref = rep(c("x", "y", "z"), 2))
  expect_equal(coupling_vladutz(twins, "doc", "ref")$weight, 1)

  edges <- coupling_vladutz(shen_citations(), "doc", "ref")
  expect_all_true(edges$weight > 0 & edges$weight <= 1)
})

test_that("it agrees with a slow implementation", {
  links <- data.frame(doc = Ref_stagflation$Citing_ItemID_Ref, ref = Ref_stagflation$ItemID_Ref)
  fast <- sort_edges(coupling_vladutz(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                                      output_in_character = FALSE))
  slow <- data.table::as.data.table(slow_coupling(links, "vladutz"))[order(Source, Target)]

  expect_equal(fast$weight, slow$weight)
})
