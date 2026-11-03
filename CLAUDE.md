# CLAUDE.md

R package `biblionetwork` (0.2.0; authors Goutsmedt, Claveau, Truc; MIT; GitHub `agoutsmedt/biblionetwork`, pkgdown site; submitted to CRAN: see `cran-comments.md`, `CRAN-RELEASE`) that computes the edges of bibliometric networks (`biblio_coupling` (general, `method =`), `coupling_angle` (the former `biblio_coupling`), `biblio_cocitation`, `coauth_network`, `coupling_strength`, `coupling_similarity`, `entity_network`, formerly `coupling_entity`, now deprecated) with several weighting methods, optimised with `data.table`. `networkflow` imports it, and `socio_atproto` compares its own sparse-matrix implementation (`coupling_strength_edges()`) against `biblionetwork::coupling_strength()`: that project found the package version **explodes in memory on very popular targets** (a reference cited by many documents creates a huge number of pairs). Keep that in mind when testing and changing performance.

Install with `R CMD INSTALL ~/git_projects/biblionetwork`.

## Commands

```r
devtools::document()        # regenerate man/ and NAMESPACE from roxygen
devtools::load_all()        # iterate without installing
devtools::check()           # R CMD check (no tests/ yet)
devtools::test()            # once tests/ exists
devtools::test(filter = "coupling_strength")   # a single test file
pkgdown::build_site()       # site in docs/ (config: _pkgdown.yml)
quarto::quarto_render("README.qmd")           # README.md is generated
```

## Architecture

One exported function per file in `R/`, plus `R/utils.R` and `R/coupling_core.R` (internal helpers shared by all of them: `prepare_links()`, `coupling_core()`, `sparse_product()`, `finalise_edges()`, `check_*()`). Each function follows the same pipeline, so a fix to one usually applies to the others:

1. `prepare_links()`: validates arguments (cli errors), works on a copy (the input is never modified), renames the two columns to `id_art`/`id_ref`, drops NA rows (warning), duplicates and self-citations, keys on `(id_ref, id_art)`.
2. Keep only references cited more than once (for co-citation: documents citing more than once), then `coupling_core()` computes, with sparse matrix cross-products, the number of shared references and the weighted sums of every pair of documents sharing one (zero-row table and warning if none).
3. Count shared references per pair, apply `weight_threshold`, normalise (cosine `N / sqrt(L_A L_B)`, or the strength/similarity variants).
4. `finalise_edges()`: `Source`/`Target`/`weight` (+ extra columns), or `from`/`to` (character if `output_in_character`) as copies. Orientation is `Source < Target`, except `coauth_network()` (`Source > Target`, kept from earlier versions).

Package-level imports (`@import data.table`, `Rdpack`, `lifecycle`) live in `R/biblionetwork-package.R`, not in each function. The `*_stagflation.R` files in `R/` only document the datasets in `data/`. Non-standard-evaluation column names are declared as `NULL` at the top of each function to silence `R CMD check` notes (add new ones there; the helpers in `utils.R` do the same). Articles and README are Quarto (`vignettes/articles/*.qmd`, shown on the site only, not built by R CMD; `README.qmd` -> `README.md`; set `QUARTO_PATH` to a quarto binary, e.g. `~/quarto-1.10.18-linux-amd64/quarto-1.10.18/bin/quarto`, to build them). The site theme is in `pkgdown/extra.scss`. `docs/`, `revdep/`, `data-raw/` are excluded from the build via `.Rbuildignore`; `.travis.yml` is obsolete (no GitHub Actions workflow).

## State (2026-11-03, version 0.2.0)

Fixed in this development version (details in `NEWS.md`): `coupling_similarity()`
(idf bug, `nb_doc` a 1x1 table recycled with its first value, **and** wrong
denominator: it is now the cosine of Shen et al. 2019, Eq. 8,
`sum_shared idf / sqrt(S(A) S(B))`, checked on the paper's worked example),
`N` in `coupling_strength()` (now all citing documents), `min()` -> `pmin()` in
`coupling_entity()`, the column name in `biblio_cocitation()`, the crash on empty
pair tables (now a zero-row table **and** a `biblionetwork_no_edges` warning
saying why), and `dt[unique(id_art)]` -> `uniqueN()`.

Added: `coupling_jaccard()`, `coupling_vladutz()` (Eqs. 1 and 6 of Shen et al.)
and the comparison tools in `R/compare_weights.R` (`compute_couplings()`,
`summarise_weights()`, `correlate_weights()`, `overlap_top_weights()`,
`merge_weights()`, `plot_weights()`). All the document-level coupling
functions go through `coupling_core()` (`R/coupling_core.R`): add a new measure
as a formula on its columns, and to `compute_couplings()`.

Open points:

- **networkflow documents the old `coupling_similarity()`** (`R/build_dynamic_networks.R`
  details: "S_i proportional to L_i", scale of the weights, CPM advice): update it.
- Speed/memory: `coupling_core()` uses sparse matrices (`Matrix::tcrossprod`); the
  quantities of the measures are the products B diag(w) t(B). `entity_network()` (the `min` rule becomes a sum over
  levels k reached by both entities) and `coauth_network()` use `sparse_product()`
  too. Benchmarks in `NEWS.md`.
- Table 4 of Shen et al. has an apparent typo (cell VII-II, 0.201 instead of
  0.502): it is excluded in `test-shen2019.R`.
- `coupling_descriptive()` (Liu 2017) is a per-target loop, cost ~ n_documents^2: use `targets`.
- Not implemented: the idf variant of Eq. 3 of Shen et al. (`log(N / (1 + f))`),
  a hypergeometric significance measure of coupling.
- `cran-comments.md`, `CRAN-RELEASE`, `.travis.yml` are obsolete (2021).

## Skills to load

- `testing-r-packages` for tests; `cli` for messages; `quarto-authoring` for the README/vignettes; `r-package-development`, `cran-extrachecks`, `lifecycle` (Posit) for CRAN work and deprecations, if installed.

## Conventions

- The roxygen block sits **inside** the function body in this package (`f <- function(...) { #' ... }`): keep that style when editing, and regenerate with `devtools::document()`; never edit `NAMESPACE`/`man/` by hand. References use Rdpack (`\insertCite{}{biblionetwork}`, `inst/REFERENCES.bib`).
- `README.md` is rendered from `README.qmd`. Update `NEWS.md` and `cran-comments.md` for releases. British English.
- Example data (`data/*_stagflation.rda`, built in `data-raw/`) are the examples of the documentation and the natural test fixtures; do not change them without rebuilding from `data-raw/`.
- `data.table` functions can modify by reference: check that functions never alter the user's input table (a classic bug to test).

## Tests

`tests/testthat/` (testthat 3, one file per `R/` file, `helper-fixtures.R`
with hand-built toy tables whose expected weights are computed on paper in
the tests, and `slow_coupling()`, a loop implementation used as a
cross-check). `test-databases.R` runs the invariants on samples of
`~/data/scopus/scopus.duckdb` (Journal of Monetary Economics 1995-1999) and
`~/data/wos/wos.duckdb` (`ID_Art <= 3000`); it is skipped on CRAN, CI and
wherever the databases are absent. Never write a test that builds a huge pair
table. Run `devtools::test()`; a single file: `devtools::test(filter = "coupling_strength")`.

