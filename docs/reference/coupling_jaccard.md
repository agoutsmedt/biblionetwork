# Bibliographic coupling edges, weighted by the relative coupling strength (Jaccard)

The *relative bibliographic coupling strength* of (Sen and Gan 1983) :
the number of references shared by two documents divided by the number
of references in the *union* of their bibliographies. It is a Jaccard
index, as noted by (Shen et al. 2019) (who credit Egghe and Rousseau,
1990). It is the other classic normalisation of the number of shared
references, next to the cosine of
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md).

## Usage

``` r
coupling_jaccard(
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
`output_in_character = TRUE`), the `weight` (between 0 and 1) and the
original identifiers in `Source` and `Target`. Each pair appears once,
with `Source < Target`.

## Details

**\[experimental\]**

With \\R(A)\\ the references of \\A\\ and \\L(A) = \|R(A)\|\\,

\$\$w\_{AB} = \frac{\|R(A) \cap R(B)\|}{L(A) + L(B) - \|R(A) \cap
R(B)\|} = \frac{\|R(A) \cap R(B)\|}{\|R(A) \cup R(B)\|}\$\$

Computing choices: see
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md).
\\L(A)\\ counts all the references of \\A\\, including those cited by no
other document.

## Why use it in research

Like the coupling angle, it corrects for the length of the
bibliographies, but differently: the cosine divides by the geometric
mean of the lengths, the Jaccard index by the size of the union. The
Jaccard index is never above the cosine, and penalises more strongly the
pairs of documents with bibliographies of very different lengths. Both
are bounded between 0 and 1 and give very similar rankings in practice
((Shen et al. 2019) report a Pearson correlation of 0.956 between the
two on their corpus): compare them on yours with
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md).

## Intuition

Take all the references cited by at least one of the two documents
(their union): the weight is the share of them that both documents cite.
It is the answer to "of everything these two documents read, how much
did they read in common?". If one document cites 5 references, all cited
by the other one, which cites 50, the cosine is \\5/\sqrt{250} \approx
0.32\\ and the Jaccard index \\5/50 = 0.1\\: the Jaccard index sees that
the second document reads much more than the first.

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
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md),
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)

## Examples

``` r
library(biblionetwork)
# d1 = {r1, r2, r3} and d2 = {r1, r2} share 2 references out of 3
toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2"),
                  ref = c("r1", "r2", "r3", "r1", "r2"))
coupling_jaccard(toy, source = "doc", ref = "ref")
#>      from     to    weight Source Target
#>    <char> <char>     <num> <char> <char>
#> 1:     d1     d2 0.6666667     d1     d2
```
