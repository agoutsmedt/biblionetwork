# Compute several coupling (or co-citation) measures at once

Computes several measures of bibliographic coupling (or of co-citation)
on the same table of citations and returns a named list of edge tables,
ready for
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md),
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md),
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md)
and
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md).
The costly step (finding all the pairs of nodes that share a reference)
is done only once, so computing the five measures costs little more than
computing one.

## Usage

``` r
compute_couplings(
  dt,
  source,
  ref,
  methods = c("angle", "strength", "similarity", "jaccard", "vladutz"),
  weight_threshold = 1,
  network = c("coupling", "cocitation"),
  title = NULL,
  descriptive_args = list()
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

- methods:

  Character vector, among `"angle"`
  ([`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md)),
  `"strength"`
  ([`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md)),
  `"similarity"`
  ([`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md)),
  `"jaccard"`
  ([`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md)),
  `"vladutz"`
  ([`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md))
  and `"descriptive"`
  ([`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md)).
  The first five are computed by default; `"descriptive"` is not, since
  it is much more costly (see the details), and it needs `title`.

- weight_threshold:

  Number. The minimum number of shared references for two documents to
  be linked (1 by default: any shared reference creates a tie). A
  threshold of 2 or 3 is common in large corpora, where sharing a single
  reference is weak evidence of proximity and produces very dense
  networks. It applies to the number of shared references, not to the
  normalised weight.

- network:

  `"coupling"` (default): the nodes are the documents of `source`.
  `"cocitation"`: the nodes are the references of `ref`, and the
  measures are those of
  [`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md).

- title:

  Character scalar. The column with the title of the cited references,
  needed (only) for `methods` including `"descriptive"`.

- descriptive_args:

  A list of further arguments for
  [`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md)
  (`targets`, `stopwords`, `min_weight`, `max_documents`).

## Value

A named list with one `data.table` per method, each with columns
`Source`, `Target` and `weight`. The tables of the five measures
describe the same pairs of nodes (those sharing at least
`weight_threshold` references, or co-cited at least `weight_threshold`
times), in the same order. The table of `"descriptive"` has its own
pairs.

## Details

**\[experimental\]**

The five measures that start from the shared references are computed on
the same pairs of nodes (those sharing at least `weight_threshold`
references), so that their weights can be compared pair by pair.
`"descriptive"` (the DescriptiveBC measure of (Liu 2017) ) is different
in two ways. It couples documents that cite *different but related*
references, so its pairs are not the same ones: any pair of documents
with similar titles of references is concerned, whatever the number of
shared references (the `weight_threshold` does not apply to it). And its
cost grows with the square of the number of documents: the function
informs you when you ask for it, and you should give `targets` or work
on a time window for a large corpus.
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md)
puts the tables side by side, with `NA` for the pairs a measure does not
have.

## Why use it in research

The choice of a measure is a modelling choice, not a technical detail:
it determines which pairs of documents look close, and thus the
communities found. (Shen et al. 2019) show on one corpus that the
measures can be very close (coupling angle and similarity) or quite
different (Vladutz-Cook and the others). Whether it matters for *your*
corpus can only be checked on your corpus: compute the measures with
this function, and compare the distributions and the rankings of the
weights.
[`vignette("comparing_measures")`](https://agoutsmedt.github.io/biblionetwork/articles/comparing_measures.md)
does it on the stagflation corpus.

## References

Liu R (2017). “A New Bibliographic Coupling Measure with Descriptive
Capability.” *Scientometrics*, **110**(2), 915–935.
[doi:10.1007/s11192-016-2196-7](https://doi.org/10.1007/s11192-016-2196-7)
.  
  
Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.

## See also

Other tools to compare coupling measures:
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md),
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md),
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md)

## Examples

``` r
library(biblionetwork)
edges <- compute_couplings(Ref_stagflation,
                           source = "Citing_ItemID_Ref",
                           ref = "ItemID_Ref",
                           weight_threshold = 2)
names(edges)
#> [1] "angle"      "strength"   "similarity" "jaccard"    "vladutz"   
summarise_weights(edges)
#>        method n_edges        mean         sd          min         q01
#>        <char>   <int>       <num>      <num>        <num>       <num>
#> 1:      angle    1501 0.107669186 0.06044895 0.0207223291 0.030740141
#> 2:   strength    1501 0.009367874 0.01299973 0.0005415795 0.001160528
#> 3: similarity    1501 0.070717811 0.04753687 0.0097282985 0.016752491
#> 4:    jaccard    1501 0.053513766 0.03310502 0.0103092784 0.014925373
#> 5:    vladutz    1501 0.022122321 0.02291125 0.0016339869 0.002849544
#>            q25        q50        q75        q99       max share_zero
#>          <num>      <num>      <num>      <num>     <num>      <num>
#> 1: 0.064051262 0.09274778 0.13483997 0.31250000 0.4291975          0
#> 2: 0.003600744 0.00606473 0.01070624 0.05099059 0.2537136          0
#> 3: 0.038402090 0.05799043 0.08680766 0.24852872 0.3578691          0
#> 4: 0.030612245 0.04444444 0.06756757 0.17647059 0.2692308          0
#> 5: 0.008720930 0.01487280 0.02681704 0.11333333 0.2230769          0
#>    ratio_q99_median
#>               <num>
#> 1:         3.369353
#> 2:         8.407726
#> 3:         4.285685
#> 4:         3.970588
#> 5:         7.620175
correlate_weights(edges)
#>                angle  strength similarity   jaccard   vladutz
#> angle      1.0000000 0.8523666  0.9592276 0.9802158 0.6866473
#> strength   0.8523666 1.0000000  0.9005974 0.8121718 0.7284654
#> similarity 0.9592276 0.9005974  1.0000000 0.9375955 0.8410196
#> jaccard    0.9802158 0.8121718  0.9375955 1.0000000 0.7018655
#> vladutz    0.6866473 0.7284654  0.8410196 0.7018655 1.0000000
#> attr(,"n_pairs")
#> [1] 1501

# The titles-based measure is not computed by default; it needs the titles of the references
# \donttest{
toy <- data.frame(
  doc = c("a", "a", "b", "b"),
  ref = c("r1", "r2", "r1", "r3"),
  title = c("inflation expectations", "oil supply shocks",
            "inflation expectations", "supply shocks prices")
)
compute_couplings(toy, "doc", "ref", methods = c("angle", "descriptive"), title = "title")
#> ℹ Computing the "descriptive" measure of Liu (2017), which is not part of the
#>   default measures.
#> ! Its cost grows with the square of the number of documents, and its pairs are
#>   not those of the other measures: documents with no shared reference can be
#>   linked.
#> ℹ For a large corpus, give `descriptive_args = list(targets = ...)` or work by
#>   time window.
#> $angle
#>    Source Target weight
#>    <char> <char>  <num>
#> 1:      a      b    0.5
#> 
#> $descriptive
#>    Source Target weight
#>    <char> <char>  <num>
#> 1:      a      b   0.75
#> 
# }
```
