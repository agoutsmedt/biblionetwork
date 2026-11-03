# Correlate the weights of several measures

Computes the correlation between the weights of each pair of measures,
over the pairs of nodes present in all the tables, as (Shen et al. 2019)
do with Pearson correlations. The default is the Spearman rank
correlation, which compares the *rankings* of the pairs and does not
depend on the scale of the weights: it is the relevant one when the
weights are only used to order or filter edges, as in most community
detection settings. Pearson correlations (the paper's choice) are
sensitive to the scale and to extreme values, and thus differ much more
between a bounded cosine and an unbounded strength.

## Usage

``` r
correlate_weights(edges, method = c("spearman", "pearson", "kendall"))
```

## Arguments

- edges:

  A named list of at least two edge tables, for instance from
  [`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md).

- method:

  `"spearman"` (default), `"pearson"` or `"kendall"`.

## Value

A correlation matrix, with the number of pairs of nodes used in the
attribute `"n_pairs"`.

## Details

**\[experimental\]**

## References

Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.

## See also

Other tools to compare coupling measures:
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md),
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md),
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md),
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md)

## Examples

``` r
library(biblionetwork)
edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                           weight_threshold = 2)
correlate_weights(edges)
#>                angle  strength similarity   jaccard   vladutz
#> angle      1.0000000 0.8523666  0.9592276 0.9802158 0.6866473
#> strength   0.8523666 1.0000000  0.9005974 0.8121718 0.7284654
#> similarity 0.9592276 0.9005974  1.0000000 0.9375955 0.8410196
#> jaccard    0.9802158 0.8121718  0.9375955 1.0000000 0.7018655
#> vladutz    0.6866473 0.7284654  0.8410196 0.7018655 1.0000000
#> attr(,"n_pairs")
#> [1] 1501
correlate_weights(edges, method = "pearson")
#>                angle  strength similarity   jaccard   vladutz
#> angle      1.0000000 0.6472621  0.9698954 0.9781405 0.6996622
#> strength   0.6472621 1.0000000  0.7063183 0.6114331 0.6510810
#> similarity 0.9698954 0.7063183  1.0000000 0.9500334 0.8217881
#> jaccard    0.9781405 0.6114331  0.9500334 1.0000000 0.7197476
#> vladutz    0.6996622 0.6510810  0.8217881 0.7197476 1.0000000
#> attr(,"n_pairs")
#> [1] 1501
```
