# Co-citation edges, with the same weights as the coupling measures

Builds the edges of a *co-citation* network from a table of direct
citations (one row per citing document and cited reference). Two
references are co-cited when at least one document cites both of them
(Small 1973) . By default the weight is the co-citation angle (Sen and
Gan 1983) : the number of documents citing both references, divided by
the geometric mean of the numbers of citations received by each of them.
With `method`, the co-citation can also be weighted like the coupling
measures
([`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md),
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md)):
see the section on the idf weights below.

## Usage

``` r
biblio_cocitation(
  dt,
  source,
  ref,
  normalized_weight_only = TRUE,
  weight_threshold = 1,
  output_in_character = TRUE,
  method = c("angle", "strength", "similarity", "jaccard", "vladutz")
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

  Character scalar. The column of the cited references: they are the
  nodes of the co-citation network.

- normalized_weight_only:

  Logical. If `FALSE`, the number of documents citing both references is
  returned in addition to the normalised `weight`.

- weight_threshold:

  Number. The minimum number of documents that must cite two references
  together for them to be linked (1 by default).

- output_in_character:

  Logical. If `TRUE` (default), the identifiers are also returned as
  character columns `from` and `to`, to build a
  [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph
  more easily.

- method:

  The weight: `"angle"` (default, the co-citation angle), `"strength"`,
  `"similarity"`, `"jaccard"` or `"vladutz"` (see above).

## Value

A `data.table` with one row per pair of references: the identifiers in
`from` and `to` (if `output_in_character = TRUE`), the `weight` and, if
`normalized_weight_only = FALSE`, `nb_shared_citations`. The original
identifiers are kept in `Source` and `Target`. Each pair appears once,
with `Source < Target`.

## Details

**\[experimental\]**

Write \\C(A)\\ for the set of documents citing reference \\A\\. The
weight of the tie between references \\A\\ and \\B\\ with the default
`method = "angle"` is

\$\$w\_{AB} = \frac{\|C(A) \cap C(B)\|}{\sqrt{\|C(A)\| \\ \|C(B)\|}}\$\$

The numerator is the number of documents citing both references
(returned as `nb_shared_citations` when
`normalized_weight_only = FALSE`). The other methods are those of the
coupling functions, applied to the references as nodes: see the
documentation of each, replacing "document" by "reference" and
"reference" by "citing document".

Computing choices:

- \\\|C(A)\|\\ is the number of citations received in the *whole* table,
  including from documents that cite only one reference;

- documents citing a single reference cannot co-cite anything and are
  ignored in the numerator;

- duplicated rows are counted once, and rows with a missing identifier
  are dropped with a warning;

- the table of the user is not modified;

- if no pair of references is co-cited (or none reaches
  `weight_threshold`), a zero-row table is returned with a warning
  explaining why.

Memory and speed: the pairs are computed with sparse matrices, as in
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md);
a few documents with extremely long bibliographies still create many
pairs. Consider removing them first.

## Why use it in research

Where bibliographic coupling looks at what documents *use*, co-citation
looks at how the community *perceives* cited documents: references that
are regularly cited together are considered by citing authors as
belonging to the same body of work. Co-citation networks are the classic
tool to map the intellectual base of a field (schools, paradigms,
canonical references) and to identify the key texts of each cluster
(Boyack et al. 2005; Boyack and Klavans 2010; Yan and Ding 2012) .
Unlike coupling, a co-citation network is not fixed at the date of
publication of the cited documents: it depends on later citations, and
thus changes as the corpus of citing documents grows. This is a feature
if you want to study how the reception of texts evolves, but it must be
kept in mind when comparing time windows. A reference that is rarely
cited has a very uncertain position, hence the interest of
`weight_threshold`.

## Intuition

Imagine that each citing document is a reading list. Two references that
appear together on many lists are probably about related things. The
weight with `method = "angle"` asks: among all the lists where *one* of
the two references appears, how often is the other one there too? A
reference cited a thousand times appears on many lists by default, so it
must be seen with another reference much more often to be considered
close to it: that is what the division by the number of citations does.

## Weighting the co-citing documents (the idf methods)

The idf measures of the coupling functions give more weight to a rare
shared item. In coupling, the shared items are references, and a
reference cited by few documents is rare. Co-citation is the mirror
image (Rousseau 2010) : the shared items are the *citing documents*, and
a citing document is "rare" when it cites few references. The intuition
is again about reading lists: a document that cites only 8 references
and puts A and B among them tells much more about the closeness of A and
B than a review that cites 300 references and puts A and B among them by
completeness. With `method = "strength"` (and `"similarity"`), the
co-citation of A and B by a document \\d\\ is weighted by \\\log(M /
L_d)\\, with \\M\\ the number of references in the table and \\L_d\\ the
number of references of \\d\\. This is a direct transposition of the
formulas of
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md)
and
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md)
(swapping the two columns of the table): it is not a measure proposed in
the literature as such, so compare it with the default on your corpus
([`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md)
with `network = "cocitation"`).

## References

Boyack KW, Klavans R (2010). “Co-Citation Analysis, Bibliographic
Coupling, and Direct Citation: Which Citation Approach Represents the
Research Front Most Accurately?” *Journal of the American Society for
Information Science and Technology*, **61**(12), 2389–2404.
[doi:10.1002/asi.21419](https://doi.org/10.1002/asi.21419) .  
  
Boyack KW, Klavans R, Börner K (2005). “Mapping the Backbone of
Science.” *Scientometrics*, **64**(3), 351–374.
[doi:10.1007/s11192-005-0255-6](https://doi.org/10.1007/s11192-005-0255-6)
.  
  
Rousseau R (2010). “Bibliographic Coupling and Co-Citation as Dual
Notions.” In *The Janus Faced Scholar: A Festschrift in Honour of Peter
Ingwersen*, 167–173. Royal School of Library and Information Science,
Copenhagen.  
  
Sen SK, Gan SK (1983). “A Mathematical Extension of the Idea of
Bibliographic Coupling and Its Applications.” *Annals of library science
and documentation*, **30**(2).  
  
Small H (1973). “Co-Citation in the Scientific Literature: A New Measure
of the Relationship between Two Documents.” *Journal of the American
Society for Information Science*, **24**(4), 265–269.
[doi:10.1002/asi.4630240406](https://doi.org/10.1002/asi.4630240406) .  
  
Yan E, Ding Y (2012). “Scholarly Network Similarities: How Bibliographic
Coupling Networks, Citation Networks, Cocitation Networks, Topical
Networks, Coauthorship Networks, and Coword Networks Relate to Each
Other.” *Journal of the American Society for Information Science and
Technology*, **63**(7), 1313–1326.
[doi:10.1002/asi.22680](https://doi.org/10.1002/asi.22680) .

## See also

Other co-citation and co-authorship measures:
[`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md)

## Examples

``` r
library(biblionetwork)
# Co-citation network of the references of the stagflation corpus,
# keeping the pairs co-cited at least three times
edges <- biblio_cocitation(Ref_stagflation,
                           source = "Citing_ItemID_Ref",
                           ref = "ItemID_Ref",
                           weight_threshold = 3)
head(edges)
#>      from     to    weight Source Target
#>    <char> <char>     <num>  <int>  <int>
#> 1: 181882 214939 0.2121320 181882 214939
#> 2: 181882 364710 0.3162278 181882 364710
#> 3: 181483 364716 0.6123724 181483 364716
#> 4: 181882 364716 0.2371708 181882 364716
#> 5: 214939 364716 0.3354102 214939 364716
#> 6: 364758 364765 1.0000000 364758 364765

# The same pairs, weighted by the specificity of the co-citing documents
head(biblio_cocitation(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                       weight_threshold = 3, method = "strength"))
#>      from     to     weight Source Target
#>    <char> <char>      <num>  <int>  <int>
#> 1: 181882 214939 0.05536295 181882 214939
#> 2: 181882 364710 0.10082702 181882 364710
#> 3: 181483 364716 0.51473013 181483 364716
#> 4: 181882 364716 0.08730949 181882 364716
#> 5: 214939 364716 0.14425521 214939 364716
#> 6: 364758 364765 1.50258125 364758 364765
```
