# Package index

## Bibliographic Coupling

One general function,
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
to link documents that cite the same references, and one function per
weighting method.

- [`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md)
  : Bibliographic coupling edges, with the weighting method of your
  choice
- [`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md)
  : Bibliographic coupling edges, weighted by the coupling angle
- [`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md)
  : Bibliographic coupling edges, weighted by the coupling strength
- [`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md)
  : Bibliographic coupling edges, weighted by the idf-weighted cosine
  (SIM)
- [`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md)
  : Bibliographic coupling edges, weighted by the relative coupling
  strength (Jaccard)
- [`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md)
  : Bibliographic coupling edges, weighted by the Vladutz-Cook formula
- [`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md)
  : Bibliographic coupling edges using the titles of the references
  (DescriptiveBC)
- [`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)
  : Terms that describe why a document is related to another (DTerms)

## Comparing Coupling Measures

Compute several measures at once and compare the distributions, the
rankings and the gaps between the ranks of their weights.

- [`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md)
  : Compute several coupling (or co-citation) measures at once
- [`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md)
  : Put the weights of several measures side by side, with their ranks
- [`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md)
  : Summarise the distribution of the weights of each measure
- [`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md)
  : Correlate the weights of several measures
- [`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md)
  : Overlap between the strongest edges of several measures
- [`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md)
  : Plot the weights of several coupling measures

## Bibliographic Co-citation

Functions for building co-citation type networks.

- [`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md)
  : Co-citation edges, with the same weights as the coupling measures

## Networks of Entities

Not a new measure: the coupling (or co-citation) measures, aggregated at
the level of authors, journals, institutions…

- [`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md)
  : Aggregate a coupling or co-citation network at the level of entities

## Co-authorship Network

Functions for building co-authorship type networks.

- [`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md)
  : Co-authorship edges, with full or fractional counting

## Included Dataset

Data on stagflation explanation

- [`Authors_stagflation`](https://agoutsmedt.github.io/biblionetwork/reference/Authors_stagflation.md)
  : List of Authors of the Articles and Books Explaining the 1970s US
  Stagflation.
- [`Nodes_stagflation`](https://agoutsmedt.github.io/biblionetwork/reference/Nodes_stagflation.md)
  : Articles and Books Explaining the 1970s US Stagflation.
- [`Ref_stagflation`](https://agoutsmedt.github.io/biblionetwork/reference/Ref_stagflation.md)
  : Articles and Books Explaining the 1970s US Stagflation.
