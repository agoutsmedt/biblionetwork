# Bibliographic coupling edges, weighted by the coupling strength

Builds the edges of a bibliographic coupling network in which the shared
references are not all equal: sharing a reference that few documents
cite says more about the proximity of two documents than sharing a
reference that the whole corpus cites. The weight is the *coupling
strength* (Vladutz and Cook 1984; Shen et al. 2019) , a refinement of
the coupling angle of
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md)
that gives each shared reference a weight decreasing with its number of
citations, in the spirit of the inverse document frequency of
information retrieval (Spärck Jones 1972; Salton and Buckley 1988) (see
[tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)).

## Usage

``` r
coupling_strength(
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
(character if `output_in_character = TRUE`), the coupling strength in
`weight`, and the original identifiers in `Source` and `Target`. Each
pair appears once, with `Source < Target`.

## Details

**\[experimental\]**

Write \\N\\ for the number of citing documents in the table, \\f_j\\ for
the number of documents citing reference \\j\\, \\R(A)\\ for the
references of document \\A\\ and \\L(A) = \|R(A)\|\\ for the length of
its bibliography. The weight of the tie between \\A\\ and \\B\\ is

\$\$w\_{AB} = \frac{\sum\_{j \in R(A) \cap R(B)} \log(N / f_j)}{L(A) \\
L(B)}\$\$

A reference cited by every document has weight \\\log(1) = 0\\; a
reference cited by two documents has weight \\\log(N/2)\\. Contrary to
the coupling angle, the denominator is the product (not the square root
of the product) of the lengths, and the weight is not bounded by 1; the
scale of the weights depends on \\N\\, so that the weights are
meaningful relative to each other within one call, not across calls.
This is Eq. 7 of (Shen et al. 2019) , who use base-10 logarithms; the
natural logarithm used here multiplies all the weights by the same
constant (\\\ln 10\\), which changes no ranking and no correlation.
Unlike
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
the lengths \\L\\ are simple counts of references, not sums of idf
weights.

Computing choices:

- \\N\\ is the number of distinct citing documents in the table,
  *including* those that share no reference with any other document;

- \\L(A)\\ counts all the references of \\A\\, including those cited by
  no other document;

- duplicated rows are counted once, a document citing itself is ignored,
  and rows with a missing identifier are dropped with a warning;

- the table of the user is not modified;

- if no reference is shared (or if no pair reaches `weight_threshold`),
  a zero-row table is returned, with a warning that says why.

Memory: like all the coupling functions, it first lists all the pairs of
documents citing a same reference. A reference cited by \\n\\ documents
creates \\n (n - 1) / 2\\ pairs, and very popular references can exhaust
the memory. Since such references have the smallest weights, they can
often be removed before the call with little effect on the result.

## Why use it in research

In a corpus built around a topic (the stagflation literature, a journal,
a decade of central-banking research), a few references are cited by
most documents: they define the field but do not distinguish the
documents within it. With the coupling angle, two documents sharing only
such classics are as close as two documents sharing equally many rare
references. The coupling strength corrects this, and makes the resulting
network more suited to detecting sub-specialities. The cost is a measure
that depends on the whole corpus: the weight of a tie changes if
documents are added to the table, and is not comparable across corpora
of different sizes (see below).

## Intuition

Two economists who both cite the most famous paper of their field are
not necessarily working on the same question; two who both cite an
obscure working paper probably are. The coupling strength measures how
*surprising* a shared reference is: a reference cited by a fraction
\\f/N\\ of the corpus has a surprise of \\\log(N/f)\\, which is 0 for a
reference cited by everybody and grows as the reference gets rarer. The
tie is the total surprise of what two documents share, divided (as for
the coupling angle) by the lengths of the two bibliographies. It is the
same logic as the tf-idf of search engines, where a word found in every
text does not help to find a particular one.

## References

Salton G, Buckley C (1988). “Term-Weighting Approaches in Automatic Text
Retrieval.” *Information Processing & Management*, **24**(5), 513–523.  
  
Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.  
  
Spärck Jones K (1972). “A Statistical Interpretation of Term Specificity
and Its Application in Retrieval.” *Journal of Documentation*,
**28**(1), 11–21.  
  
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
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md),
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)

## Examples

``` r
library(biblionetwork)
coupling_strength(Ref_stagflation,
                  source = "Citing_ItemID_Ref",
                  ref = "ItemID_Ref")
#>             from         to      weight     Source     Target
#>           <char>     <char>       <num>      <int>      <int>
#>    1:    1021902    1184127 0.005870237    1021902    1184127
#>    2:     214927    2207578 0.020008623     214927    2207578
#>    3:    1184127    2901822 0.006565523    1184127    2901822
#>    4:    1184130    2901822 0.009848284    1184130    2901822
#>    5:    1717556    2901822 0.002563412    1717556    2901822
#>   ---                                                        
#> 2712: 1111111122 1111111183 0.009224890 1111111122 1111111183
#> 2713: 1111111134 1111111183 0.005902349 1111111134 1111111183
#> 2714: 1111111146 1111111183 0.008853523 1111111146 1111111183
#> 2715: 1111111161 1111111183 0.002629546 1111111161 1111111183
#> 2716: 1111111182 1111111183 0.038292193 1111111182 1111111183

# A toy example: d1 and d2 share r1 and r2, each cited by 2 of the
# 4 documents, so w = 2 * log(4 / 2) / (3 * 2)
toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2", "d3", "d3", "d4", "d4"),
                  ref = c("r1", "r2", "r3", "r1", "r2", "r3", "r4", "r4", "r5"))
coupling_strength(toy, source = "doc", ref = "ref")
#>      from     to    weight Source Target
#>    <char> <char>     <num> <char> <char>
#> 1:     d1     d2 0.2310491     d1     d2
#> 2:     d1     d3 0.1155245     d1     d3
#> 3:     d3     d4 0.1732868     d3     d4
```
