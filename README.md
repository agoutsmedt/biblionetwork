
<!-- README.md is generated from README.Rmd. Please edit that file -->

# biblionetwork

<!-- badges: start -->
<!-- badges: end -->

The goal of biblionetwork is to provide functions to create bibliometric
networks like bibliographic coupling network, co-citation network and
co-authorship network. The weights of network edges can be calculated
according to different methods, depending on the type of networks, the
type of nodes, and what you want to analyse. These functions are
optimized to be be used on very large dataset.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("agoutsmedt/biblionetwork")
```

## Example

This is a basic example using the data integrated in the package. It
uses the `biblio_coupling()` function which is the most general function
of the package. This function calculates the number of references that
different articles share together, as well as the coupling angle value
of edges in a bibliographic coupling network (Sen and Gan, 1983), from a
direct citation data frame. This is a standard way to build
bibliographic coupling network using Salton’s cosine measure: it divides
the number of references that two articles share by the rootsquare of
the product of both articles bibliography lengths. It avoids giving too
much importance to articles with a large bibliography.

The output is an edges data frame linking nodes together (see the `from`
and `to` columns) with a weight for each edge being the coupling angle
measure. If `normalized_weight_only` is set to be `FALSE`, another
column displays the number of references shared by the two nodes.

``` r
library(biblionetwork)

edges <- biblio_coupling(Ref_stagflation, source = "Citing_ItemID_Ref", ref = "ItemID_Ref", normalized_weight_only = FALSE)
```

This function is a relatively general function that can also be used:

1.  for title co-occurence networks (taking care of the lenght of the
    title thanks to the coupling angle measure);
2.  for co-authorship networks (taking care of the number of co-authors
    an author has collaborated with on a period)
