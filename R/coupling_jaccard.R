coupling_jaccard <- function(dt, source, ref, weight_threshold = 1, output_in_character = TRUE)
{
  #' Bibliographic coupling edges, weighted by the relative coupling strength (Jaccard)
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' The *relative bibliographic coupling strength* of
  #' \insertCite{sen1983}{biblionetwork}: the number of references shared by
  #' two documents divided by the number of references in the *union* of their
  #' bibliographies. It is a Jaccard index, as noted by
  #' \insertCite{shen2019}{biblionetwork} (who credit Egghe and Rousseau,
  #' 1990). It is the other classic normalisation of the number of shared
  #' references, next to the cosine of [coupling_angle()].
  #'
  #' @section Why use it in research:
  #' Like the coupling angle, it corrects for the length of the bibliographies,
  #' but differently: the cosine divides by the geometric mean of the lengths,
  #' the Jaccard index by the size of the union. The Jaccard index is never
  #' above the cosine, and penalises more strongly the pairs of documents with
  #' bibliographies of very different lengths. Both are bounded between 0 and 1 and give very similar
  #' rankings in practice (\insertCite{shen2019}{biblionetwork} report a
  #' Pearson correlation of 0.956 between the two on their corpus): compare
  #' them on yours with [correlate_weights()].
  #'
  #' @section Intuition:
  #' Take all the references cited by at least one of the two documents (their
  #' union): the weight is the share of them that both documents cite. It is
  #' the answer to "of everything these two documents read, how much did they
  #' read in common?". If one document cites 5 references, all cited by the other
  #' one, which cites 50, the cosine is \eqn{5/\sqrt{250} \approx 0.32} and the
  #' Jaccard index \eqn{5/50 = 0.1}: the Jaccard index sees that the second
  #' document reads much more than the first.
  #'
  #' @details
  #' With \eqn{R(A)} the references of \eqn{A} and \eqn{L(A) = |R(A)|},
  #'
  #' \deqn{w_{AB} = \frac{|R(A) \cap R(B)|}{L(A) + L(B) - |R(A) \cap R(B)|} = \frac{|R(A) \cap R(B)|}{|R(A) \cup R(B)|}}
  #'
  #' Computing choices: see [coupling_angle()]. \eqn{L(A)} counts all the
  #' references of \eqn{A}, including those cited by no other document.
  #'
  #' @inheritParams coupling_angle
  #' @return A `data.table` with one row per pair of documents sharing at
  #'   least `weight_threshold` references: `from` and `to` (character if
  #'   `output_in_character = TRUE`), the `weight` (between 0 and 1) and the
  #'   original identifiers in `Source` and `Target`. Each pair appears once,
  #'   with `Source < Target`.
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' # d1 = {r1, r2, r3} and d2 = {r1, r2} share 2 references out of 3
  #' toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2"),
  #'                   ref = c("r1", "r2", "r3", "r1", "r2"))
  #' coupling_jaccard(toy, source = "doc", ref = "ref")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  weight <- N <- nb_ref_Target <- nb_ref_Source <- NULL

  check_bool(output_in_character, "output_in_character")
  check_threshold(weight_threshold)

  bib_coup <- coupling_core(dt, source, ref, weight_threshold, needs = character())
  bib_coup[, weight := coupling_weights(bib_coup, "jaccard")]

  finalise_edges(bib_coup, output_in_character = output_in_character)
}
