test_that("the coupling angle matches the hand-computed values", {
  edges <- coupling_angle(toy_citations(), "doc", "ref", normalized_weight_only = FALSE)

  expect_named(edges, c("from", "to", "weight", "nb_shared_references", "Source", "Target"))
  expect_equal(nrow(edges), 3)
  # d1-d2 share 2 of their 3 and 2 references; d1-d3 and d3-d4 share one
  expect_equal(weight_of(edges, "d1", "d2"), 2 / sqrt(3 * 2))
  expect_equal(weight_of(edges, "d1", "d3"), 1 / sqrt(3 * 2))
  expect_equal(weight_of(edges, "d3", "d4"), 1 / sqrt(2 * 2))
  expect_setequal(edges$nb_shared_references, c(2, 1, 1))
})

test_that("each pair appears once, oriented, with no self-loop", {
  edges <- coupling_angle(toy_citations(), "doc", "ref")

  expect_all_true(edges$Source < edges$Target)
  expect_false(anyDuplicated(edges[, c("Source", "Target")]) > 0)
})

test_that("normalized_weight_only and output_in_character select the columns", {
  expect_named(coupling_angle(toy_citations(), "doc", "ref"),
               c("from", "to", "weight", "Source", "Target"))
  expect_named(coupling_angle(toy_citations(), "doc", "ref", output_in_character = FALSE),
               c("Source", "Target", "weight"))
  expect_named(
    coupling_angle(toy_citations(), "doc", "ref", normalized_weight_only = FALSE,
                    output_in_character = FALSE),
    c("Source", "Target", "weight", "nb_shared_references")
  )
})

test_that("weight_threshold filters on the number of shared references", {
  edges <- coupling_angle(toy_citations(), "doc", "ref", weight_threshold = 2)

  expect_equal(nrow(edges), 1)
  expect_equal(edges$Source, "d1")
  expect_equal(edges$Target, "d2")
})

test_that("numeric identifiers are kept in Source and Target, and 'from'/'to' are character", {
  toy <- toy_citations()
  toy$doc <- as.integer(sub("d", "", toy$doc))
  toy$ref <- 100L + as.integer(sub("r", "", toy$ref))  # distinct from the document ids
  edges <- coupling_angle(toy, "doc", "ref")

  expect_type(edges$Source, "integer")
  expect_type(edges$from, "character")
  expect_equal(weight_of(edges, 1L, 2L), 2 / sqrt(3 * 2))
})

test_that("duplicated rows, self-citations and the order of rows do not matter", {
  toy <- toy_citations()
  reference <- sort_edges(coupling_angle(toy, "doc", "ref"))

  withr::local_seed(1)
  noisy <- rbind(toy, toy[c(1, 5), ], data.frame(doc = "d1", ref = "d1"))
  noisy <- noisy[sample(nrow(noisy)), ]
  expect_equal(sort_edges(coupling_angle(noisy, "doc", "ref")), reference)
})

test_that("the input table is not modified, whether data.frame or data.table", {
  toy <- toy_citations()
  toy_before <- data.table::copy(toy)
  coupling_angle(toy, "doc", "ref")
  expect_identical(toy, toy_before)

  toy_dt <- data.table::as.data.table(toy_citations())
  toy_dt_before <- data.table::copy(toy_dt)
  coupling_angle(toy_dt, "doc", "ref")
  expect_identical(toy_dt, toy_dt_before)
  expect_named(toy_dt, c("doc", "ref"))
})

test_that("an empty result is a zero-row table, not an error", {
  no_overlap <- data.frame(doc = c("a", "b"), ref = c("x", "y"))

  expect_warning(edges <- coupling_angle(no_overlap, "doc", "ref"), class = "biblionetwork_no_edges")
  expect_equal(nrow(edges), 0)
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
  expect_warning(numeric_edges <- coupling_angle(no_overlap, "doc", "ref", output_in_character = FALSE),
                 class = "biblionetwork_no_edges")
  expect_equal(nrow(numeric_edges), 0)
})

test_that("the warning for an empty result says why", {
  # nothing is shared at all
  expect_warning(coupling_angle(data.frame(doc = c("a", "b"), ref = c("x", "y")), "doc", "ref"),
                 "No two documents share a reference")
  # something is shared but not enough: the warning gives the largest number
  expect_warning(coupling_angle(toy_citations(), "doc", "ref", weight_threshold = 10),
                 "at least 10 shared references")
  expect_warning(coupling_angle(toy_citations(), "doc", "ref", weight_threshold = 10),
                 "is 2")
})

test_that("a single document gives no edge", {
  one <- data.frame(doc = "a", ref = c("x", "y"))
  expect_warning(edges <- coupling_angle(one, "doc", "ref"), class = "biblionetwork_no_edges")
  expect_equal(nrow(edges), 0)
})

test_that("two documents with the same bibliography have a weight of 1", {
  same <- data.frame(doc = rep(c("a", "b"), each = 3), ref = rep(c("x", "y", "z"), 2))
  expect_equal(coupling_angle(same, "doc", "ref")$weight, 1)
})

test_that("missing identifiers are dropped with a warning", {
  toy <- rbind(toy_citations(), data.frame(doc = "d1", ref = NA))

  expect_warning(edges <- coupling_angle(toy, "doc", "ref"), "missing identifier")
  expect_equal(sort_edges(edges), sort_edges(coupling_angle(toy_citations(), "doc", "ref")))
})

test_that("arguments are checked", {
  expect_error(coupling_angle(1:3, "doc", "ref"), "data frame")
  expect_error(coupling_angle(toy_citations(), "doc", "nope"), "nope")
  expect_error(coupling_angle(toy_citations(), "doc", "doc"), "different")
  expect_error(coupling_angle(toy_citations(), c("doc", "ref"), "ref"), "one column")
  expect_error(coupling_angle(toy_citations(), "doc", "ref", weight_threshold = 0), "weight_threshold")
  expect_error(coupling_angle(toy_citations(), "doc", "ref", output_in_character = NA), "TRUE")
})

test_that("it agrees with a slow implementation on the stagflation data", {
  links <- data.frame(doc = Ref_stagflation$Citing_ItemID_Ref, ref = Ref_stagflation$ItemID_Ref)
  fast <- sort_edges(coupling_angle(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                                     normalized_weight_only = FALSE, output_in_character = FALSE))
  slow <- slow_coupling(links, "angle")
  slow <- data.table::as.data.table(slow)[order(Source, Target)]

  expect_equal(nrow(fast), nrow(slow))
  expect_equal(fast$weight, slow$weight)
  expect_equal(fast$nb_shared_references, slow$nb_shared)
})
