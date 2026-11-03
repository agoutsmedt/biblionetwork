biblio_coupling <- function(dt, source, ref, method = c("angle", "strength", "similarity", "jaccard", "vladutz"), normalized_weight_only = TRUE, weight_threshold = 1, output_in_character = TRUE)
{
  #' Bibliographic coupling edges, with the weighting method of your choice
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' The general entry point to bibliographic coupling. From a table of direct
  #' citations (one row per citing document and cited reference), it returns the
  #' edges of the network linking the documents that share references
  #' \insertCite{kessler1963}{biblionetwork}, weighted by the `method` you
  #' choose. It is a thin wrapper: every method is also available as a
  #' function of its own, which documents the formula and the reasons to
  #' choose it.
  #'
  #' | `method` | Function | Weight |
  #' |---|---|---|
  #' | `"angle"` (default) | [coupling_angle()] | cosine of the bibliographies \insertCite{sen1983}{biblionetwork} |
  #' | `"strength"` | [coupling_strength()] | shared references weighted by their rarity \insertCite{shen2019}{biblionetwork} |
  #' | `"similarity"` | [coupling_similarity()] | idf-weighted cosine \insertCite{shen2019}{biblionetwork} |
  #' | `"jaccard"` | [coupling_jaccard()] | shared references over the union of the bibliographies \insertCite{sen1983}{biblionetwork} |
  #' | `"vladutz"` | [coupling_vladutz()] | Vladutz and Cook formula \insertCite{vladutz1984}{biblionetwork} |
  #'
  #' In versions up to 0.1.1, `biblio_coupling()` was what is now
  #' [coupling_angle()]: calls that leave `method` to its default give the same
  #' result. To compare several methods at once on the same corpus, use
  #' [compute_couplings()]; to couple authors, journals or institutions rather
  #' than documents, use [entity_network()]; to link cited references, use
  #' [biblio_cocitation()].
  #'
  #' @inheritParams coupling_angle
  #' @param method The weighting method, one of `"angle"` (default),
  #'   `"strength"`, `"similarity"`, `"jaccard"` and `"vladutz"`. See the table
  #'   above and the help page of each function.
  #'
  #' @return A `data.table` with one row per pair of documents sharing at least
  #'   `weight_threshold` references: `Source` and `Target` (identifiers, with
  #'   `Source < Target`), `from` and `to` (the same, as characters, if
  #'   `output_in_character = TRUE`), the `weight` and, if
  #'   `normalized_weight_only = FALSE`, `nb_shared_references`. Whatever the
  #'   method, the weights of different methods do not have the same scale: see
  #'   [compute_couplings()] to compare them.
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' # The default is the coupling angle...
  #' head(biblio_coupling(Ref_stagflation,
  #'                      source = "Citing_ItemID_Ref",
  #'                      ref = "ItemID_Ref",
  #'                      weight_threshold = 3))
  #'
  #' # ...and the method changes the weights, not the pairs of documents
  #' head(biblio_coupling(Ref_stagflation,
  #'                      source = "Citing_ItemID_Ref",
  #'                      ref = "ItemID_Ref",
  #'                      method = "strength",
  #'                      weight_threshold = 3))
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  weight <- NULL

  method <- rlang::arg_match(method)
  check_bool(normalized_weight_only, "normalized_weight_only")
  check_bool(output_in_character, "output_in_character")
  check_threshold(weight_threshold)

  # One engine for all the methods: the pairs are listed once, then weighted
  bib_coup <- coupling_core(dt, source, ref, weight_threshold, needs = coupling_needs(method))
  bib_coup[, weight := coupling_weights(bib_coup, method)]
  data.table::setnames(bib_coup, "N", "nb_shared_references")

  finalise_edges(
    bib_coup,
    extra = if (normalized_weight_only) character() else "nb_shared_references",
    output_in_character = output_in_character,
    from_to = output_in_character
  )
}
