test_that("the co-citation angle matches the hand-computed values", {
  edges <- biblio_cocitation(toy_citations(), "doc", "ref", normalized_weight_only = FALSE)

  # r1 and r2 are cited by 2 documents each, twice together (d1 and d2)
  expect_named(edges, c("from", "to", "weight", "nb_shared_citations", "Source", "Target"))
  expect_equal(nrow(edges), 5)
  expect_equal(weight_of(edges, "r1", "r2"), 2 / sqrt(2 * 2))
  expect_equal(weight_of(edges, "r1", "r3"), 1 / sqrt(2 * 2))
  expect_equal(weight_of(edges, "r2", "r3"), 1 / sqrt(2 * 2))
  expect_equal(weight_of(edges, "r3", "r4"), 1 / sqrt(2 * 2))
  # r5 is cited once, by d4, together with r4 (cited twice)
  expect_equal(weight_of(edges, "r4", "r5"), 1 / sqrt(2 * 1))
})

test_that("the number of citations counts documents citing a single reference", {
  toy <- rbind(toy_citations(), data.frame(doc = "d5", ref = "r1"))
  edges <- biblio_cocitation(toy, "doc", "ref")

  # r1 is now cited 3 times (d5 co-cites nothing but counts in the cosine)
  expect_equal(weight_of(edges, "r1", "r2"), 2 / sqrt(3 * 2))
})

test_that("all the column combinations can be returned", {
  # the numeric output with the number of co-citations used to fail
  edges <- biblio_cocitation(toy_citations(), "doc", "ref", normalized_weight_only = FALSE,
                             output_in_character = FALSE)
  expect_named(edges, c("Source", "Target", "weight", "nb_shared_citations"))
  expect_named(biblio_cocitation(toy_citations(), "doc", "ref"),
               c("from", "to", "weight", "Source", "Target"))
})

test_that("weight_threshold filters on the number of co-citations", {
  edges <- biblio_cocitation(toy_citations(), "doc", "ref", weight_threshold = 2)

  expect_equal(nrow(edges), 1)
  expect_equal(c(edges$Source, edges$Target), c("r1", "r2"))
})

test_that("it is coupling_angle() with the two columns swapped", {
  toy <- toy_citations()
  cocitation <- biblio_cocitation(toy, "doc", "ref", normalized_weight_only = FALSE)
  coupling <- coupling_angle(toy, "ref", "doc", normalized_weight_only = FALSE)

  expect_equal(sort_edges(cocitation)$weight, sort_edges(coupling)$weight)
  expect_equal(sort_edges(cocitation)$nb_shared_citations, sort_edges(coupling)$nb_shared_references)
})

test_that("the input is not modified, the order of rows does not matter", {
  toy <- toy_citations()
  toy_before <- data.table::copy(toy)
  reference <- sort_edges(biblio_cocitation(toy, "doc", "ref"))
  expect_identical(toy, toy_before)

  withr::local_seed(2)
  expect_equal(sort_edges(biblio_cocitation(toy[sample(nrow(toy)), ], "doc", "ref")), reference)
})

test_that("an empty result is a zero-row table, not an error", {
  # every document cites a single reference: nothing is co-cited
  single <- data.frame(doc = c("a", "b"), ref = c("x", "y"))
  expect_warning(edges <- biblio_cocitation(single, "doc", "ref"), class = "biblionetwork_no_edges")

  expect_equal(nrow(edges), 0)
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
})

test_that("the idf weights are the coupling weights with the columns swapped", {
  # Nodes are the references r1-r5 (M = 5), the shared items the documents:
  # d1 cites 3 references, d2, d3 and d4 two each.
  strength <- biblio_cocitation(toy_citations(), "doc", "ref", method = "strength")

  # r1 and r2 are co-cited by d1 and d2, and each is cited by 2 documents
  expect_equal(weight_of(strength, "r1", "r2"), (log(5 / 3) + log(5 / 2)) / (2 * 2))
  # r4 (cited twice) and r5 (once) are co-cited by d4 only
  expect_equal(weight_of(strength, "r4", "r5"), log(5 / 2) / (2 * 1))

  expect_equal(weight_of(biblio_cocitation(toy_citations(), "doc", "ref", method = "jaccard"), "r1", "r2"), 1)
  expect_equal(weight_of(biblio_cocitation(toy_citations(), "doc", "ref", method = "vladutz"), "r4", "r5"),
               4 / (2 + 1) * (1 / 2))

  swapped <- coupling_strength(toy_citations(), "ref", "doc", output_in_character = FALSE)
  expect_equal(sort_edges(biblio_cocitation(toy_citations(), "doc", "ref", method = "strength",
                                            output_in_character = FALSE))$weight,
               sort_edges(swapped)$weight)
  expect_error(biblio_cocitation(toy_citations(), "doc", "ref", method = "cosine"), "method")
})

test_that("a long bibliography counts less than a short one for the idf co-citation", {
  # d1 cites x, y only; d2 cites x, y and 6 other references; d3 and d4 cite
  # other things. The pair (x, y) is co-cited twice, the pair (a, b) twice too,
  # but by two documents with long bibliographies.
  links <- data.frame(
    doc = c("d1", "d1", "d2", "d2", rep("d3", 8), rep("d4", 8)),
    ref = c("x", "y", "x", "y", letters[1:8], letters[1:8])
  )
  strength <- biblio_cocitation(links, "doc", "ref", method = "strength", output_in_character = FALSE)

  expect_gt(weight_of(strength, "x", "y") * 2 * 2, weight_of(strength, "a", "b") * 4 * 4)
})
