# Bibliographic coupling edges, with the weighting method of your choice

The general entry point to bibliographic coupling. From a table of
direct citations (one row per citing document and cited reference), it
returns the edges of the network linking the documents that share
references (Kessler 1963) , weighted by the `method` you choose. It is a
thin wrapper: every method is also available as a function of its own,
which documents the formula and the reasons to choose it.

|  |  |  |
|----|----|----|
| `method` | Function | Weight |
| `"angle"` (default) | [`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md) | cosine of the bibliographies (Sen and Gan 1983) |
| `"strength"` | [`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md) | shared references weighted by their rarity (Shen et al. 2019) |
| `"similarity"` | [`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md) | idf-weighted cosine (Shen et al. 2019) |
| `"jaccard"` | [`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md) | shared references over the union of the bibliographies (Sen and Gan 1983) |
| `"vladutz"` | [`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md) | Vladutz and Cook formula (Vladutz and Cook 1984) |

In versions up to 0.1.1, `biblio_coupling()` was what is now
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md):
calls that leave `method` to its default give the same result. To
compare several methods at once on the same corpus, use
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md);
to couple authors, journals or institutions rather than documents, use
[`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md);
to link cited references, use
[`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md).

## Usage

``` r
biblio_coupling(
  dt,
  source,
  ref,
  method = c("angle", "strength", "similarity", "jaccard", "vladutz"),
  normalized_weight_only = TRUE,
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

- method:

  The weighting method, one of `"angle"` (default), `"strength"`,
  `"similarity"`, `"jaccard"` and `"vladutz"`. See the table above and
  the help page of each function.

- normalized_weight_only:

  Logical. If `FALSE`, the number of shared references is returned in
  addition to the normalised `weight`.

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
`weight_threshold` references: `Source` and `Target` (identifiers, with
`Source < Target`), `from` and `to` (the same, as characters, if
`output_in_character = TRUE`), the `weight` and, if
`normalized_weight_only = FALSE`, `nb_shared_references`. Whatever the
method, the weights of different methods do not have the same scale: see
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md)
to compare them.

## Details

**\[experimental\]**

## References

Kessler MM (1963). “Bibliographic Coupling between Scientific Papers.”
*American Documentation*, **14**(1), 10–25.
[doi:10.1002/asi.5090140103](https://doi.org/10.1002/asi.5090140103) .  
  
Sen SK, Gan SK (1983). “A Mathematical Extension of the Idea of
Bibliographic Coupling and Its Applications.” *Annals of library science
and documentation*, **30**(2).  
  
Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.  
  
Vladutz G, Cook J (1984). “Bibliographic Coupling and Subject
Relatedness.” *Proceedings of the American Society for Information
Science*, **21**, 204–207.

## See also

Other coupling measures:
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md),
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md),
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md),
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)

## Examples

``` r
library(biblionetwork)
# The default is the coupling angle...
head(biblio_coupling(Ref_stagflation,
                     source = "Citing_ItemID_Ref",
                     ref = "ItemID_Ref",
                     weight_threshold = 3))
#>       from       to     weight  Source   Target
#>     <char>   <char>      <num>   <int>    <int>
#> 1:  214927  2207578 0.14605935  214927  2207578
#> 2: 5160307  6714008 0.09128709 5160307  6714008
#> 3: 1717556  7815498 0.16564729 1717556  7815498
#> 4:  214927  8456979 0.09733285  214927  8456979
#> 5: 2207578  8456979 0.11846978 2207578  8456979
#> 6: 5240516 10585974 0.14726421 5240516 10585974

# ...and the method changes the weights, not the pairs of documents
head(biblio_coupling(Ref_stagflation,
                     source = "Citing_ItemID_Ref",
                     ref = "ItemID_Ref",
                     method = "strength",
                     weight_threshold = 3))
#>       from       to     weight  Source   Target
#>     <char>   <char>      <num>   <int>    <int>
#> 1:  214927  2207578 0.02000862  214927  2207578
#> 2: 5160307  6714008 0.01061175 5160307  6714008
#> 3: 1717556  7815498 0.03526234 1717556  7815498
#> 4:  214927  8456979 0.01193990  214927  8456979
#> 5: 2207578  8456979 0.01280790 2207578  8456979
#> 6: 5240516 10585974 0.01146359 5240516 10585974
```
