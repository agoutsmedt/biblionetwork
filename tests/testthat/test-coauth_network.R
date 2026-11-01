test_that("the three counting methods match the hand-computed values", {
  toy <- toy_authorships()

  # p1 = {a, b, c}, p2 = {a, b}; p3 has a single author and creates no tie
  full <- coauth_network(toy, "author", "paper", method = "full_counting")
  expect_named(full, c("from", "to", "weight", "Source", "Target"))
  expect_equal(nrow(full), 3)
  expect_equal(weight_of(full, "a", "b"), 2)
  expect_equal(weight_of(full, "a", "c"), 1)
  expect_equal(weight_of(full, "b", "c"), 1)

  fractional <- coauth_network(toy, "author", "paper", method = "fractional_counting")
  expect_equal(weight_of(fractional, "a", "b"), 1 / 2 + 1 / 1)
  expect_equal(weight_of(fractional, "a", "c"), 1 / 2)

  refined <- coauth_network(toy, "author", "paper", method = "fractional_counting_refined")
  expect_equal(weight_of(refined, "a", "b"), 2 / (3 * 2) + 2 / (2 * 1))
  expect_equal(weight_of(refined, "b", "c"), 2 / (3 * 2))
  # each co-authored document weighs 1 in total
  expect_equal(sum(refined$weight), 2)
})

test_that("full counting is the default method", {
  expect_equal(sort_edges(coauth_network(toy_authorships(), "author", "paper")),
               sort_edges(coauth_network(toy_authorships(), "author", "paper", method = "full_counting")))
})

test_that("the cosine normalisation divides by the numbers of co-authored papers", {
  edges <- coauth_network(toy_authorships(), "author", "paper", method = "full_counting",
                          cosine_normalized = TRUE)

  # a and b co-authored 2 papers, c one (p3, with the single author d, is ignored)
  expect_equal(weight_of(edges, "a", "b"), 2 / sqrt(2 * 2))
  expect_equal(weight_of(edges, "a", "c"), 1 / sqrt(2 * 1))
})

test_that("an unknown method is an error", {
  expect_error(coauth_network(toy_authorships(), "author", "paper", method = "other"), "method")
})

test_that("duplicates and the order of rows do not matter, the input is not modified", {
  toy <- toy_authorships()
  toy_before <- data.table::copy(toy)
  reference <- sort_edges(coauth_network(toy, "author", "paper", method = "fractional_counting"))
  expect_identical(toy, toy_before)

  withr::local_seed(6)
  noisy <- rbind(toy, toy[1:2, ])
  expect_equal(sort_edges(coauth_network(noisy[sample(nrow(noisy)), ], "author", "paper",
                                         method = "fractional_counting")), reference)
})

test_that("numeric identifiers keep their type", {
  toy <- toy_authorships()
  toy$author <- match(toy$author, letters)
  edges <- coauth_network(toy, "author", "paper")

  expect_type(edges$Source, "integer")
  expect_equal(weight_of(edges, 1L, 2L), 2)
})

test_that("an empty result is a zero-row table, not an error", {
  expect_warning(
    edges <- coauth_network(data.frame(author = c("a", "b"), paper = c("p1", "p2")), "author", "paper"),
    "No document has more than one author"
  )

  expect_equal(nrow(edges), 0)
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
})

test_that("it runs on the stagflation data, with the expected invariants", {
  refined <- coauth_network(Authors_stagflation, "Author", "ItemID_Ref",
                            method = "fractional_counting_refined")
  articles <- unique(Authors_stagflation[, c("Author", "ItemID_Ref")])
  n_authors <- table(articles$ItemID_Ref)

  expect_equal(sum(refined$weight), sum(n_authors > 1))
})
