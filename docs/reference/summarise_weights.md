# Summarise the distribution of the weights of each measure

Describes the distribution of the weights of each measure: number of
edges, mean, standard deviation, extremes, quantiles, and the share of
weights equal to zero. (Shen et al. 2019) compare the measures through
the shape of their distributions (they report a smooth, right-skewed
distribution, well fitted by a lognormal, for the idf-weighted
similarity, and more scattered and irregular ones for the other measures
except the raw count), which matters when the weights are used by a
community detection algorithm or filtered by a threshold. Read the
summaries with the scales in mind: a cosine is bounded by 1, the
coupling strength is not, so means and quantiles of different measures
are not comparable. The `ratio_q99_median` column, a scale-free
indicator of how heavy the right tail is, is.

## Usage

``` r
summarise_weights(edges, probs = c(0.01, 0.25, 0.5, 0.75, 0.99))
```

## Arguments

- edges:

  A named list of edge tables with a `weight` column, for instance from
  [`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md).

- probs:

  Numeric vector of probabilities for the quantiles.

## Value

A `data.table` with one row per measure: `method`, `n_edges`, `mean`,
`sd`, `min`, one column per quantile (`q01`, `q25`...), `max`,
`share_zero` and `ratio_q99_median`.

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
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md),
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md)

## Examples

``` r
library(biblionetwork)
edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                           weight_threshold = 2)
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
```
