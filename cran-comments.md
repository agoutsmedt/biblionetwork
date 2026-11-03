## Update

This is an update (0.1.0 -> 0.2.0). The main changes (see NEWS.md):

* `biblio_coupling()` is now a general function with a `method` argument; the former function is `coupling_angle()`.
* new weighting methods and functions (`coupling_jaccard()`, `coupling_vladutz()`, `coupling_descriptive()`), tools to compare them (`compute_couplings()` and friends) and `entity_network()` (`coupling_entity()` is deprecated).
* faster and lighter computation (sparse matrices), several bug fixes, a test suite, and vignettes written in Quarto.

## Test environments

* local Fedora Linux, R 4.6.1 (to be completed with win-builder and R-hub before submission)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes

* The vignettes are built with Quarto (`VignetteBuilder: quarto`).
* Tests that use the author's private Scopus and Web of Science databases are skipped on CRAN and wherever the databases are absent.
