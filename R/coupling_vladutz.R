coupling_vladutz <- function(dt, source, ref, weight_threshold = 1, output_in_character = TRUE)
{
  #' Bibliographic coupling edges, weighted by the Vladutz-Cook formula
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' The first coupling measure that weights shared references by their
  #' rarity, proposed by \insertCite{vladutz1984}{biblionetwork} and reported
  #' by \insertCite{shen2019}{biblionetwork} (their Eq. 6). It is the
  #' ancestor of [coupling_strength()], which \insertCite{shen2019}{biblionetwork}
  #' present as a correction of it based on the probabilistic interpretation
  #' of the inverse document frequency.
  #'
  #' @section Why use it in research:
  #' It is provided mainly for comparison and replication: it also discounts
  #' the references cited by many documents, but the weight of a reference
  #' decreases as \eqn{1/f_j} instead of \eqn{\log(N/f_j)}, so that it
  #' almost ignores all the references except the rarest ones. In the corpus
  #' of \insertCite{shen2019}{biblionetwork} it differs markedly from the other
  #' measures (correlations of about 0.6 to 0.7 with the relative coupling, the coupling angle, the coupling strength and the similarity). Use [compute_couplings()] and
  #' [correlate_weights()] to see how much it matters on your corpus.
  #'
  #' @section Intuition:
  #' A shared reference counts for the *inverse* of the number of documents that
  #' cite it: a reference shared by two documents and cited by nobody else
  #' counts \eqn{1/2}, one cited by a hundred documents counts \eqn{1/100}.
  #' This is a very steep discount: the measure is almost entirely driven by the
  #' rarest references. The sum is then divided by the average length of the two
  #' bibliographies (the factor 4 is a convenient scaling). Compare with
  #' [coupling_strength()], whose discount (a logarithm) is much gentler.
  #'
  #' @details
  #' Write \eqn{f_j} for the number of documents citing reference \eqn{j} and
  #' \eqn{L(A)} for the length of the bibliography of \eqn{A}.
  #'
  #' \deqn{w_{AB} = \frac{4}{L(A) + L(B)} \sum_{j \in R(A) \cap R(B)} \frac{1}{f_j}}
  #'
  #' The factor 4 is a normalisation that changes no ranking. It makes the
  #' weight reach 1 for two documents with identical bibliographies made of
  #' references each cited by exactly two documents; since shared references
  #' have \eqn{f_j \geq 2}, the weight is never above 1. Computing choices: see
  #' [coupling_strength()].
  #'
  #' @inheritParams coupling_angle
  #' @return A `data.table` with one row per pair of documents sharing at
  #'   least `weight_threshold` references: `from` and `to` (character if
  #'   `output_in_character = TRUE`), the `weight` and the original
  #'   identifiers in `Source` and `Target`. Each pair appears once, with
  #'   `Source < Target`.
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2", "d3", "d3", "d4", "d4"),
  #'                   ref = c("r1", "r2", "r3", "r1", "r2", "r3", "r4", "r4", "r5"))
  #' coupling_vladutz(toy, source = "doc", ref = "ref")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  weight <- sum_inv_freq <- nb_ref_Target <- nb_ref_Source <- NULL

  check_bool(output_in_character, "output_in_character")
  check_threshold(weight_threshold)

  bib_coup <- coupling_core(dt, source, ref, weight_threshold, needs = "inv_freq")
  bib_coup[, weight := coupling_weights(bib_coup, "vladutz")]

  finalise_edges(bib_coup, output_in_character = output_in_character)
}
