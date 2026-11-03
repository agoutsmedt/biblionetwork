coupling_strength <- function(dt, source, ref, weight_threshold = 1, output_in_character = TRUE)
{
  #' Bibliographic coupling edges, weighted by the coupling strength
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Builds the edges of a bibliographic coupling network in which the shared
  #' references are not all equal: sharing a reference that few documents cite
  #' says more about the proximity of two documents than sharing a reference
  #' that the whole corpus cites. The weight is the *coupling strength*
  #' \insertCite{vladutz1984,shen2019}{biblionetwork}, a refinement of the
  #' coupling angle of [coupling_angle()] that gives each shared reference a
  #' weight decreasing with its number of citations, in the spirit of the
  #' inverse document frequency of information retrieval
  #' \insertCite{sparckjones1972,salton1988}{biblionetwork} (see
  #' [tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)).
  #'
  #' @section Why use it in research:
  #' In a corpus built around a topic (the stagflation literature, a journal,
  #' a decade of central-banking research), a few references are cited by most
  #' documents: they define the field but do not distinguish the
  #' documents within it. With the coupling angle, two documents sharing only
  #' such classics are as close as two documents sharing equally many rare
  #' references. The coupling strength corrects this, and makes the resulting
  #' network more suited to detecting sub-specialities. The cost is a measure
  #' that depends on the whole corpus: the weight of a tie changes if documents
  #' are added to the table, and is not comparable across corpora of different
  #' sizes (see below).
  #'
  #' @section Intuition:
  #' Two economists who both cite the most famous paper of their field are not
  #' necessarily working on the same question; two who both cite an obscure
  #' working paper probably are. The coupling strength measures how *surprising*
  #' a shared reference is: a reference cited by a fraction \eqn{f/N} of the
  #' corpus has a surprise of \eqn{\log(N/f)}, which is 0 for a reference
  #' cited by everybody and grows as the reference gets rarer. The tie is the
  #' total surprise of what two documents share, divided (as for the coupling
  #' angle) by the lengths of the two bibliographies. It is the same logic as
  #' the tf-idf of search engines, where a word found in every text does not
  #' help to find a particular one.
  #'
  #' @details
  #' Write \eqn{N} for the number of citing documents in the table,
  #' \eqn{f_j} for the number of documents citing reference \eqn{j},
  #' \eqn{R(A)} for the references of document \eqn{A} and \eqn{L(A) = |R(A)|}
  #' for the length of its bibliography. The weight of the tie between \eqn{A}
  #' and \eqn{B} is
  #'
  #' \deqn{w_{AB} = \frac{\sum_{j \in R(A) \cap R(B)} \log(N / f_j)}{L(A) \, L(B)}}
  #'
  #' A reference cited by every document has weight \eqn{\log(1) = 0}; a
  #' reference cited by two documents has weight \eqn{\log(N/2)}. Contrary to
  #' the coupling angle, the denominator is the product (not the square root
  #' of the product) of the lengths, and the weight is not bounded by 1; the
  #' scale of the weights depends on \eqn{N}, so that the weights are
  #' meaningful relative to each other within one call, not across calls.
  #' This is Eq. 7 of \insertCite{shen2019}{biblionetwork}, who use base-10
  #' logarithms; the natural logarithm used here multiplies all the weights by
  #' the same constant (\eqn{\ln 10}), which changes no ranking and no
  #' correlation. Unlike [coupling_similarity()], the lengths \eqn{L} are simple
  #' counts of references, not sums of idf weights.
  #'
  #' Computing choices:
  #'
  #' * \eqn{N} is the number of distinct citing documents in the table,
  #'   *including* those that share no reference with any other document;
  #' * \eqn{L(A)} counts all the references of \eqn{A}, including those
  #'   cited by no other document;
  #' * duplicated rows are counted once, a document citing itself is ignored,
  #'   and rows with a missing identifier are dropped with a warning;
  #' * the table of the user is not modified;
  #' * if no reference is shared (or if no pair reaches `weight_threshold`), a
  #'   zero-row table is returned, with a warning that says why.
  #'
  #' Memory: like all the coupling functions, it first lists all the pairs of
  #' documents citing a same reference. A reference cited by \eqn{n} documents
  #' creates \eqn{n (n - 1) / 2} pairs, and very popular references can
  #' exhaust the memory. Since such references have the smallest weights, they
  #' can often be removed before the call with little effect on the result.
  #'
  #' @inheritParams coupling_angle
  #' @param weight_threshold Number. The minimum number of shared references
  #'   for two documents to be linked (1 by default). It applies to the number
  #'   of shared references, not to the weight.
  #'
  #' @return A `data.table` with one row per pair of documents sharing at
  #'   least `weight_threshold` references: the identifiers in `from` and `to`
  #'   (character if `output_in_character = TRUE`), the coupling strength in
  #'   `weight`, and the original identifiers in `Source` and `Target`. Each
  #'   pair appears once, with `Source < Target`.
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' coupling_strength(Ref_stagflation,
  #'                   source = "Citing_ItemID_Ref",
  #'                   ref = "ItemID_Ref")
  #'
  #' # A toy example: d1 and d2 share r1 and r2, each cited by 2 of the
  #' # 4 documents, so w = 2 * log(4 / 2) / (3 * 2)
  #' toy <- data.frame(doc = c("d1", "d1", "d1", "d2", "d2", "d3", "d3", "d4", "d4"),
  #'                   ref = c("r1", "r2", "r3", "r1", "r2", "r3", "r4", "r4", "r5"))
  #' coupling_strength(toy, source = "doc", ref = "ref")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  weight <- sum_idf <- nb_ref_Target <- nb_ref_Source <- NULL

  check_bool(output_in_character, "output_in_character")
  check_threshold(weight_threshold)

  bib_coup <- coupling_core(dt, source, ref, weight_threshold, needs = "idf")
  bib_coup[, weight := coupling_weights(bib_coup, "strength")]

  finalise_edges(bib_coup, output_in_character = output_in_character)
}
