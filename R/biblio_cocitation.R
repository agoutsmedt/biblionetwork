biblio_cocitation <- function(dt, source, ref, normalized_weight_only = TRUE, weight_threshold = 1, output_in_character = TRUE, method = c("angle", "strength", "similarity", "jaccard", "vladutz"))
{
  #' Co-citation edges, with the same weights as the coupling measures
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Builds the edges of a *co-citation* network from a table of direct
  #' citations (one row per citing document and cited reference). Two
  #' references are co-cited when at least one document cites both of them
  #' \insertCite{small1973}{biblionetwork}. By default the weight is the
  #' co-citation angle \insertCite{sen1983}{biblionetwork}: the number of
  #' documents citing both references, divided by the geometric mean of the
  #' numbers of citations received by each of them. With `method`, the
  #' co-citation can also be weighted like the coupling measures
  #' ([coupling_strength()], [coupling_similarity()], [coupling_jaccard()],
  #' [coupling_vladutz()]): see the section on the idf weights below.
  #'
  #' @section Why use it in research:
  #' Where bibliographic coupling looks at what documents *use*, co-citation
  #' looks at how the community *perceives* cited documents: references that
  #' are regularly cited together are considered by citing authors as belonging
  #' to the same body of work. Co-citation networks are the classic tool to
  #' map the intellectual base of a field (schools, paradigms, canonical
  #' references) and to identify the key texts of each cluster
  #' \insertCite{boyack2005,boyack2010,yan2012}{biblionetwork}. Unlike
  #' coupling, a co-citation network is not fixed at the date of publication
  #' of the cited documents: it depends on later citations, and thus changes
  #' as the corpus of citing documents grows. This is a feature if you want to
  #' study how the reception of texts evolves, but it must be kept in mind
  #' when comparing time windows. A reference that is rarely cited has a very
  #' uncertain position, hence the interest of `weight_threshold`.
  #'
  #' @section Intuition:
  #' Imagine that each citing document is a reading list. Two references that
  #' appear together on many lists are probably about related things. The
  #' weight with `method = "angle"` asks: among all the lists where *one* of
  #' the two references appears, how often is the other one there too? A
  #' reference cited a thousand times appears on many lists by default, so it
  #' must be seen with another reference much more often to be considered
  #' close to it: that is what the division by the number of citations does.
  #'
  #' @section Weighting the co-citing documents (the idf methods):
  #' The idf measures of the coupling functions give more weight to a
  #' rare shared item. In coupling, the shared items are references, and a
  #' reference cited by few documents is rare. Co-citation is the mirror
  #' image \insertCite{rousseau2010}{biblionetwork}: the shared items are the
  #' *citing documents*, and a citing document is "rare" when it cites few
  #' references. The intuition is again about reading lists: a document that
  #' cites only 8 references and puts A and B among them tells much more
  #' about the closeness of A and B than a review that cites 300 references
  #' and puts A and B among them by completeness. With `method = "strength"`
  #' (and `"similarity"`), the co-citation of A and B by a document \eqn{d} is
  #' weighted by \eqn{\log(M / L_d)}, with \eqn{M} the number of references in
  #' the table and \eqn{L_d} the number of references of \eqn{d}. This is a
  #' direct transposition of the formulas of [coupling_strength()] and
  #' [coupling_similarity()] (swapping the two columns of the table): it is
  #' not a measure proposed in the literature as such, so compare it with the
  #' default on your corpus ([compute_couplings()] with
  #' `network = "cocitation"`).
  #'
  #' @details
  #' Write \eqn{C(A)} for the set of documents citing reference \eqn{A}. The
  #' weight of the tie between references \eqn{A} and \eqn{B} with the default
  #' `method = "angle"` is
  #'
  #' \deqn{w_{AB} = \frac{|C(A) \cap C(B)|}{\sqrt{|C(A)| \, |C(B)|}}}
  #'
  #' The numerator is the number of documents citing both references (returned
  #' as `nb_shared_citations` when `normalized_weight_only = FALSE`). The
  #' other methods are those of the coupling functions, applied to the
  #' references as nodes: see the documentation of each, replacing "document"
  #' by "reference" and "reference" by "citing document".
  #'
  #' Computing choices:
  #'
  #' * \eqn{|C(A)|} is the number of citations received in the *whole* table,
  #'   including from documents that cite only one reference;
  #' * documents citing a single reference cannot co-cite anything and are
  #'   ignored in the numerator;
  #' * duplicated rows are counted once, and rows with a missing identifier
  #'   are dropped with a warning;
  #' * the table of the user is not modified;
  #' * if no pair of references is co-cited (or none reaches `weight_threshold`),
  #'   a zero-row table is returned with a warning explaining why.
  #'
  #' Memory and speed: the pairs are computed with sparse matrices, as in
  #' [coupling_angle()]; a few documents with extremely long bibliographies
  #' still create many pairs. Consider removing them first.
  #'
  #' @inheritParams coupling_angle
  #' @param ref Character scalar. The column of the cited references: they are
  #'   the nodes of the co-citation network.
  #' @param normalized_weight_only Logical. If `FALSE`, the number of
  #'   documents citing both references is returned in addition to the
  #'   normalised `weight`.
  #' @param weight_threshold Number. The minimum number of documents that must
  #'   cite two references together for them to be linked (1 by default).
  #' @param method The weight: `"angle"` (default, the co-citation angle),
  #'   `"strength"`, `"similarity"`, `"jaccard"` or `"vladutz"` (see above).
  #'
  #' @return A `data.table` with one row per pair of references: the
  #'   identifiers in `from` and `to` (if `output_in_character = TRUE`), the
  #'   `weight` and, if `normalized_weight_only = FALSE`,
  #'   `nb_shared_citations`. The original identifiers are kept in `Source`
  #'   and `Target`. Each pair appears once, with `Source < Target`.
  #'
  #' @family co-citation and co-authorship measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' # Co-citation network of the references of the stagflation corpus,
  #' # keeping the pairs co-cited at least three times
  #' edges <- biblio_cocitation(Ref_stagflation,
  #'                            source = "Citing_ItemID_Ref",
  #'                            ref = "ItemID_Ref",
  #'                            weight_threshold = 3)
  #' head(edges)
  #'
  #' # The same pairs, weighted by the specificity of the co-citing documents
  #' head(biblio_cocitation(Ref_stagflation, "Citing_ItemID_Ref", "ItemID_Ref",
  #'                        weight_threshold = 3, method = "strength"))
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

  # Co-citation is coupling with the two columns swapped: the nodes are the references
  bib_cocit <- coupling_core(dt, ref, source, weight_threshold,
                             needs = coupling_needs(method), nodes = "references")
  bib_cocit[, weight := coupling_weights(bib_cocit, method)]
  data.table::setnames(bib_cocit, "N", "nb_shared_citations")

  finalise_edges(
    bib_cocit,
    extra = if (normalized_weight_only) character() else "nb_shared_citations",
    output_in_character = output_in_character,
    from_to = output_in_character
  )
}
