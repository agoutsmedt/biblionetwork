toy_titles <- function() {
  data.frame(
    doc = c("a", "a", "b", "b", "c"),
    ref = c("r1", "r2", "r1", "r3", "r4"),
    title = c("inflation expectations", "oil supply shocks",
              "inflation expectations", "supply shocks prices", "central banking")
  )
}

# A slow implementation of Eq. 3 and 5 of Liu (2017), with loops
slow_descriptive <- function(links, stopwords = NULL) {
  titles <- unique(links[, c("ref", "title")])
  terms <- stats::setNames(lapply(titles$title, function(x) setdiff(strsplit(tolower(x), "[^a-z0-9]+")[[1]], stopwords)), titles$ref)
  sim <- function(r1, r2) {
    if (r1 == r2) return(1)
    u <- length(union(terms[[r1]], terms[[r2]]))
    if (u == 0) 0 else length(intersect(terms[[r1]], terms[[r2]])) / u
  }
  refs <- split(links$ref, links$doc)
  docs <- sort(names(refs))
  out <- list()
  for (a in seq_along(docs)) for (b in seq_along(docs)) {
    if (a >= b) next
    ra <- unique(refs[[docs[a]]]); rb <- unique(refs[[docs[b]]])
    w <- (sum(sapply(ra, function(r) max(sapply(rb, function(q) sim(r, q))))) +
            sum(sapply(rb, function(q) max(sapply(ra, function(r) sim(r, q)))))) / (length(ra) + length(rb))
    if (w > 0) out[[length(out) + 1]] <- data.frame(Source = docs[a], Target = docs[b], weight = w)
  }
  do.call(rbind, out)
}

test_that("DescriptiveBC matches the hand-computed value", {
  edges <- coupling_descriptive(toy_titles(), "doc", "ref", "title")

  # a = {r1, r2}, b = {r1, r3}: r1 matches itself (1); r2 and r3 share
  # {supply, shocks} out of {oil, supply, shocks, prices}: 0.5.
  # (1 + 0.5 + 1 + 0.5) / (2 + 2)
  expect_named(edges, c("from", "to", "weight", "Source", "Target"))
  expect_equal(nrow(edges), 1)
  expect_equal(weight_of(edges, "a", "b"), 0.75)
})

test_that("documents with no similar reference are not linked, and stop words are ignored", {
  edges <- coupling_descriptive(toy_titles(), "doc", "ref", "title")
  expect_false("c" %in% c(edges$Source, edges$Target))

  # with 'oil' as a stop word, r2 = {supply, shocks} and r3 = {supply, shocks, prices}: 2/3
  with_stop <- coupling_descriptive(toy_titles(), "doc", "ref", "title", stopwords = "oil")
  expect_equal(weight_of(with_stop, "a", "b"), (1 + 2 / 3 + 1 + 2 / 3) / 4)
})

test_that("without any title it is the Dice coefficient of the bibliographies", {
  toy <- toy_titles()
  toy$title <- NA_character_
  edges <- coupling_descriptive(toy, "doc", "ref", "title")

  expect_equal(nrow(edges), 1)
  expect_equal(weight_of(edges, "a", "b"), 2 * 1 / (2 + 2))
})

test_that("it agrees with a slow implementation, with targets and min_weight", {
  links <- data.frame(
    doc = c("a", "a", "a", "b", "b", "c", "c", "d", "d"),
    ref = c("r1", "r2", "r3", "r1", "r4", "r5", "r6", "r2", "r7"),
    title = c("inflation expectations", "oil supply shocks", "wage price spiral",
              "inflation expectations", "price expectations", "oil prices shocks",
              "monetary policy rules", "oil supply shocks", "wage rigidity")
  )
  fast <- sort_edges(coupling_descriptive(links, "doc", "ref", "title"))
  slow <- data.table::as.data.table(slow_descriptive(links))[order(Source, Target)]
  expect_equal(fast$weight, slow$weight)
  expect_equal(fast$Source, slow$Source)

  only_a <- coupling_descriptive(links, "doc", "ref", "title", targets = "a")
  expect_all_true(only_a$Source == "a" | only_a$Target == "a")
  expect_equal(sort(only_a$weight), sort(fast$weight[fast$Source == "a" | fast$Target == "a"]))

  expect_all_true(coupling_descriptive(links, "doc", "ref", "title", min_weight = 0.3)$weight > 0.3)
})

test_that("the weight is bounded by 1 and the input is not modified", {
  toy <- toy_titles()
  toy_before <- data.table::copy(toy)
  edges <- coupling_descriptive(toy, "doc", "ref", "title")
  expect_identical(toy, toy_before)
  expect_all_true(edges$weight <= 1)
})

test_that("arguments are checked and empty results warn", {
  expect_error(coupling_descriptive(toy_titles(), "doc", "ref", "nope"), "nope")
  expect_error(coupling_descriptive(toy_titles(), "doc", "ref", "title", targets = "zzz"), "targets")
  expect_error(coupling_descriptive(toy_titles(), "doc", "ref", "title", max_documents = 2), "too many")
  expect_warning(
    coupling_descriptive(toy_titles(), "doc", "ref", "title", min_weight = 0.99),
    class = "biblionetwork_no_edges"
  )
  conflicting <- rbind(toy_titles(), data.frame(doc = "c", ref = "r1", title = "another title"))
  expect_warning(coupling_descriptive(conflicting, "doc", "ref", "title"), "several different titles")
})

test_that("descriptive_terms() ranks the words of the matching references", {
  terms <- descriptive_terms(toy_titles(), "doc", "ref", "title", from = "a", to = "b")

  # b = {r1, r3}: best similarities 1 and 0.5; each word of r1 gets 1 / 2, the
  # words of r3 that appear in r2 too ('supply', 'shocks') 0.5 / 2; 'prices' 0.5 / 2
  expect_named(terms, c("term", "strength"))
  expect_equal(terms$strength[terms$term == "inflation"], 0.5)
  expect_equal(terms$strength[terms$term == "shocks"], 0.25)
  expect_lte(nrow(descriptive_terms(toy_titles(), "doc", "ref", "title", "a", "b", n_terms = 2)), 2)
  expect_error(descriptive_terms(toy_titles(), "doc", "ref", "title", "a", "zzz"), "documents of")
})

test_that("a pair of documents appears once, even if both documents are targets", {
  toy <- data.frame(
    doc = c("a", "a", "b", "b", "c", "c"),
    ref = c("r1", "r2", "r1", "r3", "r2", "r3"),
    title = c("inflation expectations", "oil supply shocks", "inflation expectations",
              "supply shocks prices", "oil supply shocks", "supply shocks prices")
  )
  edges <- coupling_descriptive(toy, "doc", "ref", "title", output_in_character = FALSE)
  expect_equal(nrow(edges), nrow(unique(edges[, c("Source", "Target")])))
  expect_equal(nrow(edges), 3)
})
