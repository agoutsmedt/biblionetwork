coauth_network <- function(dt, authors, articles, method = c("full_counting", "fractional_counting", "fractional_counting_refined"), cosine_normalized = FALSE)
{
  #' Co-authorship edges, with full or fractional counting
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Builds the edges of a co-authorship network from a table with one row per
  #' author (or institution, or country) and document. Two authors are linked
  #' when they have co-signed documents. The weight of the tie can count each
  #' collaboration fully, or share it between the pairs of co-authors of a
  #' document (*fractional counting*), following
  #' \insertCite{perianes-rodriguez2016b,leydesdorff2017}{biblionetwork}, and
  #' can be normalised by the productivity of the two authors with a cosine.
  #'
  #' @section Why use it in research:
  #' Co-authorship networks describe the social structure of a research
  #' community: who collaborates with whom, the existence of collaborative
  #' cliques, the central or bridging positions. The way collaborations are
  #' counted changes the picture. With full counting, a document signed by ten
  #' authors creates 45 ties of weight 1 and weighs much more in the network
  #' than a document signed by two authors; fractional counting corrects this
  #' by giving a document a total weight that does not depend on its number of
  #' authors. Normalising by productivity prevents very prolific authors from
  #' being linked to everybody. Perianes-Rodriguez et al.
  #' \insertCite{perianes-rodriguez2016b}{biblionetwork} compare full and
  #' fractional counting for bibliometric networks: read it before choosing.
  #' The nodes can be authors, institutions or countries, the latter being the
  #' basis of studies of international collaboration.
  #'
  #' @section Intuition:
  #' Think of each document as a pie of value 1 to share among the pairs of its
  #' authors. With full counting, every pair of co-authors receives a full pie:
  #' a document with ten authors distributes 45 pies, a document with two
  #' authors distributes one. With fractional counting, a document always
  #' distributes the same total (one pie in the refined version, or one pie per
  #' author in the other), so that large collaborations do not dominate. The
  #' cosine then asks whether two authors collaborate much *relative to* how
  #' much each of them collaborates in general.
  #'
  #' @details
  #' Write \eqn{a_{ik} = 1} if author \eqn{i} signed document \eqn{k}, and
  #' \eqn{n_k = \sum_i a_{ik}} for its number of authors. The weight of the tie
  #' between \eqn{i} and \eqn{j} is, according to `method`:
  #'
  #' * `"full_counting"`: the number of documents they co-signed,
  #'   \deqn{w_{ij} = \sum_{k} a_{ik} a_{jk}}
  #' * `"fractional_counting"`
  #'   \insertCite{perianes-rodriguez2016b}{biblionetwork}: each document
  #'   gives \eqn{1/(n_k - 1)} to each pair,
  #'   \deqn{w_{ij} = \sum_{k} \frac{a_{ik} a_{jk}}{n_k - 1}}
  #'   so that the weights of the ties of an author in a document sum to 1;
  #' * `"fractional_counting_refined"`, inspired by
  #'   \insertCite{leydesdorff2017}{biblionetwork}: each document gives
  #'   \eqn{2 / (n_k (n_k - 1))} to each pair,
  #'   \deqn{w_{ij} = \sum_{k} \frac{2 \, a_{ik} a_{jk}}{n_k (n_k - 1)}}
  #'   so that each document has a total weight of 1 in the network: the sum
  #'   of all the weights equals the number of (multi-authored) documents.
  #'
  #' If `cosine_normalized = TRUE`, the weight is divided by
  #' \eqn{\sqrt{P_i P_j}}, with \eqn{P_i} the number of co-authored documents
  #' of author \eqn{i} (documents with a single author are ignored in the
  #' whole function, since they create no tie).
  #'
  #' Duplicated rows are counted once, rows with a missing identifier are
  #' dropped with a warning, the table of the user is not modified, and a
  #' zero-row table is returned, with a warning, if nobody co-authored a document.
  #'
  #' @param dt A data frame or a `data.table` with one row per author and
  #'   document. It is not modified.
  #' @param authors Character scalar. The column of the authors (or
  #'   institutions, or countries), the nodes of the network.
  #' @param articles Character scalar. The column of the documents.
  #' @param method `"full_counting"` (default), `"fractional_counting"` or
  #'   `"fractional_counting_refined"` (see the details).
  #' @param cosine_normalized Logical. If `TRUE`, divides the weight by the
  #'   geometric mean of the numbers of co-authored documents of the two
  #'   authors (Salton's cosine).
  #'
  #' @return A `data.table` with one row per pair of authors: `from` and `to`
  #'   (copies of `Source` and `Target`, with the type of the `authors`
  #'   column), the `weight`, and the original identifiers in `Source` and
  #'   `Target`. Each pair appears once, with `Source > Target` (the orientation of
  #'   the previous versions of the package).
  #'
  #' @family co-citation and co-authorship measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' coauth_network(Authors_stagflation,
  #'                authors = "Author",
  #'                articles = "ItemID_Ref",
  #'                method = "fractional_counting")
  #'
  #' # Toy example: three authors sign document 1, two sign document 2.
  #' # With fractional counting, a-b gets 1/2 + 1/1 = 1.5
  #' toy <- data.frame(author = c("a", "b", "c", "a", "b"),
  #'                   paper = c(1, 1, 1, 2, 2))
  #' coauth_network(toy, authors = "author", articles = "paper",
  #'                method = "fractional_counting")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  N <- Source <- Target <- weight <- nb_art_Target <- nb_art_Source <- nb_auth <- nb_art <- NULL

  method <- rlang::arg_match(method)
  check_bool(cosine_normalized, "cosine_normalized")

  # A cleaned copy: the loops (an author with herself) are not an issue here
  dt <- prepare_links(dt, authors, articles, new_names = c("authors", "articles"),
                      remove_loops = FALSE, arg_names = c("authors", "articles"))

  # Single-author documents create no tie
  dt <- dt[, nb_auth := .N, by = "articles"][nb_auth > 1]

  if (nrow(dt) == 0) {
    warn_no_edges(
      0L, 1,
      none = "No document has more than one author: there is no co-authorship tie.",
      unit = "co-authored documents",
      hint = "Check that {.arg authors} and {.arg articles} are not inverted."
    )
  }

  # The nodes (sorted authors) and the links author -> document
  authors_id <- sort(unique(dt$authors))
  i <- match(dt$authors, authors_id)
  j <- match(dt$articles, unique(dt$articles))

  # The weight of each document, shared by every pair of its authors
  document_weight <- switch(
    method,
    full_counting = rep(1, nrow(dt)),
    fractional_counting = 1 / (dt$nb_auth - 1),
    fractional_counting_refined = 2 / (dt$nb_auth * (dt$nb_auth - 1))
  )

  # Sum of the weights of the documents co-signed by each pair (sparse
  # cross-product: see coupling_core())
  coauth <- sparse_product(i, j, document_weight, length(authors_id), max(j, 0L))
  coauth <- data.table::data.table(Source = authors_id[coauth$i], Target = authors_id[coauth$j],
                                   weight = coauth$x, i = coauth$i, j = coauth$j)

  if (cosine_normalized) {
    # P_i: number of co-authored documents of each author
    nb_art <- tabulate(i, nbins = length(authors_id))
    coauth[, weight := weight / sqrt(nb_art[i] * nb_art[j])]
  }
  coauth[, c("i", "j") := NULL]

  # Orientation kept from  # Orientation kept from the previous versions of the package (Source > Target),
  # unlike the coupling functions
  coauth[, c("Source", "Target") := list(Target, Source)]

  finalise_edges(coauth, output_in_character = FALSE)
}
