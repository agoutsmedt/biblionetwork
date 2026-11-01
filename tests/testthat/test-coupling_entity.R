test_that("the entity coupling strength matches the hand-computed values", {
  edges <- coupling_entity(toy_entities(), "art", "ref", "entity", method = "coupling_strength")

  # N = 6 documents; r1 is cited by 5 documents, r2 by 3, r3 by 1 (ignored,
  # one entity only). E1 cites r1 twice and r2 once (L = 3), E2 r1 three times
  # and r2 once (L = 4), E3 r2 and r3 once each (L = 2).
  expect_named(edges, c("from", "to", "weight", "Source", "Target", "Weighting_method"))
  expect_equal(nrow(edges), 3)
  expect_equal(weight_of(edges, "E1", "E2"), (2 * log(6 / 5) + 1 * log(6 / 3)) / (3 * 4))
  expect_equal(weight_of(edges, "E1", "E3"), log(6 / 3) / (3 * 2))
  expect_equal(weight_of(edges, "E2", "E3"), log(6 / 3) / (4 * 2))
  expect_all_equal(edges$Weighting_method, "coupling_strength")
})

test_that("the entity coupling angle uses the minimum of the two counts for each reference", {
  edges <- coupling_entity(toy_entities(), "art", "ref", "entity", method = "coupling_angle")

  # pmin(2, 3) = 2 for r1 and pmin(1, 1) = 1 for r2 (a global min() would give 1 twice)
  expect_equal(weight_of(edges, "E1", "E2"), (2 + 1) / sqrt(3 * 4))
  expect_equal(weight_of(edges, "E1", "E3"), 1 / sqrt(3 * 2))
  expect_equal(weight_of(edges, "E2", "E3"), 1 / sqrt(4 * 2))
  expect_all_equal(edges$Weighting_method, "coupling_angle")
})

test_that("weight_threshold counts shared references, not citations", {
  edges <- coupling_entity(toy_entities(), "art", "ref", "entity", weight_threshold = 2)

  expect_equal(nrow(edges), 1)
  expect_equal(c(edges$Source, edges$Target), c("E1", "E2"))
})

test_that("from and to are character only if requested", {
  entities <- toy_entities()
  entities$entity <- c(1L, 1L, 1L, 2L, 2L, 2L, 2L, 3L, 3L)

  expect_type(coupling_entity(entities, "art", "ref", "entity")$from, "integer")
  expect_type(coupling_entity(entities, "art", "ref", "entity", output_in_character = TRUE)$from, "character")
})

test_that("a document with several entities is counted once in the idf", {
  # Same documents, but a1 is signed by both E1 and E2: N and f_j do not change
  entities <- rbind(toy_entities(),
                    data.frame(art = c("a1", "a1"), entity = "E2", ref = c("r1", "r2")))
  edges <- coupling_entity(entities, "art", "ref", "entity", method = "coupling_strength")

  # E2 now cites r1 four times and r2 twice (L = 6); still N = 6, f(r1) = 5
  expect_equal(weight_of(edges, "E1", "E2"), (2 * log(6 / 5) + 1 * log(6 / 3)) / (3 * 6))
})

test_that("the input is not modified, the order of rows does not matter, and errors are clear", {
  entities <- toy_entities()
  entities_before <- data.table::copy(entities)
  reference <- sort_edges(coupling_entity(entities, "art", "ref", "entity"))
  expect_identical(entities, entities_before)

  withr::local_seed(5)
  expect_equal(sort_edges(coupling_entity(entities[sample(nrow(entities)), ], "art", "ref", "entity")), reference)
  expect_error(coupling_entity(entities, "art", "ref", "nope"), "nope")
  expect_error(coupling_entity(entities, "art", "ref", "entity", method = "unknown"), "method")
})

test_that("an empty result is a zero-row table, not an error", {
  alone <- data.frame(art = c("a", "b"), entity = c("E1", "E2"), ref = c("x", "y"))
  expect_warning(edges <- coupling_entity(alone, "art", "ref", "entity"), class = "biblionetwork_no_edges")

  expect_equal(nrow(edges), 0)
  expect_named(edges, c("from", "to", "weight", "Source", "Target", "Weighting_method"))
})

test_that("the entity similarity is the idf-weighted cosine with the minimum rule", {
  edges <- coupling_entity(toy_entities(), "art", "ref", "entity", method = "coupling_similarity")

  # N = 6; idf(r1) = log(6/5), idf(r2) = log(6/3), idf(r3) = log(6/1).
  # S(E1) = 2 idf(r1) + idf(r2); S(E2) = 3 idf(r1) + idf(r2); S(E3) = idf(r2) + idf(r3)
  idf1 <- log(6 / 5)
  idf2 <- log(6 / 3)
  idf3 <- log(6 / 1)
  s1 <- 2 * idf1 + idf2
  s2 <- 3 * idf1 + idf2
  s3 <- idf2 + idf3
  expect_equal(weight_of(edges, "E1", "E2"), (2 * idf1 + idf2) / sqrt(s1 * s2))
  expect_equal(weight_of(edges, "E1", "E3"), idf2 / sqrt(s1 * s3))
  expect_equal(weight_of(edges, "E2", "E3"), idf2 / sqrt(s2 * s3))
  expect_all_true(edges$weight <= 1)
  expect_all_equal(edges$Weighting_method, "coupling_similarity")
})

test_that("two entities with identical citations have an entity similarity of 1", {
  entities <- data.frame(
    art = c("a1", "a2", "a3", "a4", "a5", "a6"),
    entity = c("E1", "E1", "E2", "E2", "E3", "E3"),
    ref = c("x", "y", "x", "y", "z", "w")
  )
  edges <- coupling_entity(entities, "art", "ref", "entity", method = "coupling_similarity")

  expect_equal(weight_of(edges, "E1", "E2"), 1)
})
