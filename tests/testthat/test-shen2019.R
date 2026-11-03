# The artificial example of Shen et al. (2019, Tables 1 to 4) is the only
# published set of numbers against which the measures can be checked.

test_that("the number of shared references matches Table 3 (Kessler coupling)", {
  table3 <- shen_tables()
  edges <- coupling_angle(shen_citations(), "doc", "ref", normalized_weight_only = FALSE)

  # the pairs with a coupling of 0 are not edges
  expect_equal(nrow(edges), sum(table3$kessler > 0))
  for (i in which(table3$kessler > 0)) {
    shared <- edges$nb_shared_references[
      (edges$Source == table3$a[i] & edges$Target == table3$b[i]) |
        (edges$Source == table3$b[i] & edges$Target == table3$a[i])
    ]
    expect_equal(shared, table3$kessler[i], info = paste(table3$a[i], table3$b[i]))
  }
})

test_that("the coupling strength matches Table 4", {
  table4 <- shen_tables()
  edges <- coupling_strength(shen_citations(), "doc", "ref")

  # Table 4 omits the lengths of the bibliographies (all equal to 5) and uses
  # base-10 logarithms: w = sum(log10(N / f)) * ln(10) / 5^2 in this package.
  # The paper rounds to three decimals.
  # The cell VII-II (0.201) is left out: articles I and II both share A, B and
  # D with VII (Table 3 gives 3 for both pairs, and the cell VII-I is 0.502),
  # so it should be 0.502, like VII-I. It looks like a typo of the paper.
  checked <- which(table4$strength_log10 > 0 & !(table4$a == "VII" & table4$b == "II"))
  expect_length(checked, 38)
  for (i in checked) {
    w <- weight_of(edges, table4$a[i], table4$b[i])
    expect_lt(abs(w * 25 / log(10) - table4$strength_log10[i]), 0.0021)
  }
})

test_that("the other measures give their definitions on the same example", {
  # I and II share 4 of their 5 references: angle 4/5, Jaccard 4/6
  expect_equal(weight_of(coupling_angle(shen_citations(), "doc", "ref"), "I", "II"), 4 / 5)
  expect_equal(weight_of(coupling_jaccard(shen_citations(), "doc", "ref"), "I", "II"), 4 / 6)
  # Vladutz-Cook: 4 / (5 + 5) * (1/7 + 1/9 + 1/5 + 1/5)
  expect_equal(weight_of(coupling_vladutz(shen_citations(), "doc", "ref"), "I", "II"),
               4 / 10 * (1 / 7 + 1 / 9 + 1 / 5 + 1 / 5))
})
