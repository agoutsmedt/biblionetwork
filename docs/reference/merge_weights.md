# Put the weights of several measures side by side, with their ranks

Joins a named list of edge tables (for instance the result of
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md))
by pair of nodes, with one column of weights per element, and, by
default, the rank of each pair under each measure and the gap between
the ranks of two measures. It is the table behind the other comparison
functions, and the tool to inspect the pairs on which two measures
disagree.

## Usage

``` r
merge_weights(
  edges,
  rank = TRUE,
  rank_gap = NULL,
  ties = c("average", "min", "max", "first")
)
```

## Arguments

- edges:

  A named list of edge tables, each with the columns `Source`, `Target`
  and `weight`. The tables are not modified.

- rank:

  Logical. If `TRUE` (default), adds one `rank_<name>` column per
  element of `edges`.

- rank_gap:

  Character vector of two names of `edges`, or `NULL` (default). If
  given, adds the `rank_gap` column, `rank_<second> - rank_<first>`. If
  `NULL` and `edges` has exactly two elements, the gap between them
  (second minus first) is computed. It requires `rank = TRUE`.

- ties:

  How ties are ranked, as in
  [`data.table::frank()`](https://rdrr.io/pkg/data.table/man/frank.html)
  (`"average"` by default).

## Value

A `data.table` with `Source`, `Target`, one column of weights per
element of `edges` and, according to the arguments, the `rank_<name>`
columns and `rank_gap`. A pair absent from a table (for instance because
tables were built with different thresholds) gets `NA`.

## Details

**\[experimental\]**

Weights of different measures do not have the same scale, but their
ranks do: rank 1 is the strongest pair of the measure. A pair with a
high weight for one measure and a low weight for another has a large
*gap* between the two ranks. The gap is

\$\$\mathrm{rank\\gap}\_{AB} = \mathrm{rank}\_{2}(A, B) -
\mathrm{rank}\_{1}(A, B)\$\$

with 1 and 2 the first and second elements of `rank_gap`: it is positive
when the second measure ranks the pair lower (as less close) than the
first one, negative when it ranks it higher. Sorting the table on the
gap (decreasing, then increasing) gives the pairs on which the measures
disagree the most.

Ranks are computed on the pairs present in *all* the tables, so that
they are comparable: the pairs that a measure does not have (for
instance those of
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md),
which links documents that share no reference) get `NA` ranks.

## See also

Other tools to compare coupling measures:
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md),
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md),
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md),
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md)

## Examples

``` r
library(biblionetwork)
edges <- compute_couplings(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
                           methods = c("angle", "strength"), weight_threshold = 2)
merged <- merge_weights(edges)
head(merged)
#> Key: <Source, Target>
#>     Source   Target      angle    strength rank_angle rank_strength rank_gap
#>      <int>    <int>      <num>       <num>      <num>         <num>    <num>
#> 1:  214927  2207578 0.14605935 0.020008623      315.5           138   -177.5
#> 2:  214927  8456979 0.09733285 0.011939901      703.0           316   -387.0
#> 3:  214927 10729971 0.29848100 0.047267549       20.0            23      3.0
#> 4:  214927 19627977 0.11202241 0.011401148      558.0           342   -216.0
#> 5:  214927 60300900 0.08944272 0.013267952      797.0           266   -531.0
#> 6: 1021902  8456979 0.06362848 0.005376741     1132.5           850   -282.5

# The pairs that the angle ranks high and the strength ranks low
head(merged[order(-rank_gap)])
#>      Source     Target     angle    strength rank_angle rank_strength rank_gap
#>       <int>      <int>     <num>       <num>      <num>         <num>    <num>
#> 1: 12824456  106566088 0.1616904 0.005202959      228.0           877    649.0
#> 2: 12824456   20533251 0.1519474 0.004992118      279.5           909    629.5
#> 3: 12824456   95433988 0.1025978 0.002810660      648.0          1260    612.0
#> 4: 20533251 1111111147 0.1264279 0.004107403      439.0          1039    600.0
#> 5: 12824456 1111111130 0.1378164 0.004683245      359.0           949    590.0
#> 6: 12824456  101777013 0.1111111 0.003452918      567.0          1150    583.0
```
