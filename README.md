
-   [biblionetwork](#biblionetwork)
    -   [Installation](#installation)
    -   [Uses of the package](#uses-of-the-package)
        -   [The basic coupling angle (or cosine)
            function](#the-basic-coupling-angle-or-cosine-function)
        -   [Testing another method: the `coupling_strength()`
            function](#testing-another-method-the-coupling_strength-function)
        -   [Aggregating at the “entity”
            level](#aggregating-at-the-entity-level)
        -   [A different world: building co-authorship
            network](#a-different-world-building-co-authorship-network)
    -   [Incorporated data](#incorporated-data)
    -   [References](#references)

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

The original function which uses data.table and allows the user to find
edges and calculate weights for very large networks was developed by
[François
Claveau](https://www.usherbrooke.ca/philosophie/nous-joindre/personnel-enseignant/claveau-francois/).
The different functions in this package have been developed, from
Claveau’s original idea, by [Alexandre
Truc](https://sites.google.com/view/alexandre-truc/home-and-contact) and
[Aurélien Goutsmedt](https://agoutsmedt.wordpress.com/). The package is
maintained by Aurélien Goutsmedt and Alexandre Truc.[1]

You can cite this package as: Claveau, François, Aurélien Goutsmedt, and
Alexandre Truc.(2021). biblionetwork: A Package For Creating Different
Types of Bibliometric Networks. R package version 0.0.0.9000.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("agoutsmedt/biblionetwork")
```

## Uses of the package

Let’s use the different functions of the package with the data
integrated in the package.

### The basic coupling angle (or cosine) function

It uses the `biblio_coupling()` function which is the most general
function of the package. This function calculates the number of
references that different articles share together, as well as the
coupling angle value of edges in a bibliographic coupling network [Sen
and Gan](#ref-sen1983) ([1983](#ref-sen1983)), from a direct citation
data frame. This is a standard way to build bibliographic coupling
network using Salton’s cosine measure: it divides the number of
references that two articles share by the rootsquare of the product of
both articles bibliography lengths. It avoids giving too much importance
to articles with a large bibliography. It looks like:[2]

$$ 
\\frac{R(A) \\bullet R(B)}{\\sqrt{L(A).L(B)}} 
$$

with *R*(*A*) and *R*(*B*) the references of document A and document B,
*R*(*A*) • *R*(*B*) being the number of shared references by A and B,
and *L*(*A*) and *L*(*B*) the length of the bibliographies of document A
and document B.

The output is an edges data frame linking nodes together (see the `from`
and `to` columns) with a weight for each edge being the coupling angle
measure. If `normalized_weight_only` is set to be `FALSE`, another
column displays the number of references shared by the two nodes.

This example use the [`Ref_stagflation.rda`](#incorporated-data) file.

``` r
library(biblionetwork)

biblio_coupling(Ref_stagflation, source = "Citing_ItemID_Ref", ref = "ItemID_Ref", normalized_weight_only = FALSE, weight_threshold = 1)
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

This function is a relatively general function that can also be used:

1.  for co-citation, just by inverting the `source`and `ref` columns;
2.  for title co-occurence networks (taking care of the lenght of the
    title thanks to the coupling angle measure);
3.  for co-authorship networks (taking care of the number of co-authors
    an author has collaborated with on a period)

The function just keeps the edges that have a non-normalized weight
superior to the `weight_threshold`. In a large bibliographic coupling
network, you can consider for instance that sharing only one reference
is not sufficient/significant for two articles to be linked together.
This parameter could also be modified to avoid creating untractable
networks with too many edges.

``` r
library(biblionetwork)

biblio_coupling(Ref_stagflation, source = "Citing_ItemID_Ref", ref = "ItemID_Ref", weight_threshold = 3)
#>            from         to     weight     Source     Target
#>   1:     214927    2207578 0.14605935     214927    2207578
#>   2:     214927    8456979 0.09733285     214927    8456979
#>   3:     214927   10729971 0.29848100     214927   10729971
#>   4:     214927   19627977 0.11202241     214927   19627977
#>   5:    1021902   12824456 0.06537205    1021902   12824456
#>  ---                                                       
#> 958: 1111111147 1111111156 0.17325923 1111111147 1111111156
#> 959: 1111111147 1111111161 0.13333938 1111111147 1111111161
#> 960: 1111111156 1111111161 0.08580846 1111111156 1111111161
#> 961: 1111111159 1111111171 0.24333213 1111111159 1111111171
#> 962: 1111111182 1111111183 0.27060404 1111111182 1111111183
```

### Testing another method: the `coupling_strength()` function

This function calculates the coupling strength measure [Shen et
al.](#ref-shen2019) ([2019](#ref-shen2019)) from a direct citation data
frame. It is a refinement of `biblio_coupling()`: it takes into account
the frequency with which a reference shared by two articles has been
cited in the whole corpus. In other words, the most cited references are
less important in the links between two articles, than references that
have been rarely cited. To a certain extent, it is similar to the TF-IDF
measure. It looks like:

$$ 
\\frac{1}{L(A)}.\\frac{1}{L(A)}\\sum\_{j}(log({\\frac{N}{freq(R\_{j})}}))
$$

with *N* the number of articles in the whole dataset and
*f**r**e**q*(*R*<sub>*j*</sub>) the number of time the reference j
(which is shared by documents A and B) is cited in the whole corpus.

``` r
library(biblionetwork)

coupling_strength(Ref_stagflation, source = "Citing_ItemID_Ref", ref = "ItemID_Ref", weight_threshold = 1)
#>             from         to      weight     Source     Target
#>    1:     214927    2207578 0.019691698     214927    2207578
#>    2:     214927    5982867 0.005331122     214927    5982867
#>    3:     214927    8456979 0.011752248     214927    8456979
#>    4:     214927   10729971 0.046511251     214927   10729971
#>    5:     214927   16008556 0.008648490     214927   16008556
#>   ---                                                        
#> 2712: 1111111161 1111111172 0.005067554 1111111161 1111111172
#> 2713: 1111111161 1111111180 0.001168603 1111111161 1111111180
#> 2714: 1111111161 1111111183 0.002580798 1111111161 1111111183
#> 2715: 1111111172 1111111180 0.003870999 1111111172 1111111180
#> 2716: 1111111182 1111111183 0.037748271 1111111182 1111111183
```

### Aggregating at the “entity” level

Rather than focusing on documents, you can want to study the
relationships between authors, institutions/affiliations or journals.
The `coupling_entity()` function allows you to do that. Coupling links
are calculated using the coupling angle measure or the coupling strength
measure. Coupling links are calculated depending of the number
references two authors share, taking into account the minimum number of
times two authors are citing each references. For instance, if two
entities share a reference in common, the first one citing it twice (in
other words, citing it in two different articles), the second one three
times, the function takes two as the minimum value. In addition to the
features of the [coupling strength
measure](#testing-another-method-the-coupling_strength-function) or the
[coupling angle measure](#the-basic-coupling-angle-or-cosine-function),
it means that, if two entities share two reference in common, the fact
that the first reference is cited at least four times by the two
entities, whereas the second reference is cited at least only once, the
first reference contributes more to the edge weight than the second
reference. This use of minimum shared reference for entities coupling
comes from [Zhao and Strotmann](#ref-zhao2008b)
([2008](#ref-zhao2008b)). It looks like:

$$ 
\\frac{1}{L(A)}.\\frac{1}{L(A)}\\sum\_{j} Min(C\_{Aj},C\_{Bj}).(log({\\frac{N}{freq(R\_{j})}}))
$$

with *C*<sub>*A**j*</sub> and *C*<sub>*B**j*</sub> the number of time
documents A and B cite the reference *j*.

This example use the [`Ref_stagflation.rda`](#incorporated-data) and the
[`Nodes_stagflation.rda`](#incorporated-data) files.

``` r
library(biblionetwork)

# merging the references data with the citing author information in Nodes_stagflation
entity_citations <- merge(Ref_stagflation, Nodes_stagflation, by.x = "Citing_ItemID_Ref", by.y = "ItemID_Ref")

coupling_entity(entity_citations, source = "Citing_ItemID_Ref", ref = "ItemID_Ref", entity = "Author.y", method = "coupling_angle")
#>             from          to     weight     Source      Target Weighting_method
#>    1: ALBANESI-S      BALL-L 0.02429648 ALBANESI-S      BALL-L   coupling_angle
#>    2: ALBANESI-S ROTEMBERG-J 0.03045725 ALBANESI-S ROTEMBERG-J   coupling_angle
#>    3: ALBANESI-S    BARSKY-R 0.02100729 ALBANESI-S    BARSKY-R   coupling_angle
#>    4: ALBANESI-S     BEYER-A 0.03458572 ALBANESI-S     BEYER-A   coupling_angle
#>    5: ALBANESI-S  CHAPPELL-H 0.04264014 ALBANESI-S  CHAPPELL-H   coupling_angle
#>   ---                                                                          
#> 1456:    VELDE-F     YOUNG-W 0.01601282    VELDE-F     YOUNG-W   coupling_angle
#> 1457:    VELDE-F     WEISE-C 0.02282177    VELDE-F     WEISE-C   coupling_angle
#> 1458:    VELDE-F   WACHTER-M 0.01883109    VELDE-F   WACHTER-M   coupling_angle
#> 1459:    VELDE-F WEINTRAUB-S 0.12909944    VELDE-F WEINTRAUB-S   coupling_angle
#> 1460:  WACHTER-M WEINTRAUB-S 0.14586499  WACHTER-M WEINTRAUB-S   coupling_angle
```

### A different world: building co-authorship network

Even if co-authorship links weights can be calculated using the
[`biblio_coupling`](#the-basic-coupling-angle-or-cosine-function)
function with authors as `source` and articles as `ref`, the method used
is not necessarily the most appropriate for co-authorship networks. The
`coauth_network` function implements different types of methods for
calculating the weights linking different authors:[3]

1.  a “full counting” method;
2.  a “fractional counting” method (see [Perianes-Rodriguez, Waltman,
    and Van Eck 2016](#ref-perianes-rodriguez2016b) for an interesting
    comparison between full counting and fractional counting results);
3.  a “fractional counting refined” method, inspired by [Leydesdorff and
    Park](#ref-leydesdorff2017) ([2017-02](#ref-leydesdorff2017)).

In addition, it is possible to take into account the total number of
collaborations of two linked authors, by fixing `cosine_normalized` to
`True`.

This example use the [`Authors_stagflation.rda`](#incorporated-data)
file.

``` r
library(biblionetwork)

full_counting <- coauth_network(Authors_stagflation, authors = "Author", articles = "ItemID_Ref", method = "full_counting")
head(full_counting[order(Source)],10)
#>              from           to weight        Source       Target
#>  1:       CHARI-V   ALBANESI-S      1       CHARI-V   ALBANESI-S
#>  2:  CHRISTIANO-L      CHARI-V      2  CHRISTIANO-L      CHARI-V
#>  3:  CHRISTIANO-L   ALBANESI-S      1  CHRISTIANO-L   ALBANESI-S
#>  4:   CUKIERMAN-A    BRUNNER-K      1   CUKIERMAN-A    BRUNNER-K
#>  5:  EICHENBAUM-M      CHARI-V      1  EICHENBAUM-M      CHARI-V
#>  6:  EICHENBAUM-M CHRISTIANO-L      1  EICHENBAUM-M CHRISTIANO-L
#>  7: EICHENGREEN-B      BORDO-M      1 EICHENGREEN-B      BORDO-M
#>  8:      EUSEPI-S    BULLARD-J      1      EUSEPI-S    BULLARD-J
#>  9:      FARMER-R      BEYER-A      1      FARMER-R      BEYER-A
#> 10:  FITZGERALD-T CHRISTIANO-L      1  FITZGERALD-T CHRISTIANO-L

fractional_counting <- coauth_network(Authors_stagflation, authors = "Author", articles = "ItemID_Ref", method = "fractional_counting")
head(fractional_counting[order(Source)],10)
#>              from           to weight        Source       Target
#>  1:       CHARI-V   ALBANESI-S    0.5       CHARI-V   ALBANESI-S
#>  2:  CHRISTIANO-L      CHARI-V    1.0  CHRISTIANO-L      CHARI-V
#>  3:  CHRISTIANO-L   ALBANESI-S    0.5  CHRISTIANO-L   ALBANESI-S
#>  4:   CUKIERMAN-A    BRUNNER-K    0.5   CUKIERMAN-A    BRUNNER-K
#>  5:  EICHENBAUM-M      CHARI-V    0.5  EICHENBAUM-M      CHARI-V
#>  6:  EICHENBAUM-M CHRISTIANO-L    0.5  EICHENBAUM-M CHRISTIANO-L
#>  7: EICHENGREEN-B      BORDO-M    1.0 EICHENGREEN-B      BORDO-M
#>  8:      EUSEPI-S    BULLARD-J    1.0      EUSEPI-S    BULLARD-J
#>  9:      FARMER-R      BEYER-A    1.0      FARMER-R      BEYER-A
#> 10:  FITZGERALD-T CHRISTIANO-L    1.0  FITZGERALD-T CHRISTIANO-L

fractional_counting_cosine <- coauth_network(Authors_stagflation, authors = "Author", articles = "ItemID_Ref", method = "fractional_counting", cosine_normalized = TRUE)
head(fractional_counting_cosine[order(Source)],10)
#>              from           to    weight        Source       Target
#>  1:       CHARI-V   ALBANESI-S 0.3535534       CHARI-V   ALBANESI-S
#>  2:  CHRISTIANO-L   ALBANESI-S 0.2500000  CHRISTIANO-L   ALBANESI-S
#>  3:  CHRISTIANO-L      CHARI-V 0.3535534  CHRISTIANO-L      CHARI-V
#>  4:   CUKIERMAN-A    BRUNNER-K 0.3535534   CUKIERMAN-A    BRUNNER-K
#>  5:  EICHENBAUM-M      CHARI-V 0.3535534  EICHENBAUM-M      CHARI-V
#>  6:  EICHENBAUM-M CHRISTIANO-L 0.2500000  EICHENBAUM-M CHRISTIANO-L
#>  7: EICHENGREEN-B      BORDO-M 1.0000000 EICHENGREEN-B      BORDO-M
#>  8:      EUSEPI-S    BULLARD-J 1.0000000      EUSEPI-S    BULLARD-J
#>  9:      FARMER-R      BEYER-A 1.0000000      FARMER-R      BEYER-A
#> 10:  FITZGERALD-T CHRISTIANO-L 0.5000000  FITZGERALD-T CHRISTIANO-L
```

## Incorporated data

The biblionetwork package contains bibliometric data built by
[Goutsmedt](#ref-goutsmedt2021a) ([2021](#ref-goutsmedt2021a)). These
data gather the academic articles and books that endeavoured to explain
the United States stagflation of the 1970s, published between 1975 and
2013. They also gather all the references cited by these articles and
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

<div id="ref-goutsmedt2021a" class="csl-entry">

Goutsmedt, Aurélien. 2021. “From the Stagflation to the Great Inflation:
Explaining the US Economy of the 1970s.” *Revue d’Economie Politique*
Forthcoming.
<https://mega.nz/file/zfJ2QBbb#3OqXBIQRYmuQzptMyfvwW92IXhN-pWApKpILSs_w-pg>.

</div>

<div id="ref-leydesdorff2017" class="csl-entry">

Leydesdorff, Loet, and Han Woo Park. 2017-02. “Full and Fractional
Counting in Bibliometric Networks.” *Journal of Informetrics* 11 (1):
117–20.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716303133>.

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
<http://nopr.niscair.res.in/bitstream/123456789/28008/1/ALIS>.

</div>

<div id="ref-shen2019" class="csl-entry">

Shen, Si, Danhao Zhu, Ronald Rousseau, Xinning Su, and Dongbo Wang.
2019. “A Refined Method for Computing Bibliographic Coupling Strengths.”
*Journal of Informetrics* 13 (2): 605–15.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.

</div>

<div id="ref-vladutz1984" class="csl-entry">

Vladutz, George, and James Cook. 1984. “Bibliographic Coupling and
Subject Relatedness.” *Proceedings of the American Society for
Information Science* 21: 204–7.

</div>

<div id="ref-zhao2008b" class="csl-entry">

Zhao, Dangzhi, and Andreas Strotmann. 2008. “Author Bibliographic
Coupling: Another Approach to Citation-Based Author Knowledge Network
Analysis.” *Proceedings of the American Society for Information Science
and Technology* 45 (1): 1–10.
<https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/meet.2008.1450450292>.

</div>

</div>

[1] Contact: [agoutsmedt@hotmail.fr](agoutsmedt@hotmail.fr).

[2] Github\_document does not render properly math equations and I have
decided to let them in a format that would allow proper computation in
.html or .pdf documents.

[3] I take as example authors here, but the function could also be used
for calculating a co-authorship network with institutions or countries
as nodes.
