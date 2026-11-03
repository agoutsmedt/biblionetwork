# Tests on real data: samples of the authors' Scopus and Web of Science
# DuckDB databases. They check the invariants of every measure on corpora
# much larger and messier than the toy examples (identifiers of different
# types, very uneven bibliographies and popular references). Skipped on CRAN,
# in CI and wherever the databases are absent: these data cannot be
# distributed with the package. Samples are small and deterministic.

# A sample of the Scopus database: the references of the Journal of Monetary
# Economics in 1995-1999 (about 420 documents and 6,700 references, with
# character identifiers).
scopus_sample <- function(con) {
  citations <- DBI::dbGetQuery(con, "
    SELECT citing_id AS doc, cited_id AS ref FROM reference
    WHERE citing_id IN (
      SELECT scopus_id FROM article
      WHERE prism_publication_name = 'Journal of Monetary Economics'
        AND substr(prism_cover_date, 1, 4) BETWEEN '1995' AND '1999')")
  authorships <- DBI::dbGetQuery(con, "
    SELECT scopus_id AS paper, auid AS author FROM author
    WHERE scopus_id IN (
      SELECT scopus_id FROM article
      WHERE prism_publication_name = 'Journal of Monetary Economics'
        AND substr(prism_cover_date, 1, 4) BETWEEN '1995' AND '1999')")
  list(citations = citations, authorships = authorships)
}

# A sample of the Web of Science database, with integer identifiers: the first
# 3,000 citing documents (about 460 documents with references). ItemID_Ref = 0
# is a reference that is not matched to a document.
wos_sample <- function(con) {
  citations <- DBI::dbGetQuery(con, '
    SELECT ID_Art AS doc, ItemID_Ref AS ref FROM "references"
    WHERE ID_Art <= 3000 AND ItemID_Ref > 0')
  authorships <- DBI::dbGetQuery(con, "
    SELECT ID_Art AS paper, Nom AS author FROM authors
    WHERE ID_Art BETWEEN 24200000 AND 24230000")
  list(citations = citations, authorships = authorships)
}

# The invariants that every coupling edge table must respect.
expect_valid_coupling <- function(edges, links) {
  expect_gt(nrow(edges), 0)
  expect_all_true(edges$Source < edges$Target)
  expect_false(anyDuplicated(edges[, c("Source", "Target")]) > 0)
  expect_all_true(is.finite(edges$weight))
  expect_all_true(edges$weight >= 0)
  expect_all_true(edges$Source %in% links$doc)
  expect_all_true(edges$Target %in% links$doc)
}

test_that("the coupling functions respect their invariants on a Scopus sample", {
  con <- local_database("~/data/scopus/scopus.duckdb")
  links <- scopus_sample(con)$citations
  skip_if(nrow(links) == 0, "no references in the sample")
  links_before <- data.table::copy(links)

  angle <- coupling_angle(links, "doc", "ref", normalized_weight_only = FALSE, output_in_character = FALSE)
  strength <- coupling_strength(links, "doc", "ref", output_in_character = FALSE)
  similarity <- coupling_similarity(links, "doc", "ref", output_in_character = FALSE)

  expect_identical(links, links_before)
  expect_valid_coupling(angle, links)
  expect_valid_coupling(strength, links)
  expect_valid_coupling(similarity, links)
  # the cosines are bounded by 1, and the three functions find the same pairs
  expect_all_true(angle$weight <= 1 + 1e-12)
  expect_all_true(similarity$weight <= 1 + 1e-12)
  expect_equal(nrow(strength), nrow(angle))
  expect_equal(nrow(similarity), nrow(angle))
  # raising the threshold only removes edges
  strict <- coupling_angle(links, "doc", "ref", weight_threshold = 3, output_in_character = FALSE)
  expect_lt(nrow(strict), nrow(angle))
  expect_all_true(strict$weight %in% angle$weight)
  expect_equal(nrow(strict), sum(angle$nb_shared_references >= 3))
})

test_that("the fast functions agree with the slow implementation on a Scopus sample", {
  con <- local_database("~/data/scopus/scopus.duckdb")
  links <- scopus_sample(con)$citations
  skip_if(nrow(links) == 0, "no references in the sample")
  # 60 citing documents keep the double loop of the slow version quick
  docs <- sort(unique(links$doc))[1:60]
  links <- links[links$doc %in% docs, ]

  all_measures <- compute_couplings(links, "doc", "ref")
  for (measure in names(all_measures)) {
    fast <- sort_edges(all_measures[[measure]])
    slow <- data.table::as.data.table(slow_coupling(links, measure))[order(Source, Target)]
    expect_equal(nrow(fast), nrow(slow), info = measure)
    expect_equal(fast$weight, slow$weight, info = measure)
  }
  # the individual functions give the same weights as compute_couplings()
  expect_equal(sort_edges(coupling_jaccard(links, "doc", "ref", output_in_character = FALSE))$weight,
               sort_edges(all_measures$jaccard)$weight)
})

test_that("the comparison tools run on a Web of Science sample", {
  con <- local_database("~/data/wos/wos.duckdb")
  links <- wos_sample(con)$citations
  skip_if(nrow(links) == 0, "no references in the sample")

  edges <- compute_couplings(links, "doc", "ref", weight_threshold = 2)
  summary <- summarise_weights(edges)
  correlations <- correlate_weights(edges)

  expect_equal(summary$method, names(edges))
  expect_equal(unique(summary$n_edges), nrow(edges$angle))
  expect_all_true(as.vector(correlations) >= -1 & as.vector(correlations) <= 1)
  expect_equal(unname(diag(correlations)), rep(1, 5))
  # the cosine and the Jaccard index rank the pairs almost identically
  expect_gt(correlations["angle", "jaccard"], 0.9)
  expect_all_true(as.vector(overlap_top_weights(edges, top = 0.1)) <= 1)
})

test_that("co-citation and entity coupling run on a Scopus sample", {
  con <- local_database("~/data/scopus/scopus.duckdb")
  links <- scopus_sample(con)$citations
  skip_if(nrow(links) == 0, "no references in the sample")

  cocitation <- biblio_cocitation(links, "doc", "ref", normalized_weight_only = FALSE,
                                  weight_threshold = 2, output_in_character = FALSE)
  expect_gt(nrow(cocitation), 0)
  expect_all_true(cocitation$Source < cocitation$Target)
  expect_all_true(cocitation$weight <= 1 + 1e-12)
  expect_all_true(cocitation$nb_shared_citations >= 2)

  # Entities: the first author of each document plays the role of an entity
  authorships <- scopus_sample(con)$authorships
  first_author <- authorships[!duplicated(authorships$paper), ]
  entity_links <- merge(links, first_author, by.x = "doc", by.y = "paper")
  edges <- entity_network(entity_links, "doc", "ref", "author", weight_threshold = 2,
                           method = "angle")
  expect_gt(nrow(edges), 0)
  expect_all_true(edges$Source < edges$Target)
  expect_all_true(is.finite(edges$weight) & edges$weight > 0)
})

test_that("the coupling functions respect their invariants on a Web of Science sample", {
  con <- local_database("~/data/wos/wos.duckdb")
  links <- wos_sample(con)$citations
  skip_if(nrow(links) == 0, "no references in the sample")

  angle <- coupling_angle(links, "doc", "ref", normalized_weight_only = FALSE, output_in_character = FALSE)
  strength <- coupling_strength(links, "doc", "ref", output_in_character = FALSE)
  similarity <- coupling_similarity(links, "doc", "ref", output_in_character = FALSE)

  expect_type(angle$Source, "integer")
  expect_valid_coupling(angle, links)
  expect_valid_coupling(strength, links)
  expect_valid_coupling(similarity, links)
  expect_all_true(angle$weight <= 1 + 1e-12)

  # character identifiers give the same edges
  as_character <- coupling_angle(links, "doc", "ref", output_in_character = TRUE)
  expect_equal(nrow(as_character), nrow(angle))
  expect_type(as_character$from, "character")
})

test_that("co-authorship respects its invariants on Web of Science and Scopus samples", {
  samples <- list(
    wos = wos_sample(local_database("~/data/wos/wos.duckdb"))$authorships,
    scopus = scopus_sample(local_database("~/data/scopus/scopus.duckdb"))$authorships
  )
  for (name in names(samples)) {
    authorships <- unique(stats::na.omit(samples[[name]]))
    skip_if(nrow(authorships) == 0, "no authors in the sample")
    n_authors <- table(authorships$paper)
    n_coauthored <- sum(n_authors > 1)
    skip_if(n_coauthored == 0, "no co-authored paper in the sample")

    full <- coauth_network(authorships, "author", "paper", method = "full_counting")
    fractional <- coauth_network(authorships, "author", "paper", method = "fractional_counting")
    refined <- coauth_network(authorships, "author", "paper", method = "fractional_counting_refined")
    cosine <- coauth_network(authorships, "author", "paper", method = "full_counting", cosine_normalized = TRUE)

    # The ties of a paper with n authors: n (n - 1) / 2 pairs of weight 1
    pairs_per_paper <- n_authors[n_authors > 1] * (n_authors[n_authors > 1] - 1) / 2
    expect_equal(sum(full$weight), sum(pairs_per_paper), info = name)
    # fractional counting: each author gives a total of 1 per paper, i.e. n / 2 per paper
    expect_equal(sum(fractional$weight), sum(n_authors[n_authors > 1]) / 2, info = name)
    # refined fractional counting: each co-authored paper weighs 1
    expect_equal(sum(refined$weight), n_coauthored, info = name)
    expect_equal(nrow(full), nrow(refined), info = name)
    expect_all_true(cosine$weight <= 1 + 1e-12)
  }
})

# Every method, checked edge by edge against the definition written with sets
# (not with the sparse matrices of the package), on both databases.
set_based_weight <- function(links, a, b, method) {
  links <- unique(links[!is.na(links$doc) & !is.na(links$ref) & links$doc != links$ref, ])
  n_docs <- length(unique(links$doc))
  freq <- table(links$ref)
  ra <- links$ref[links$doc == a]
  rb <- links$ref[links$doc == b]
  shared <- intersect(ra, rb)
  idf <- function(r) log(n_docs / as.numeric(freq[as.character(r)]))
  s_a <- sum(idf(ra))
  s_b <- sum(idf(rb))
  switch(
    method,
    angle = length(shared) / sqrt(length(ra) * length(rb)),
    strength = sum(idf(shared)) / (length(ra) * length(rb)),
    similarity = sum(idf(shared)) / sqrt(s_a * s_b),
    jaccard = length(shared) / (length(ra) + length(rb) - length(shared)),
    vladutz = 4 / (length(ra) + length(rb)) * sum(1 / as.numeric(freq[as.character(shared)]))
  )
}

test_that("every coupling method matches its set-based definition on real data", {
  withr::local_seed(11)
  for (database in c("~/data/scopus/scopus.duckdb", "~/data/wos/wos.duckdb")) {
    con <- local_database(database)
    links <- if (grepl("scopus", database)) scopus_sample(con)$citations else wos_sample(con)$citations
    skip_if(nrow(links) == 0, "no references in the sample")
    for (method in c("angle", "strength", "similarity", "jaccard", "vladutz")) {
      edges <- biblio_coupling(links, "doc", "ref", method = method, weight_threshold = 2, output_in_character = FALSE)
      rows <- sample(nrow(edges), min(30, nrow(edges)))
      expected <- unname(mapply(function(a, b) set_based_weight(links, a, b, method), edges$Source[rows], edges$Target[rows]))
      expect_equal(edges$weight[rows], expected, info = paste(database, method))
    }
  }
})
