# Bibliographic coupling edges, weighted by the idf-weighted cosine (SIM)

The cosine counterpart of
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md).
It is the similarity measure \\SIM\_{CS}\\ of (Shen et al. 2019) , which
generalises the coupling angle of
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md)
(Sen and Gan 1983) : instead of describing a document by a 0/1 vector
over references, it uses a vector whose components are the (square roots
of the) idf weights of the references, and takes the cosine of the
vectors of two documents. The weight is therefore bounded between 0 and
1.

## Usage

``` r
coupling_similarity(
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
  be linked (1 by default). It applies to the number of shared
  references, not to the weight.

- output_in_character:

  Logical. If `TRUE` (default), the identifiers are also returned as
  character columns `from` and `to`, to build a
  [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph
  more easily.

## Value

A `data.table` with one row per pair of documents sharing at least
`weight_threshold` references: the identifiers in `from` and `to`
(character if `output_in_character = TRUE`), the similarity in `weight`
(between 0 and 1), and the original identifiers in `Source` and
`Target`. Each pair appears once, with `Source < Target`.

## Details

**\[experimental\]**

Write \\N\\ for the number of citing documents in the table, \\f_j\\ for
the number of documents citing reference \\j\\, and \\\mathrm{idf}\_j =
\log(N / f_j)\\. The vector of document \\A\\ has one component per
reference of \\A\\, equal to \\\sqrt{\mathrm{idf}\_j}\\. The cosine of
two such vectors is

\$\$w\_{AB} = \frac{\sum\_{j \in R(A) \cap R(B)}
\mathrm{idf}\_j}{\sqrt{S(A) \\ S(B)}}, \qquad S(A) = \sum\_{j \in R(A)}
\mathrm{idf}\_j\$\$

where \\S(A)\\ sums the idf of *all* the references of \\A\\, shared or
not (the squared norm of its vector). The numerator is the numerator of
the coupling strength. The weight does not depend on the base of the
logarithm (the natural logarithm is used), since the base multiplies
numerator and denominator by the same constant.

References cited once have \\\mathrm{idf}\_j = \log N\\, the highest
value: they cannot create a tie but they increase \\S(A)\\, as the
references of any other kind. A document whose references are all cited
by all the documents has \\S = 0\\: its ties get a weight of 0.

Computing choices: see
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md)
(\\N\\ counts all the citing documents; duplicates and self-citations
are ignored; missing identifiers are dropped with a warning; the table
of the user is not modified; a zero-row table is returned, with a
warning, if no reference is shared). The same memory remark applies.

*Versions up to 0.1.1* returned a different quantity, wrongly computed
(see `NEWS.md`): do not compare with their results.

## Why use it in research

It combines the two qualities of the measures it generalises: like the
coupling strength, shared rare references count more than shared
classics; like the coupling angle, the weight is a cosine, bounded by 1,
and a long bibliography is normalised away. Use it when you want weights
with the same scale as the coupling angle (for instance to apply the
same threshold or community detection settings) while discounting the
references that all the corpus cites. (Shen et al. 2019) find that, on a
corpus of library and information science articles, this similarity is
very strongly correlated with the plain coupling angle (a Pearson
correlation of 0.996) and somewhat less with the coupling strength
(0.887): check on your own corpus, with
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
whether it changes anything.

## Intuition

Start from the picture of
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md):
the surprise of a shared reference is \\\log(N/f)\\. Now give every
reference of a document an importance equal to its surprise: a
bibliography of ten classics carries little information, a bibliography
of ten obscure papers carries much. The informational size \\S(A)\\ of a
document is the total surprise of its bibliography, and the similarity
compares the surprise that two documents share with their informational
sizes, like a cosine. Two documents with short but distinctive
bibliographies can be very similar, while two documents with long
bibliographies of classics cannot.

## References

Sen SK, Gan SK (1983). “A Mathematical Extension of the Idea of
Bibliographic Coupling and Its Applications.” *Annals of library science
and documentation*, **30**(2).  
  
Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.

## See also

Other coupling measures:
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md),
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md),
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md),
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)

## Examples

``` r
library(biblionetwork)
coupling_similarity(Ref_stagflation,
                    source = "Citing_ItemID_Ref",
                    ref = "ItemID_Ref")
#>             from         to     weight     Source     Target
#>           <char>     <char>      <num>      <int>      <int>
#>    1:    1021902    1184127 0.02944587    1021902    1184127
#>    2:     214927    2207578 0.12438825     214927    2207578
#>    3:    1184127    2901822 0.03451922    1184127    2901822
#>    4:    1184130    2901822 0.04213543    1184130    2901822
#>    5:    1717556    2901822 0.01910916    1717556    2901822
#>   ---                                                       
#> 2712: 1111111122 1111111183 0.03786992 1111111122 1111111183
#> 2713: 1111111134 1111111183 0.03197678 1111111134 1111111183
#> 2714: 1111111146 1111111183 0.03751466 1111111146 1111111183
#> 2715: 1111111161 1111111183 0.02909475 1111111161 1111111183
#> 2716: 1111111182 1111111183 0.24285542 1111111182 1111111183

# Toy example: for d3 and d4, N = 4, the shared reference r4 is cited by
# 2 documents, and S(d3) = 2 log(2), S(d4) = log(2) + log(4), so
# w = log(2) / sqrt(2 log(2) * 3 log(2))
toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2", "d3", "d3", "d4", "d4"),
                  ref = c("r1", "r2", "r3", "r1", "r2", "r3", "r4", "r4", "r5"))
coupling_similarity(toy, source = "doc", ref = "ref")
#>      from     to    weight Source Target
#>    <char> <char>     <num> <char> <char>
#> 1:     d1     d2 0.8164966     d1     d2
#> 2:     d1     d3 0.4082483     d1     d3
#> 3:     d3     d4 0.4082483     d3     d4
```
