# Small fixtures built by hand, whose expected results are computed on paper
# in the tests. They are functions (not objects) so that each test builds its
# own data (self-sufficient tests).

# Four documents and their references:
#   d1 = {r1, r2, r3}, d2 = {r1, r2}, d3 = {r3, r4}, d4 = {r4, r5}
# Shared references: d1-d2: r1, r2; d1-d3: r3; d3-d4: r4. r5 is cited once.
# Every reference but r5 is cited by 2 documents out of N = 4.
toy_citations <- function() {
  data.frame(
    doc = c("d1", "d1", "d1", "d2", "d2", "d3", "d3", "d4", "d4"),
    ref = c("r1", "r2", "r3", "r1", "r2", "r3", "r4", "r4", "r5")
  )
}

# Papers and their authors: p1 = {a, b, c}, p2 = {a, b}, p3 = {d} (alone).
toy_authorships <- function() {
  data.frame(
    author = c("a", "b", "c", "a", "b", "d"),
    paper = c("p1", "p1", "p1", "p2", "p2", "p3")
  )
}

# Citing documents, their entity (e.g. a journal) and their references.
# N = 6 documents; r1 is cited by 5 documents, r2 by 3, r3 by 1.
#   E1: a1 -> r1, r2; a2 -> r1       (r1 twice, r2 once: L = 3)
#   E2: a3 -> r1, r2; a4 -> r1; a5 -> r1  (r1 three times, r2 once: L = 4)
#   E3: a6 -> r2, r3                 (L = 2)
toy_entities <- function() {
  data.frame(
    art = c("a1", "a1", "a2", "a3", "a3", "a4", "a5", "a6", "a6"),
    entity = c("E1", "E1", "E1", "E2", "E2", "E2", "E2", "E3", "E3"),
    ref = c("r1", "r2", "r1", "r1", "r2", "r1", "r1", "r2", "r3")
  )
}

# The weight of one pair, whatever the orientation of the pair.
weight_of <- function(edges, a, b) {
  edges <- as.data.frame(edges)
  pair <- (edges$Source == a & edges$Target == b) | (edges$Source == b & edges$Target == a)
  edges$weight[pair]
}

# Sorts the edges to compare two tables whatever their row order.
sort_edges <- function(edges) {
  edges <- data.table::as.data.table(edges)
  data.table::setkeyv(edges, NULL)
  edges[order(Source, Target)]
}

# A slow and obvious implementation of the coupling measures, with loops over
# all the pairs of documents, to cross-check the fast functions.
# `links` has columns `doc` and `ref`.
slow_coupling <- function(links, measure = c("angle", "strength", "similarity", "jaccard", "vladutz")) {
  measure <- match.arg(measure)
  links <- unique(links)
  links <- links[links$doc != links$ref, ]
  docs <- sort(unique(links$doc))
  refs_of <- split(links$ref, as.character(links$doc))
  refs <- function(d) refs_of[[as.character(d)]]
  n_docs <- length(docs)
  f <- table(links$ref)                       # citations of each reference
  freq <- function(r) as.numeric(f[as.character(r)])
  idf <- function(r) log(n_docs / freq(r))
  out <- list()
  for (i in seq_along(docs)) {
    for (j in seq_along(docs)) {
      if (i >= j) next
      a <- refs(docs[i])
      b <- refs(docs[j])
      shared <- intersect(a, b)
      if (length(shared) == 0) next
      weight <- switch(
        measure,
        angle = length(shared) / sqrt(length(a) * length(b)),
        strength = sum(idf(shared)) / (length(a) * length(b)),
        similarity = sum(idf(shared)) / sqrt(sum(idf(a)) * sum(idf(b))),
        jaccard = length(shared) / length(union(a, b)),
        vladutz = 4 / (length(a) + length(b)) * sum(1 / freq(shared))
      )
      if (is.nan(weight)) weight <- 0
      out[[length(out) + 1]] <- data.frame(
        Source = docs[i], Target = docs[j], nb_shared = length(shared), weight = weight
      )
    }
  }
  if (length(out) == 0) {
    return(data.frame(Source = docs[0], Target = docs[0], nb_shared = integer(), weight = numeric()))
  }
  do.call(rbind, out)
}

# The artificial example of Shen et al. (2019, Tables 1-4): ten articles (I to
# X) with five references each (A to V). The paper gives the Kessler coupling
# (number of shared references, Table 3) and the coupling strength without the
# lengths (Table 4, logarithms to base 10, N = 10).
shen_citations <- function() {
  refs <- list(
    I = c("A", "B", "C", "D", "E"), II = c("A", "B", "C", "D", "F"),
    III = c("A", "B", "G", "H", "I"), IV = c("A", "B", "C", "J", "K"),
    V = c("A", "B", "J", "K", "L"), VI = c("J", "K", "L", "M", "N"),
    VII = c("A", "B", "D", "P", "Q"), VIII = c("B", "C", "D", "R", "S"),
    IX = c("B", "D", "E", "T", "U"), X = c("A", "B", "C", "N", "V")
  )
  data.frame(doc = rep(names(refs), lengths(refs)), ref = unlist(refs, use.names = FALSE))
}

# Tables 3 and 4 of the paper, as lower triangles read row by row: row II has
# the value for I; row III those for I and II, etc.
shen_tables <- function() {
  rows <- c("II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X")
  kessler <- list(4, c(2, 2), c(3, 3, 2), c(2, 2, 2, 4), c(0, 0, 0, 2, 3),
                  c(3, 3, 2, 2, 2, 0), c(3, 3, 1, 2, 1, 0, 2),
                  c(3, 2, 1, 1, 1, 0, 2, 2), c(3, 3, 2, 3, 2, 1, 2, 2, 1))
  strength <- list(0.803, c(0.201, 0.201), c(0.502, 0.502, 0.201),
                   c(0.201, 0.201, 0.201, 1.246), c(0, 0, 0, 1.046, 1.745),
                   c(0.502, 0.201, 0.201, 0.201, 0.201, 0),
                   c(0.648, 0.648, 0.046, 0.347, 0.046, 0, 0.347),
                   c(1.046, 0.347, 0.046, 0.046, 0.046, 0, 0.347, 0.347),
                   c(0.502, 0.502, 0.201, 0.502, 0.201, 0.699, 0.201, 0.347, 0.046))
  all_rows <- c("I", rows)
  data.frame(
    a = rep(rows, lengths(kessler)),
    b = unlist(lapply(seq_along(rows), function(i) all_rows[seq_len(i)])),
    kessler = unlist(kessler),
    strength_log10 = unlist(strength)
  )
}
