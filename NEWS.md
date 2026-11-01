# biblionetwork 0.1.1.9000 (development)

## Bug fixes

* `coupling_similarity()` was wrong in two ways. The idf of every reference was computed from the first reference of the table only (`nb_doc` was a one-cell table, recycled with its first value), so that the weights were proportional to those of `coupling_strength()`. And the denominator was the product of the informational lengths instead of its square root, so that the measure was not the cosine of Shen et al. (2019, Eq. 8) that the documentation announced. It now computes `sum_shared idf / sqrt(S(A) S(B))`, a cosine bounded by 1, checked against the formula and the worked example of the paper. **The weights of the previous versions are wrong and are not comparable with the new ones.**
* `coupling_strength()` computed `N` (the number of documents) after removing the references cited once, forgetting the documents without any shared reference. `N` now counts all the citing documents, as documented: weights change slightly (about 2% on average on the stagflation data).
* `coupling_entity()` used a global `min()` instead of the element-wise `pmin()` for the number of times two entities cite a reference: the weights were wrong as soon as an entity cited several references several times.
* `biblio_cocitation(normalized_weight_only = FALSE, output_in_character = FALSE)` failed (wrong column name).
* `biblio_coupling()`, `biblio_cocitation()`, `coupling_strength()`, `coupling_similarity()`, `coupling_entity()` and `coauth_network()` failed with "only 0's may be mixed with negative subscripts" when no pair of nodes was linked; they now return a zero-row table with the usual columns, and a warning (class `biblionetwork_no_edges`) that says whether nothing is shared or the `weight_threshold` is too high (with the largest number of shared items found).
* `dt[unique(id_art)]` was a keyed join on the reference identifier, which counted wrongly the documents if a document identifier was also a reference identifier; replaced by `uniqueN()`.

## Speed and memory

* The coupling and co-citation functions now compute the pairs with sparse matrices (`Matrix`) instead of listing, for each reference, all the pairs of documents citing it. A pair sharing k references used to be stored k times, with its identifiers, before being counted; it is now stored once, as integers. On a sample of 30,000 Scopus documents (830,000 citations, 4.5 million edges), `biblio_coupling()` went from 12.9 s and 7.1 GB of memory to 4.3 s and 0.8 GB; computing the five measures with `compute_couplings()` takes 5.7 s and 1.0 GB. The results are unchanged (checked against the former implementation on the stagflation data and against slow reference implementations in the tests).
* `coupling_entity()` and `coauth_network()` use sparse matrices too (for the entity measures, `min(a, b)` is written as the number of levels reached by both entities, which turns the sum of minima into a cross-product). Coupling the 35 journals of a sample of 830,000 citations takes about 3 s and 0.8 GB.
* The lengths of bibliographies are now numeric: products of two large lengths (entities such as journals) used to overflow the integer range and give `NA` weights.

## New functions

* `coupling_jaccard()`: relative coupling strength of Sen and Gan (1983), a Jaccard index.
* `coupling_vladutz()`: the Vladutz and Cook (1984) formula, as reported by Shen et al. (2019).
* `compute_couplings()`: computes several coupling measures at once, sharing the costly pair-listing step.
* `biblio_cocitation()` has a `method` argument: the co-citation can be weighted with the angle (default, unchanged), the coupling strength, the idf similarity, the Jaccard index or the Vladutz-Cook formula, as the coupling. `compute_couplings()` has a `network` argument to compute them on co-citation.
* `coupling_entity()` has a third `method`, `"coupling_similarity"`: the idf cosine, with the minimum rule of Zhao and Strotmann (2008) for the counts.
* `coupling_descriptive()`: the DescriptiveBC measure of Liu (2017), which uses the words of the titles of the references to couple documents that cite different but related references; `descriptive_terms()` gives the words that say why two documents are related.
* `summarise_weights()`, `correlate_weights()`, `overlap_top_weights()`, `merge_weights()` and `plot_weights()`: compare the distributions and the rankings of the weights of different measures.

## Other changes

* The document-level coupling functions share one internal engine (`R/coupling_core.R`).
* The package now lists `aurelien.goutsmedt@ichec.be` as the only contact address.

* A new vignette, `comparing_measures`, compares all the measures on the stagflation corpus.
* New internal helpers (`R/utils.R`) shared by all the functions: the input is checked with informative `cli` errors (missing columns, wrong arguments), rows with missing identifiers are dropped with a warning, and the pairs are built in one place.
* `coauth_network()`: an unknown `method` is now an error instead of silently using the refined fractional counting.
* Documentation rewritten to explain the research use of each measure, the formalisation and the computing choices, with references to the literature; new package-level overview and a section in the vignette to choose a measure.
* First test suite (`testthat` 3): hand-computed toy examples, invariants, cross-checks with a slow implementation, and tests on samples of the authors' Scopus and Web of Science databases (skipped where the databases are absent).
* The package now depends on R >= 4.1.0 and imports `cli`, `rlang` and `Matrix`.

# biblionetwork 0.1.1

* Use of [lifecycle](https://lifecycle.r-lib.org/index.html) to manage the life cycle of the package
* Creation of a package-level documentation to add dependency in a centralized way
* Adding repository on [Zenodo](https://zenodo.org/record/7677369) and adding the DOI badge

# biblionetwork 0.1.0

* This is the first release of the biblionetwork package
