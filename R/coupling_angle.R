coupling_angle <- function(dt, source, ref, normalized_weight_only = TRUE, weight_threshold = 1, output_in_character = TRUE)
{
  #' Bibliographic coupling edges, weighted by the coupling angle
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Builds the edges of a *bibliographic coupling* network from a table of
  #' direct citations (one row per citing document and cited reference). Two
  #' documents are coupled when their bibliographies overlap
  #' \insertCite{kessler1963}{biblionetwork}, and the weight of the tie is the
  #' coupling angle \insertCite{sen1983}{biblionetwork}: the number of shared
  #' references divided by the geometric mean of the lengths of the two
  #' bibliographies (a cosine).
  #'
  #' @section Why use it in research:
  #' Documents that cite the same references rely on the same literature: they
  #' are likely to address related questions, with related tools. Bibliographic
  #' coupling is therefore a standard way of mapping the *research fronts* of a
  #' field, and to group documents into specialities or schools with a
  #' community detection algorithm
  #' \insertCite{boyack2005,boyack2010,yan2012}{biblionetwork}. Two properties
  #' make it convenient for the history and sociology of science:
  #'
  #' * the links are fixed when a document is published, since they depend only
  #'   on its own bibliography. A network built for 1970-1979 does not change
  #'   when later documents are added, which allows comparing successive time
  #'   windows (a dynamic analysis);
  #' * it covers all the documents of the corpus, even uncited ones, as long as
  #'   their references are recorded.
  #'
  #' Its limit is the quality of the reference lists: documents without
  #' recorded references cannot be linked. Compare with the
  #' [co-citation][biblio_cocitation()] approach, which links *cited* documents
  #' and changes as new citations accumulate, and with the measures that weight
  #' the shared references ([coupling_strength()], [coupling_similarity()]).
  #'
  #' @section Intuition:
  #' Picture each bibliography as a shopping list. Two lists that contain many
  #' of the same items are probably written by people who shop for the same
  #' meal. But a very long list contains many items by sheer size, and would
  #' look similar to everybody: the weight therefore compares the shared items
  #' with the geometric mean of the lengths of the two lists. Geometrically,
  #' each document is an arrow in a space with one axis per reference, pointing
  #' along the axes of the references it cites; the weight is the cosine of the
  #' angle between two arrows (hence "coupling angle"): 1 for identical
  #' bibliographies (same direction), 0 for bibliographies with nothing in
  #' common (perpendicular).
  #'
  #' @details
  #' Write \eqn{R(A)} for the set of references of document \eqn{A}, and
  #' \eqn{L(A) = |R(A)|} for the length of its bibliography. The weight of the
  #' tie between \eqn{A} and \eqn{B} is
  #'
  #' \deqn{w_{AB} = \frac{|R(A) \cap R(B)|}{\sqrt{L(A) \, L(B)}}}
  #'
  #' The numerator is the number of shared references (returned as
  #' `nb_shared_references` when `normalized_weight_only = FALSE`). Dividing by
  #' \eqn{\sqrt{L(A) L(B)}} avoids giving too much importance to documents with
  #' a long bibliography, such as literature reviews. The weight lies between 0
  #' and 1, and is 1 only if the two bibliographies are identical.
  #'
  #' The function applies the following rules, which matter for the
  #' interpretation of the result:
  #'
  #' * duplicated rows are counted once, and a document citing itself is
  #'   ignored;
  #' * \eqn{L(A)} counts *all* the references of \eqn{A}, including those cited
  #'   by no other document of the table. Such references cannot create a tie
  #'   but they lengthen the bibliography, and so lower the weights of
  #'   \eqn{A};
  #' * rows with a missing identifier are dropped, with a warning;
  #' * the table of the user is not modified;
  #' * if no reference is shared by two documents (or if no pair reaches
  #'   `weight_threshold`), a zero-row table is returned, with the usual
  #'   columns, and a warning that says why.
  #'
  #' The function is written with `data.table` and is fast, but it first lists
  #' every pair of documents citing a same reference: a reference cited by
  #' \eqn{n} documents creates \eqn{n (n - 1) / 2} pairs. Very popular
  #' references (a classic cited by tens of thousands of documents) may
  #' therefore exhaust the memory on a large corpus. Split the corpus (by time
  #' window, for instance), or remove the most cited references, before
  #' calling the function.
  #'
  #' The function is general: it only needs two columns of identifiers. With
  #' `source` the articles and `ref` the words of their titles, it builds a
  #' title co-occurrence network; with `source` the cited documents and `ref`
  #' the citing ones, a co-citation network (but see [biblio_cocitation()]).
  #'
  #' @param dt A data frame or a `data.table` of direct citations, one row per
  #'   link between a citing document and a cited reference. It is not modified.
  #' @param source Character scalar. The column of the citing documents: they
  #'   are the nodes of the coupling network.
  #' @param ref Character scalar. The column of the cited references.
  #' @param normalized_weight_only Logical. If `FALSE`, the number of shared
  #'   references is returned in addition to the normalised `weight`.
  #' @param weight_threshold Number. The minimum number of shared references
  #'   for two documents to be linked (1 by default: any shared reference
  #'   creates a tie). A threshold of 2 or 3 is common in large corpora, where
  #'   sharing a single reference is weak evidence of proximity and produces
  #'   very dense networks. It applies to the number of shared references, not
  #'   to the normalised weight.
  #' @param output_in_character Logical. If `TRUE` (default), the identifiers
  #'   are also returned as character columns `from` and `to`, to build a
  #'   [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph more
  #'   easily.
  #'
  #' @return A `data.table` with one row per pair of documents sharing at least
  #'   `weight_threshold` references: the identifiers in `from` and `to` (if
  #'   `output_in_character = TRUE`), the `weight` (coupling angle) and,
  #'   if `normalized_weight_only = FALSE`, `nb_shared_references`. The
  #'   original identifiers are kept in `Source` and `Target` (`from` and `to`
  #'   are modified by tidygraph when a graph is created). The network is
  #'   undirected: each pair appears once, with `Source < Target`.
  #'
  #' @family coupling measures
  #'
  #' @seealso [biblio_coupling()], which gives access to this measure and to the
  #'   other methods through its `method` argument.
  #'
  #' @examples
  #' library(biblionetwork)
  #' # Edges between the documents explaining the 1970s stagflation, keeping
  #' # the pairs that share at least three references
  #' edges <- coupling_angle(Ref_stagflation,
  #'                          source = "Citing_ItemID_Ref",
  #'                          ref = "ItemID_Ref",
  #'                          weight_threshold = 3)
  #' head(edges)
  #'
  #' # A tiny example that can be checked by hand: d1 and d2 share two of
  #' # their (respectively 3 and 2) references, so the weight is 2 / sqrt(3 * 2)
  #' toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2"),
  #'                   ref = c("r1", "r2", "r3", "r1", "r2"))
  #' coupling_angle(toy, source = "doc", ref = "ref", normalized_weight_only = FALSE)
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  N <- weight <- nb_ref_Target <- nb_ref_Source <- NULL

  check_bool(normalized_weight_only, "normalized_weight_only")
  check_bool(output_in_character, "output_in_character")
  check_threshold(weight_threshold)

  bib_coup <- coupling_core(dt, source, ref, weight_threshold, needs = character())

  # Cosine normalisation by the length of the two bibliographies
  bib_coup[, weight := coupling_weights(bib_coup, "angle")]
  data.table::setnames(bib_coup, "N", "nb_shared_references")

  finalise_edges(
    bib_coup,
    extra = if (normalized_weight_only) character() else "nb_shared_references",
    output_in_character = output_in_character,
    from_to = output_in_character
  )
}
