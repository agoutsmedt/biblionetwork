#' biblionetwork: edges of bibliometric networks
#'
#' @description
#' Bibliometric networks are built from tables of links between two kinds of
#' items: documents and the references they cite, authors and the documents
#' they sign. `biblionetwork` turns such a table into the *edges* of a
#' one-mode network, whose nodes are one of the two kinds of items, with
#' several ways of weighting the ties. It returns plain tables (`data.table`),
#' ready to be turned into a graph with
#' [tidygraph](https://tidygraph.data-imaginist.com/index.html) or
#' [igraph](https://r.igraph.org/), and is the first step of the
#' [networkflow](https://agoutsmedt.github.io/networkflow/) pipeline, which
#' projects, clusters and draws the networks.
#'
#' @section Which function for which question?:
#' | Nodes | Tie | Function |
#' |---|---|---|
#' | citing documents | share references \insertCite{kessler1963}{biblionetwork} | [biblio_coupling()], by default the cosine of [coupling_angle()] \insertCite{sen1983}{biblionetwork} |
#' | citing documents | share *rare* references | [coupling_strength()], [coupling_similarity()] \insertCite{shen2019}{biblionetwork} |
#' | citing documents | other classic normalisations | [coupling_jaccard()] \insertCite{sen1983}{biblionetwork}, [coupling_vladutz()] \insertCite{vladutz1984}{biblionetwork} |
#' | citing documents | cite different but related references (similar titles) | [coupling_descriptive()] \insertCite{liu2017}{biblionetwork} |
#' | cited references | are cited together \insertCite{small1973}{biblionetwork} | [biblio_cocitation()] |
#' | authors, institutions, countries | co-sign documents | [coauth_network()] |
#' | entities (authors, journals...) | their documents cite the same references, or are cited together | [entity_network()]: not a new measure, the aggregation of the measures above at the level of entities |
#'
#' The measures of coupling do not give the same weights: [compute_couplings()]
#' computes several of them at once, and [summarise_weights()],
#' [correlate_weights()], [overlap_top_weights()] and [plot_weights()] compare
#' the distributions and the rankings of their weights.
#'
#' Coupling ties are fixed when documents are published, so they suit the
#' comparison of successive time windows; co-citation ties depend on later
#' citations and describe the reception of the cited documents. The
#' article [How to use biblionetwork](https://agoutsmedt.github.io/biblionetwork/articles/Using_biblionetwork.html) illustrates all the functions
#' on the data of the package (the literature explaining the US stagflation of
#' the 1970s, \insertCite{goutsmedt2021a}{biblionetwork}).
#'
#' @section Conventions shared by all the functions:
#' * the input is a table of links with the names of two columns; it is never
#'   modified;
#' * networks are undirected: each pair of nodes appears once, in the columns
#'   `Source` and `Target`; `from` and `to` are copies, because tidygraph
#'   modifies them;
#' * duplicated rows are counted once; rows with missing identifiers are
#'   dropped with a warning;
#' * if no pair of nodes is linked, a warning explains why (nothing shared, or
#'   a `weight_threshold` that is too high) and a table with zero rows and the
#'   usual columns is returned;
#' * all the measures are computed from the whole table: the weights depend on
#'   the corpus.
#'
#' @references
#' \insertAllCited{}
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom lifecycle deprecated
#' @import data.table
#' @import Rdpack
#' @importFrom methods as is
## usethis namespace: end
NULL
