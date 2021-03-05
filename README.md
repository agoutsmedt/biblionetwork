biblionetwork
================

<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![Travis build
status](https://travis-ci.com/agoutsmedt/biblionetwork.svg?branch=main)](https://travis-ci.com/agoutsmedt/biblionetwork)
<!-- badges: end -->

The goal of biblionetwork is to provide functions to create bibliometric
networks like bibliographic coupling network, co-citation network and
co-authorship network. It identifies edges and calculates the weights
according to different methods, depending on the type of networks, the
type of nodes, and what you want to analyse. These functions are
optimized to be used on very large dataset.

The original function, which uses data.table ([Dowle and Srinivasan
2020](#ref-datatable)) and allows the user to find edges and calculate
weights for large networks, was developed by [François
Claveau](https://www.usherbrooke.ca/philosophie/nous-joindre/personnel-enseignant/claveau-francois/).
The different functions in this package have been developed, from
Claveau’s original idea, by [Alexandre
Truc](https://sites.google.com/view/alexandre-truc/home-and-contact) and
[Aurélien Goutsmedt](https://aurelien-goutsmedt.com/). The package is
maintained by Aurélien Goutsmedt.[1]

You can cite this package as:

``` r
citation("biblionetwork")
#> 
#> To cite biblionetwork in publications use:
#> 
#>   Aurélien Goutsmedt, François Claveau and Alexandre Truc (2021).
#>   biblionetwork: A Package For Creating Different Types of Bibliometric
#>   Networks. R package version 0.0.0.9000.
#>   https://github.com/agoutsmedt/biblionetwork
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {biblionetwork: A Package For Creating Different Types of Bibliometric Networks},
#>     author = {Aurélien Goutsmedt and François Claveau and Alexandre Truc},
#>     year = {2021},
#>     note = {R package version 0.0.0.9000},
#>     url = {https://github.com/agoutsmedt/biblionetwork},
#>   }
#> 
#> As biblionetwork is continually evolving, you may want to cite its
#> version number. Find it with 'help(package=biblionetwork)'.
```

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("agoutsmedt/biblionetwork")
```

## Example

The basic function of the package is the `biblio_coupling()` function.
This function calculates the number of references that different
articles share together, as well as the coupling angle value of edges in
a bibliographic coupling network ([Sen and Gan 1983](#ref-sen1983)).
What you need is just a file with entities (documents, authors,
universities, *etc.*) citing references.[2] See the
`vignette("Using_biblionetwork")` for a more in-depth presentation of
the package.

This example use the [data incorporated](#incorporated-data) in the
package.

``` r
library(biblionetwork)

biblio_coupling(Ref_stagflation, 
                source = "Citing_ItemID_Ref", 
                ref = "ItemID_Ref", 
                normalized_weight_only = FALSE, 
                weight_threshold = 1)
#>             from         to     weight nb_shared_references     Source
#>    1:     214927    2207578 0.14605935                    4     214927
#>    2:     214927    5982867 0.04082483                    1     214927
#>    3:     214927    8456979 0.09733285                    3     214927
#>    4:     214927   10729971 0.29848100                    7     214927
#>    5:     214927   16008556 0.04714045                    1     214927
#>   ---                                                                 
#> 2712: 1111111161 1111111172 0.03434014                    1 1111111161
#> 2713: 1111111161 1111111180 0.02003610                    1 1111111161
#> 2714: 1111111161 1111111183 0.04050542                    2 1111111161
#> 2715: 1111111172 1111111180 0.03646625                    1 1111111172
#> 2716: 1111111182 1111111183 0.27060404                    8 1111111182
#>           Target
#>    1:    2207578
#>    2:    5982867
#>    3:    8456979
#>    4:   10729971
#>    5:   16008556
#>   ---           
#> 2712: 1111111172
#> 2713: 1111111180
#> 2714: 1111111183
#> 2715: 1111111180
#> 2716: 1111111183
```

## Incorporated data

The biblionetwork package contains bibliometric data built by
[Goutsmedt](#ref-goutsmedt2021a) ([2021](#ref-goutsmedt2021a)). These
data gather the academic articles and books, published between 1975 and
2013, that endeavoured to explain the United States stagflation of the
1970s. They also gather all the references cited by these articles and
books on stagflation. The `Nodes_stagflation.rda` file contains
information about the academic articles and books on stagflation (the
staflation documents), as well as about the references cited at least by
two of these stagflation documents. The `Ref_stagflation.rda` is a data
frame of direct citations, with the identifiers of citing documents, and
the identifiers of cited documents. The `Authors_stagflation.rda` is a
data frame with the list of documents explaining the US stagflation, and
all the authors of these documents (`Nodes_stagflation.rda` just takes
the first author for each document).

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-datatable" class="csl-entry">

Dowle, Matt, and Arun Srinivasan. 2020. *Data.table: Extension of
‘Data.frame‘*. <https://CRAN.R-project.org/package=data.table>.

</div>

<div id="ref-goutsmedt2021a" class="csl-entry">

Goutsmedt, Aurélien. 2021. “From the Stagflation to the Great Inflation:
Explaining the US Economy of the 1970s.” *Revue d’Economie Politique*
Forthcoming.
<https://aurelien-goutsmedt.com/media/pdf/stagflation-great-inflation.pdf>.

</div>

<div id="ref-sen1983" class="csl-entry">

Sen, Subir K., and Shymal K. Gan. 1983. “A Mathematical Extension of the
Idea of Bibliographic Coupling and Its Applications.” *Annals of Library
Science and Documentation* 30 (2).
<http://nopr.niscair.res.in/bitstream/123456789/28008/1/ALIS%2030(2)%2078-82.pdf>.

</div>

</div>

[1] Contact: <agoutsmedt@hotmail.fr>.

[2] If you want to build a coupling network with entities larger than a
document (meaning entities that have published several documents, and
thus can cite a reference several times), we rather recommend the use of
the `coupling_entity()` function. See the
`vignette("Using_biblionetwork")` for examples.
