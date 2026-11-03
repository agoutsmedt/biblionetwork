test_that("prepare_links() returns a clean copy and leaves the input alone", {
  links <- data.frame(a = c(1, 1, 2, 3), b = c(10, 10, 10, 3))
  links_before <- data.table::copy(links)

  prepared <- prepare_links(links, "a", "b")

  expect_identical(links, links_before)
  expect_named(prepared, c("id_art", "id_ref"))
  # one duplicate and one self-loop (3 -> 3) removed
  expect_equal(nrow(prepared), 2)
})

test_that("check functions give informative errors", {
  expect_error(check_threshold(0), "weight_threshold")
  expect_error(check_threshold("a"), "weight_threshold")
  expect_error(check_bool(NA, "flag"), "flag")
  expect_error(check_column_name(1, "source"), "source")
  expect_error(check_columns(data.frame(a = 1), c("a", "b"), "dt"), "b")
})

test_that("lengths of bibliographies are numeric, so that their products cannot overflow", {
  pairs <- coupling_core(toy_citations(), "doc", "ref", 1)
  expect_type(pairs$nb_ref_Source, "double")

  entity_edges <- entity_network(toy_entities(), "art", "ref", "entity", method = "angle")
  expect_all_true(is.finite(entity_edges$weight))
})
