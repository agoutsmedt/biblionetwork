# Bibliographic coupling edges, weighted by the Vladutz-Cook formula

The first coupling measure that weights shared references by their
rarity, proposed by (Vladutz and Cook 1984) and reported by (Shen et al.
2019) (their Eq. 6). It is the ancestor of
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
which (Shen et al. 2019) present as a correction of it based on the
probabilistic interpretation of the inverse document frequency.

## Usage

``` r
coupling_vladutz(
  dt,
  source,
  ref,
  weight_threshold = 1,
  output_in_character = TRUE
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

- weight_threshold:

  Number. The minimum number of shared references for two documents to
  be linked (1 by default: any shared reference creates a tie). A
  threshold of 2 or 3 is common in large corpora, where sharing a single
  reference is weak evidence of proximity and produces very dense
  networks. It applies to the number of shared references, not to the
  normalised weight.

- output_in_character:

  Logical. If `TRUE` (default), the identifiers are also returned as
  character columns `from` and `to`, to build a
  [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph
  more easily.

## Value

A `data.table` with one row per pair of documents sharing at least
`weight_threshold` references: `from` and `to` (character if
`output_in_character = TRUE`), the `weight` and the original identifiers
in `Source` and `Target`. Each pair appears once, with
`Source < Target`.

## Details

**\[experimental\]**

Write \\f_j\\ for the number of documents citing reference \\j\\ and
\\L(A)\\ for the length of the bibliography of \\A\\.

\$\$w\_{AB} = \frac{4}{L(A) + L(B)} \sum\_{j \in R(A) \cap R(B)}
\frac{1}{f_j}\$\$

The factor 4 is a normalisation that changes no ranking. It makes the
weight reach 1 for two documents with identical bibliographies made of
references each cited by exactly two documents; since shared references
have \\f_j \geq 2\\, the weight is never above 1. Computing choices: see
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md).

## Why use it in research

It is provided mainly for comparison and replication: it also discounts
the references cited by many documents, but the weight of a reference
decreases as \\1/f_j\\ instead of \\\log(N/f_j)\\, so that it almost
ignores all the references except the rarest ones. In the corpus of
(Shen et al. 2019) it differs markedly from the other measures
(correlations of about 0.6 to 0.7 with the relative coupling, the
coupling angle, the coupling strength and the similarity). Use
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md)
and
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md)
to see how much it matters on your corpus.

## Intuition

A shared reference counts for the *inverse* of the number of documents
that cite it: a reference shared by two documents and cited by nobody
else counts \\1/2\\, one cited by a hundred documents counts \\1/100\\.
This is a very steep discount: the measure is almost entirely driven by
the rarest references. The sum is then divided by the average length of
the two bibliographies (the factor 4 is a convenient scaling). Compare
with
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
whose discount (a logarithm) is much gentler.

## References

Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.  
  
Vladutz G, Cook J (1984). “Bibliographic Coupling and Subject
Relatedness.” *Proceedings of the American Society for Information
Science*, **21**, 204–207.

## See also

Other coupling measures:
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md),
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md),
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)

## Examples

``` r
library(biblionetwork)
toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2", "d3", "d3", "d4", "d4"),
                  ref = c("r1", "r2", "r3", "r1", "r2", "r3", "r4", "r4", "r5"))
coupling_vladutz(toy, source = "doc", ref = "ref")
#>      from     to weight Source Target
#>    <char> <char>  <num> <char> <char>
#> 1:     d1     d2    0.8     d1     d2
#> 2:     d1     d3    0.4     d1     d3
#> 3:     d3     d4    0.5     d3     d4
```
