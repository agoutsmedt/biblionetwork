

<!-- README.md is generated from README.qmd. Please edit that file -->

# biblionetwork <img src="man/figures/logo.png" align="right" alt="" width="120" />

<!-- badges: start -->

[![CRAN
Status](https://www.r-pkg.org/badges/version-last-release/biblionetwork.png)](https://cran.r-project.org/package=biblionetwork)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7677369.svg)](https://doi.org/10.5281/zenodo.7677369)
[![downloads](https://cranlogs.r-pkg.org/badges/biblionetwork.png)](https://cran.r-project.org/package=biblionetwork)
[![downloads-total](https://cranlogs.r-pkg.org/badges/grand-total/biblionetwork.png)](https://cran.r-project.org/package=biblionetwork)
<!-- badges: end -->

## What does biblionetwork do?

`biblionetwork` turns a **table of links between two kinds of items**
(documents and the references they cite, authors and the documents they
sign) into the **edges of a network**, whose nodes are one of the two
kinds of items. You choose the type of network and the way the ties are
weighted, depending on what you want to analyse:

| Network | Nodes are linked when they… | Main function |
|----|----|----|
| bibliographic coupling | cite the same references ([Kessler 1963](#ref-kessler1963)) | `biblio_coupling()` |
| co-citation | are cited together ([Small 1973](#ref-small1973)) | `biblio_cocitation()` |
| coupling or co-citation of entities (authors, journals, institutions) | the documents of the entities cite the same references (or are cited together) ([Zhao and Strotmann 2008](#ref-zhao2008b)) | `entity_network()` |
| co-authorship | co-sign documents | `coauth_network()` |

The weight of a tie can be computed with several measures: the coupling
angle ([Sen and Gan 1983](#ref-sen1983)), the coupling strength and the
idf-weighted similarity ([Shen et al. 2019](#ref-shen2019)), the Jaccard
index, the Vladutz-Cook formula, or full and fractional counting for
co-authorship ([Perianes-Rodriguez, Waltman, and Van Eck
2016](#ref-perianes-rodriguez2016b); [Leydesdorff and Park
2017-02](#ref-leydesdorff2017)). `compute_couplings()` computes several
of them at once, and a few functions compare their distributions and
rankings (`merge_weights()` ranks the pairs and measures the rank gap
between two measures) on your own corpus.

The package returns plain tables (`data.table`), ready to be turned into
a graph with [`tidygraph`](https://tidygraph.data-imaginist.com/) or
[`igraph`](https://r.igraph.org/). It is written for **very large
corpora**: the pairs of nodes are computed with sparse matrices, which
keeps time and memory low. Nothing is specific to bibliography, though:
any two-mode table (accounts and the accounts they follow, posts and
their words…) can be projected the same way (see the vignette). To go
further, [`networkflow`](https://agoutsmedt.github.io/networkflow/)
builds on `biblionetwork` to cluster, follow and draw networks over
time, and the [`backbone`](https://github.com/zpneal/backbone) package
([Neal 2026](#ref-neal2026)) can filter the ties that are not
statistically significant.

The original function, which uses `data.table` ([Dowle and Srinivasan
2020](#ref-datatable)) and allows the user to find edges and calculate
weights for large networks, was developed by [François
Claveau](https://www.usherbrooke.ca/recherche/fr/specialistes/details/francois.claveau).
The different functions in this package have been developed, from
Claveau’s original idea, by [Alexandre
Truc](https://sites.google.com/view/alexandre-truc/home-and-contact) and
[Aurélien Goutsmedt](https://aurelien-goutsmedt.com/). The package is
maintained by Aurélien Goutsmedt.[^1]

## Installation

You can install the release version from CRAN:

``` r
install.packages("biblionetwork")
```

or the development version from
[GitHub](https://github.com/agoutsmedt/biblionetwork):

``` r
# install.packages("devtools")
devtools::install_github("agoutsmedt/biblionetwork")
```

You can cite this package as:

``` r
citation("biblionetwork")
```

## Example

All you need is a table with entities (documents, authors, universities,
*etc.*) citing references. `biblio_coupling()` calculates the number of
references that different articles share together, and a weight for each
pair of articles in a bibliographic coupling network. By default, the
weight is the coupling angle ([Sen and Gan 1983](#ref-sen1983)); the
`method` argument selects another measure (`"strength"`, `"similarity"`,
`"jaccard"`, `"vladutz"`).[^2] See the [vignette “How to use
biblionetwork”](https://agoutsmedt.github.io/biblionetwork/articles/Using_biblionetwork.html)
for a more in-depth presentation of the package.

This example uses the [data included](#included-data) in the package.

``` r
library(biblionetwork)

biblio_coupling(Ref_stagflation,
                source = "Citing_ItemID_Ref",
                ref = "ItemID_Ref",
                normalized_weight_only = FALSE,
                weight_threshold = 1)
```

    #>             from         to     weight nb_shared_references     Source
    #>           <char>     <char>      <num>                <int>      <int>
    #>    1:    1021902    1184127 0.04622502                    1    1021902
    #>    2:     214927    2207578 0.14605935                    4     214927
    #>    3:    1184127    2901822 0.04233338                    1    1184127
    #>    4:    1184130    2901822 0.05184758                    1    1184130
    #>    5:    1717556    2901822 0.02804964                    1    1717556
    #>   ---                                                                 
    #> 2712: 1111111122 1111111183 0.05572782                    1 1111111122
    #> 2713: 1111111134 1111111183 0.04256283                    1 1111111134
    #> 2714: 1111111146 1111111183 0.05212860                    1 1111111146
    #> 2715: 1111111161 1111111183 0.04050542                    2 1111111161
    #> 2716: 1111111182 1111111183 0.27060404                    8 1111111182
    #>           Target
    #>            <int>
    #>    1:    1184127
    #>    2:    2207578
    #>    3:    2901822
    #>    4:    2901822
    #>    5:    2901822
    #>   ---           
    #> 2712: 1111111183
    #> 2713: 1111111183
    #> 2714: 1111111183
    #> 2715: 1111111183
    #> 2716: 1111111183

The same pairs of articles, weighted so that sharing a rare reference
counts more than sharing a classic ([Shen et al. 2019](#ref-shen2019)):

``` r
biblio_coupling(Ref_stagflation,
                source = "Citing_ItemID_Ref",
                ref = "ItemID_Ref",
                method = "strength",
                weight_threshold = 3)
```

    #>            from         to      weight     Source     Target
    #>          <char>     <char>       <num>      <int>      <int>
    #>   1:     214927    2207578 0.020008623     214927    2207578
    #>   2:    5160307    6714008 0.010611749    5160307    6714008
    #>   3:    1717556    7815498 0.035262345    1717556    7815498
    #>   4:     214927    8456979 0.011939901     214927    8456979
    #>   5:    2207578    8456979 0.012807897    2207578    8456979
    #>  ---                                                        
    #> 958:   39858452 1111111180 0.005118578   39858452 1111111180
    #> 959:  151268764 1111111180 0.007465000  151268764 1111111180
    #> 960:    1021902 1111111183 0.006925280    1021902 1111111183
    #> 961:  106566092 1111111183 0.002896722  106566092 1111111183
    #> 962: 1111111182 1111111183 0.038292193 1111111182 1111111183

## Included data

The `biblionetwork` package contains bibliometric data built by
Goutsmedt ([2021](#ref-goutsmedt2021a)). These data gather the academic
articles and books, published between 1975 and 2013, that endeavoured to
explain the United States stagflation of the 1970s. They also gather all
the references cited by these articles and books on stagflation. The
`Nodes_stagflation.rda` file contains information about the academic
articles and books on stagflation (the stagflation documents), as well
as about the references cited at least by two of these stagflation
documents. The `Ref_stagflation.rda` is a data frame of direct
citations, with the identifiers of citing documents, and the identifiers
of cited documents. The `Authors_stagflation.rda` is a data frame with
the list of documents explaining the US stagflation, and all the authors
of these documents (`Nodes_stagflation.rda` just takes the first author
for each document).

## References

<div id="refs" class="references csl-bib-body hanging-indent"
data-entry-spacing="0">

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

<div id="ref-kessler1963" class="csl-entry">

Kessler, M. M. 1963. “Bibliographic Coupling Between Scientific Papers.”
*American Documentation* 14 (1): 10–25.
<https://doi.org/10.1002/asi.5090140103>.

</div>

<div id="ref-leydesdorff2017" class="csl-entry">

Leydesdorff, Loet, and Han Woo Park. 2017-02. “Full and Fractional
Counting in Bibliometric Networks.” *Journal of Informetrics* 11 (1):
117–20.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716303133>.

</div>

<div id="ref-neal2026" class="csl-entry">

Neal, Zachary P. 2026. “Backbone 3.0: An R Package for Extracting
Network Backbones.” *PLOS ONE* 21 (5): e0349258.
<https://doi.org/10.1371/journal.pone.0349258>.

</div>

<div id="ref-perianes-rodriguez2016b" class="csl-entry">

Perianes-Rodriguez, Antonio, Ludo Waltman, and Nees Jan Van Eck. 2016.
“Constructing Bibliometric Networks: A Comparison Between Full and
Fractional Counting.” *Journal of Informetrics* 10 (4): 1178–95.
<https://www.sciencedirect.com/science/article/pii/S1751157716302036?casa_token=AtzjmZ-1QmYAAAAA:2mlBPZsjGUleYi9mnybHODFw2RmMh3GHvRAuMYXygRm63cQOv07M4ixbAmJXuGq71tx2ug29baTp>.

</div>

<div id="ref-sen1983" class="csl-entry">

Sen, Subir K., and Shymal K. Gan. 1983. “A Mathematical Extension of the
Idea of Bibliographic Coupling and Its Applications.” *Annals of Library
Science and Documentation* 30 (2).

</div>

<div id="ref-shen2019" class="csl-entry">

Shen, Si, Danhao Zhu, Ronald Rousseau, Xinning Su, and Dongbo Wang.
2019. “A Refined Method for Computing Bibliographic Coupling Strengths.”
*Journal of Informetrics* 13 (2): 605–15.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.

</div>

<div id="ref-small1973" class="csl-entry">

Small, Henry. 1973. “Co-Citation in the Scientific Literature: A New
Measure of the Relationship Between Two Documents.” *Journal of the
American Society for Information Science* 24 (4): 265–69.
<https://doi.org/10.1002/asi.4630240406>.

</div>

<div id="ref-zhao2008b" class="csl-entry">

Zhao, Dangzhi, and Andreas Strotmann. 2008. “Author Bibliographic
Coupling: Another Approach to Citation-Based Author Knowledge Network
Analysis.” *Proceedings of the American Society for Information Science
and Technology* 45 (1): 1–10.
<https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/meet.2008.1450450292>.

</div>

</div>

[^1]: Contact: <aurelien.goutsmedt@ichec.be>.

[^2]: If you want to build a coupling network with entities larger than
    a document (meaning entities that have published several documents,
    and thus can cite a reference several times), we rather recommend
    the use of the `entity_network()` function.
