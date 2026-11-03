# Terms that describe why a document is related to another (DTerms)

The second contribution of (Liu 2017) : given two documents, it extracts
the words of the titles of the references of one (`to`) that best
indicate in what respect it is related to the other (`from`). It
complements
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md):
the weight says *how much* two documents are related, the terms say
*why*.

## Usage

``` r
descriptive_terms(
  dt,
  source,
  ref,
  title,
  from,
  to,
  n_terms = 10,
  stopwords = NULL
)
```

## Arguments

- dt:

  A data frame or a `data.table` of direct citations, one row per link
  between a citing document and a cited reference. It is not modified.

- source:

  Character scalar. The column of the citing documents: they are the
  nodes of the coupling network.

- ref:

  Character scalar. The column of the cited references.

- title:

  Character scalar. The column with the title of the cited reference
  (one title per reference).

- from, to:

  Identifiers of two documents (values of `source`).

- n_terms:

  Number of terms to return.

- stopwords:

  Character vector of words to ignore in the titles (`NULL`: none).

## Value

A `data.table` with the `term` and its `strength`, in decreasing order.

## Details

**\[experimental\]**

The descriptive strength of a term \\t\\ is (Eq. 6 of the paper)

\$\$D(t) = \frac{\sum\_{r' \in R\_{to},\\ t \in T(r')} \max\_{r \in
R\_{from}} \mathrm{Sim}(r, r')}{\|R\_{to}\|}\$\$

with \\\mathrm{Sim}\\ the reference similarity of
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md).
The `n_terms` terms with the highest strength are returned (the paper
suggests about 10, the length of a title). The relation is not
symmetric: swap `from` and `to` to explain the relation the other way.

## Intuition

A document cites references for each of its issues. The references of
`to` that have a close match among the references of `from` are the
issues the two documents have in common, and the words of their titles
name these issues. A word is a good descriptor if it appears in many
references of `to`, and if these references are close to references of
`from`.

## References

Liu R (2017). “A New Bibliographic Coupling Measure with Descriptive
Capability.” *Scientometrics*, **110**(2), 915–935.
[doi:10.1007/s11192-016-2196-7](https://doi.org/10.1007/s11192-016-2196-7)
.

## See also

Other coupling measures:
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md),
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md),
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md)

## Examples

``` r
library(biblionetwork)
toy <- data.frame(
  doc = c("a", "a", "b", "b"),
  ref = c("r1", "r2", "r1", "r3"),
  title = c("inflation expectations", "oil supply shocks",
            "inflation expectations", "supply shocks prices")
)
descriptive_terms(toy, "doc", "ref", "title", from = "a", to = "b")
#>            term strength
#>          <char>    <num>
#> 1: expectations     0.50
#> 2:    inflation     0.50
#> 3:       prices     0.25
#> 4:       shocks     0.25
#> 5:       supply     0.25
```
