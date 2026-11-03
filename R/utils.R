# Internal helpers shared by the edge-building functions. They are not
# exported. All the functions of the package work on a *copy* of the table of
# the user: the input is never modified by reference.

# Checks (cli messages, as in networkflow) ---------------------------------

# Abort when columns are missing from a table.
check_columns <- function(data, cols, arg, call = rlang::caller_env()) {
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "{.arg {arg}} has no column{?s} {.field {missing_cols}}.",
      call = call
    )
  }
  invisible(data)
}

# Abort when an argument is not a single column name.
check_column_name <- function(x, arg, call = rlang::caller_env()) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be the name of one column (a character string).",
      call = call
    )
  }
  invisible(x)
}

check_bool <- function(x, arg, call = rlang::caller_env()) {
  if (!is.logical(x) || length(x) != 1 || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}.", call = call)
  }
  invisible(x)
}

check_threshold <- function(x, arg = "weight_threshold", call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 1) {
    cli::cli_abort(
      "{.arg {arg}} must be a single number greater than or equal to 1.",
      call = call
    )
  }
  invisible(x)
}

# Preparing the table of links -----------------------------------------------

# Takes the user's table, and returns a new data.table with two columns named
# `new_names[1]` (the "citing" side, `first`) and `new_names[2]` (the "cited"
# side, `second`), keyed on (second, first), without duplicated links, rows
# with missing identifiers, nor (if `remove_loops`) links of an item to itself.
# `as.data.table()` followed by a column selection makes a copy: the user's
# table is not modified.
prepare_links <- function(dt, first, second, new_names = c("id_art", "id_ref"),
                          remove_loops = TRUE, arg_names = c("source", "ref"),
                          call = rlang::caller_env()) {
  if (!is.data.frame(dt)) {
    cli::cli_abort("{.arg dt} must be a data frame or a data.table.", call = call)
  }
  check_column_name(first, arg_names[1], call = call)
  check_column_name(second, arg_names[2], call = call)
  check_columns(dt, c(first, second), "dt", call = call)
  if (identical(first, second)) {
    cli::cli_abort(
      "{.arg {arg_names[1]}} and {.arg {arg_names[2]}} must be two different columns.",
      call = call
    )
  }

  links <- data.table::as.data.table(dt)[, c(first, second), with = FALSE]
  data.table::setnames(links, c(first, second), new_names)
  factors_to_character(links, new_names)

  # Missing identifiers cannot be nodes of a network.
  missing_rows <- links[, which(is.na(.SD[[1L]]) | is.na(.SD[[2L]]))]
  if (length(missing_rows) > 0) {
    cli::cli_warn(
      "Dropping {length(missing_rows)} row{?s} with a missing identifier in {.field {first}} or {.field {second}}.",
      call = call
    )
    links <- links[-missing_rows]
  }

  data.table::setkeyv(links, rev(new_names))
  links <- unique(links)
  if (remove_loops) {
    links <- links[links[[new_names[1]]] != links[[new_names[2]]]]
  }
  links
}

# Identifiers stored as factors are turned into characters (in place, on a copy
# made by the caller): two factors with different levels cannot be compared.
factors_to_character <- function(dt, cols) {
  for (col in cols) {
    if (is.factor(dt[[col]])) data.table::set(dt, j = col, value = as.character(dt[[col]]))
  }
  invisible(dt)
}

# A zero-row edge table with the columns of a result.
empty_edges <- function(source_type, columns, from_to = TRUE) {
  edges <- data.table::data.table(Source = source_type[0], Target = source_type[0], weight = numeric(0))
  for (col in setdiff(columns, names(edges))) {
    edges[, (col) := if (col %in% c("from", "to", "Weighting_method")) character(0) else integer(0)]
  }
  data.table::setcolorder(edges, columns)
  edges
}

# Last step of the functions: orders the columns, and adds `from` and `to`,
# copies of `Source` and `Target` (optionally as character), because tidygraph
# modifies `from` and `to` when it creates a graph. `extra` columns come after
# `weight`, `last` columns at the very end.
finalise_edges <- function(edges, extra = character(), output_in_character = TRUE,
                           from_to = TRUE, last = character()) {
  Source <- Target <- NULL
  if (from_to) {
    columns <- c("from", "to", "weight", extra, "Source", "Target", last)
  } else {
    columns <- c("Source", "Target", "weight", extra, last)
  }
  if (nrow(edges) == 0) {
    return(empty_edges(edges$Source, columns))
  }
  if (from_to) {
    if (output_in_character) {
      edges[, `:=`(from = as.character(Source), to = as.character(Target))]
    } else {
      edges[, `:=`(from = Source, to = Target)]
    }
  }
  edges <- edges[, columns, with = FALSE]
  data.table::setkeyv(edges, NULL)
  edges
}
