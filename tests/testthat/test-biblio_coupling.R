test_that("the default method is the coupling angle", {
  expect_equal(biblio_coupling(toy_citations(), "doc", "ref"),
               coupling_angle(toy_citations(), "doc", "ref"))
})

test_that("each method gives the same weights as its own function", {
  toy <- toy_citations()
  expect_equal(biblio_coupling(toy, "doc", "ref", method = "strength"),
               coupling_strength(toy, "doc", "ref"))
  expect_equal(biblio_coupling(toy, "doc", "ref", method = "similarity"),
               coupling_similarity(toy, "doc", "ref"))
  expect_equal(biblio_coupling(toy, "doc", "ref", method = "jaccard"),
               coupling_jaccard(toy, "doc", "ref"))
  expect_equal(biblio_coupling(toy, "doc", "ref", method = "vladutz"),
               coupling_vladutz(toy, "doc", "ref"))
})

test_that("an unknown method is an error, and the input is untouched", {
  toy <- toy_citations()
  before <- data.table::copy(data.table::as.data.table(toy))
  expect_error(biblio_coupling(toy, "doc", "ref", method = "nope"), "method")
  biblio_coupling(toy, "doc", "ref", method = "jaccard", normalized_weight_only = FALSE)
  expect_equal(data.table::as.data.table(toy), before)
})

test_that("identifiers stored as factors (with different levels) work like characters", {
  toy <- toy_citations()
  as_factors <- toy
  as_factors$doc <- factor(as_factors$doc)
  as_factors$ref <- factor(as_factors$ref)

  expect_equal(sort_edges(biblio_coupling(as_factors, "doc", "ref")),
               sort_edges(biblio_coupling(toy, "doc", "ref")))
  expect_equal(nrow(biblio_cocitation(as_factors, "doc", "ref")),
               nrow(biblio_cocitation(toy, "doc", "ref")))
})
