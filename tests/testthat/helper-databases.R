# Local only: excluded from the built package (see .Rbuildignore), so that
# DBI and duckdb are not needed to check the package. Run with devtools::test().

# Opens a read-only connection to one of the authors' databases, and closes
# it at the end of the test. Skipped where the database is not available (CRAN,
# CI, other computers): the data cannot be distributed with the package.
local_database <- function(path, env = parent.frame()) {
  testthat::skip_on_cran()
  testthat::skip_on_ci()
  path <- path.expand(path)
  testthat::skip_if_not(file.exists(path), "Database not available")
  testthat::skip_if_not_installed("duckdb")
  testthat::skip_if_not_installed("DBI")
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE), path, read_only = TRUE)
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE), envir = env)
  con
}
