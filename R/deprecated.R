coupling_entity <- function(dt, source, ref, entity, weight_threshold = 1, output_in_character = FALSE, method = c("coupling_strength", "coupling_angle", "coupling_similarity"))
{
  #' Coupling edges between entities (deprecated)
  #'
  #' `r lifecycle::badge("deprecated")`
  #'
  #' @description
  #' `coupling_entity()` was renamed [entity_network()], because it is not a
  #' measure of coupling of its own but the aggregation of the coupling (or
  #' co-citation) measures at the level of entities. It is kept as a wrapper,
  #' that accepts the former names of the methods (`"coupling_strength"`,
  #' `"coupling_angle"`, `"coupling_similarity"`), and will be removed in a
  #' future version.
  #'
  #' @inheritParams entity_network
  #' @param method `"coupling_strength"` (default), `"coupling_angle"` or
  #'   `"coupling_similarity"`: the former names of the methods `"strength"`,
  #'   `"angle"` and `"similarity"` of [entity_network()]. The `Weighting_method`
  #'   column of the result keeps the former name.
  #'
  #' @return See [entity_network()].
  #'
  #' @keywords internal
  #' @export

  Weighting_method <- NULL
  lifecycle::deprecate_warn("0.2.0", "coupling_entity()", "entity_network()")
  method <- rlang::arg_match(method)
  edges <- entity_network(dt, source, ref, entity, network = "coupling",
                          method = sub("^coupling_", "", method),
                          weight_threshold = weight_threshold,
                          output_in_character = output_in_character)
  # The former names of the methods are kept in the output
  edges[, Weighting_method := method]
  edges[]
}
