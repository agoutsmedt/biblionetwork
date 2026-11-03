# Overlap between the strongest edges of several measures

For each pair of measures, the Jaccard index between the sets of their
strongest edges (the `top` share of the edges with the highest weights).
Correlations summarise all the edges, but a network analysis often
relies on the strongest ones (after a filtering of the weak ties). This
function tells how many of the strongest ties two measures have in
common: 1 means the same strongest edges, 0 none in common.

## Usage

``` r
overlap_top_weights(edges, top = 0.1)
```

## Arguments

- edges:

  A named list of at least two edge tables, for instance from
  [`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md).

- top:

  Share of edges kept for each measure, between 0 and 1 (0.1 by default:
  the top 10% of the edges). Ties at the threshold are all kept.

## Value

A symmetric matrix of Jaccard indices, with the number of edges kept by
each measure in the attribute `"n_top"`.

## Details

**\[experimental\]**

## See also

Other tools to compare coupling measures:
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md),
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md),
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md),
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md)

## Examples

``` r
library(biblionetwork)
edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                           weight_threshold = 2)
overlap_top_weights(edges, top = 0.1)
#>                angle  strength similarity   jaccard   vladutz
#> angle      1.0000000 0.3853211  0.7660819 0.7869822 0.4046512
#> strength   0.3853211 1.0000000  0.4519231 0.3727273 0.3482143
#> similarity 0.7660819 0.4519231  1.0000000 0.6593407 0.5024876
#> jaccard    0.7869822 0.3727273  0.6593407 1.0000000 0.3789954
#> vladutz    0.4046512 0.3482143  0.5024876 0.3789954 1.0000000
#> attr(,"n_top")
#>      angle   strength similarity    jaccard    vladutz 
#>        151        151        151        151        151 
```
