# biblionetwork: edges of bibliometric networks

Bibliometric networks are built from tables of links between two kinds
of items: documents and the references they cite, authors and the
documents they sign. `biblionetwork` turns such a table into the *edges*
of a one-mode network, whose nodes are one of the two kinds of items,
with several ways of weighting the ties. It returns plain tables
(`data.table`), ready to be turned into a graph with
[tidygraph](https://tidygraph.data-imaginist.com/index.html) or
[igraph](https://r.igraph.org/), and is the first step of the
[networkflow](https://agoutsmedt.github.io/networkflow/) pipeline, which
projects, clusters and draws the networks.

## Which function for which question?

|  |  |  |
|----|----|----|
| Nodes | Tie | Function |
| citing documents | share references (Kessler 1963) | [`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md), by default the cosine of [`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md) (Sen and Gan 1983) |
| citing documents | share *rare* references | [`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md), [`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md) (Shen et al. 2019) |
| citing documents | other classic normalisations | [`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md) (Sen and Gan 1983) , [`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md) (Vladutz and Cook 1984) |
| citing documents | cite different but related references (similar titles) | [`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md) (Liu 2017) |
| cited references | are cited together (Small 1973) | [`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md) |
| authors, institutions, countries | co-sign documents | [`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md) |
| entities (authors, journals...) | their documents cite the same references, or are cited together | [`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md): not a new measure, the aggregation of the measures above at the level of entities |

The measures of coupling do not give the same weights:
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md)
computes several of them at once, and
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md),
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md)
and
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md)
compare the distributions and the rankings of their weights.

Coupling ties are fixed when documents are published, so they suit the
comparison of successive time windows; co-citation ties depend on later
citations and describe the reception of the cited documents. The article
[How to use
biblionetwork](https://agoutsmedt.github.io/biblionetwork/articles/Using_biblionetwork.html)
illustrates all the functions on the data of the package (the literature
explaining the US stagflation of the 1970s, (Goutsmedt 2021) ).

## Conventions shared by all the functions

- the input is a table of links with the names of two columns; it is
  never modified;

- networks are undirected: each pair of nodes appears once, in the
  columns `Source` and `Target`; `from` and `to` are copies, because
  tidygraph modifies them;

- duplicated rows are counted once; rows with missing identifiers are
  dropped with a warning;

- if no pair of nodes is linked, a warning explains why (nothing shared,
  or a `weight_threshold` that is too high) and a table with zero rows
  and the usual columns is returned;

- all the measures are computed from the whole table: the weights depend
  on the corpus.

## References

Goutsmedt A (2021). “From the Stagflation to the Great Inflation:
Explaining the US Economy of the 1970s.” *Revue d'Economie Politique*,
**Forthcoming**.
<https://aurelien-goutsmedt.com/media/pdf/stagflation-great-inflation.pdf>.  
  
Kessler MM (1963). “Bibliographic Coupling between Scientific Papers.”
*American Documentation*, **14**(1), 10–25.
[doi:10.1002/asi.5090140103](https://doi.org/10.1002/asi.5090140103) .  
  
Liu R (2017). “A New Bibliographic Coupling Measure with Descriptive
Capability.” *Scientometrics*, **110**(2), 915–935.
[doi:10.1007/s11192-016-2196-7](https://doi.org/10.1007/s11192-016-2196-7)
.  
  
Sen SK, Gan SK (1983). “A Mathematical Extension of the Idea of
Bibliographic Coupling and Its Applications.” *Annals of library science
and documentation*, **30**(2).  
  
Shen S, Zhu D, Rousseau R, Su X, Wang D (2019). “A Refined Method for
Computing Bibliographic Coupling Strengths.” *Journal of Informetrics*,
**13**(2), 605–615.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.  
  
Small H (1973). “Co-Citation in the Scientific Literature: A New Measure
of the Relationship between Two Documents.” *Journal of the American
Society for Information Science*, **24**(4), 265–269.
[doi:10.1002/asi.4630240406](https://doi.org/10.1002/asi.4630240406) .  
  
Vladutz G, Cook J (1984). “Bibliographic Coupling and Subject
Relatedness.” *Proceedings of the American Society for Information
Science*, **21**, 204–207.

## See also

Useful links:

- <https://github.com/agoutsmedt/biblionetwork>

- <https://agoutsmedt.github.io/biblionetwork/>

- Report bugs at <https://github.com/agoutsmedt/biblionetwork/issues>

## Author

**Maintainer**: Aurélien Goutsmedt <agoutsmedt@hotmail.fr>
([ORCID](https://orcid.org/0000-0002-3788-7237))

Authors:

- Aurélien Goutsmedt <agoutsmedt@hotmail.fr>
  ([ORCID](https://orcid.org/0000-0002-3788-7237))

- François Claveau ([ORCID](https://orcid.org/0000-0001-7129-7794))

- Alexandre Truc ([ORCID](https://orcid.org/0000-0002-1328-7819))
