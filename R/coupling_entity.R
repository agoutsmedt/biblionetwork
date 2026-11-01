coupling_entity <- function(dt, source, ref, entity, weight_threshold = 1, output_in_character = FALSE, method = c("coupling_strength", "coupling_angle", "coupling_similarity"))
{
  #' Coupling edges between entities (authors, journals, institutions...)
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Builds the edges of a bibliographic coupling network whose nodes are not
  #' documents but *entities* that cite through their documents: authors,
  #' journals, institutions, countries... Two entities are coupled when the
  #' documents they publish cite the same references. As entities publish
  #' several documents, they can cite the same reference several times, and
  #' the function takes this into account: citing a reference ten times is
  #' more significant than citing it once. The weight is either the coupling
  #' strength of [coupling_strength()] or the coupling angle of
  #' [biblio_coupling()], both adapted to entities following
  #' \insertCite{zhao2008b;textual}{biblionetwork}.
  #'
  #' @section Why use it in research:
  #' Coupling at the level of authors (author bibliographic coupling,
  #' \insertCite{zhao2008b}{biblionetwork}), journals or institutions maps
  #' who relies on the same literature, whatever the documents they publish.
  #' It is a way to study the structure of a discipline through its journals
  #' or its authors, with fewer and denser nodes than the document-level
  #' network. Because entities are aggregates of documents, check that they
  #' are not too heterogeneous (a generalist journal citing everything is
  #' coupled with everyone), and that the number of documents per entity
  #' is large enough to give a stable bibliography. An article with several
  #' authors appears once for each of its authors: the same citing document
  #' then contributes to several entities.
  #'
  #' @section Intuition:
  #' Think of an entity (say a journal) as one big bibliography made of the
  #' bibliographies of all its documents, in which a reference appears as many
  #' times as the entity's documents cite it. Two journals are close when their
  #' big bibliographies overlap. Overlap is measured reference by reference by
  #' the *smaller* of the two counts: if journal A cites a reference 10 times and
  #' journal B twice, they share it twice (B is the limit). The three methods
  #' differ in what they do with these overlaps, as their document-level
  #' counterparts: `"coupling_angle"` only counts them and normalises by the
  #' sizes of the two big bibliographies; `"coupling_strength"` counts a
  #' shared rare reference more than a shared classic; `"coupling_similarity"`
  #' does the same but normalises by the "informational size" of each big
  #' bibliography, to give a cosine that cannot exceed 1.
  #'
  #' @details
  #' Write \eqn{C_{Aj}} for the number of times entity \eqn{A} cites reference
  #' \eqn{j} (the number of its documents citing \eqn{j}), \eqn{N} for the
  #' number of citing documents in the table, \eqn{f_j} for the number of
  #' documents citing \eqn{j}, and \eqn{L(A) = \sum_j C_{Aj}} for the
  #' total number of citations made by \eqn{A}. With `method =
  #' "coupling_strength"`, the weight of the tie between \eqn{A} and \eqn{B} is
  #'
  #' \deqn{w_{AB} = \frac{\sum_{j} \min(C_{Aj}, C_{Bj}) \, \log(N / f_j)}{L(A) \, L(B)}}
  #'
  #' and with `method = "coupling_angle"`,
  #'
  #' \deqn{w_{AB} = \frac{\sum_{j} \min(C_{Aj}, C_{Bj})}{\sqrt{L(A) \, L(B)}}}
  #'
  #' and with `method = "coupling_similarity"`,
  #'
  #' \deqn{w_{AB} = \frac{\sum_{j} \min(C_{Aj}, C_{Bj}) \, \log(N / f_j)}{\sqrt{S(A) \, S(B)}}, \qquad S(A) = \sum_{j} C_{Aj} \log(N / f_j)}
  #'
  #' the sums of the numerators running over the references cited by both
  #' entities, and the sum defining \eqn{S(A)} over all the references of
  #' \eqn{A}. The last variant is not proposed in the literature as such: it is
  #' the cosine of \insertCite{shen2019}{biblionetwork} (see
  #' [coupling_similarity()]) with the minimum rule of
  #' \insertCite{zhao2008b;textual}{biblionetwork} for the counts. It is
  #' bounded by 1, since \eqn{\min(C_{Aj}, C_{Bj}) \leq \sqrt{C_{Aj} C_{Bj}}}
  #' and by the Cauchy-Schwarz inequality. The minimum
  #' of the two counts is the number of times the two entities cite the
  #' reference "together" \insertCite{zhao2008b}{biblionetwork}. \eqn{f_j}
  #' counts citing documents, not entities, so that a document with several
  #' authors is not counted several times. References cited by a single entity
  #' cannot create a tie and are ignored in the sums, but they count in
  #' \eqn{L}.
  #'
  #' The `weight_threshold` applies to the number of references shared by two
  #' entities (each counted once, whatever the number of times it is cited).
  #' The table of the user is not modified, rows with a missing identifier are
  #' dropped with a warning, and a zero-row table is returned, with a warning, if no reference
  #' is shared (or if no pair reaches `weight_threshold`). The memory warning of [coupling_strength()] applies.
  #'
  #' @inheritParams biblio_coupling
  #' @param source Character scalar. The column of the citing documents.
  #'   Needed to count the documents, not to define the nodes.
  #' @param entity Character scalar. The column of the entities that are the
  #'   nodes of the network (authors, journals, institutions...). A document
  #'   can appear with several entities (one row per entity and reference).
  #' @param weight_threshold Number. The minimum number of shared references
  #'   for two entities to be linked (1 by default). With large entities such
  #'   as journals, a higher value is advisable.
  #' @param output_in_character Logical. If `TRUE`, `from` and `to` are
  #'   character columns (`FALSE` by default for this function: they keep the
  #'   type of the entity column).
  #' @param method `"coupling_strength"` (default), `"coupling_angle"` or
  #'   `"coupling_similarity"`: the weight to compute (see the details).
  #'
  #' @return A `data.table` with one row per pair of entities: `from`, `to`,
  #'   the `weight`, the original identifiers in `Source` and `Target`, and the
  #'   `Weighting_method`. Each pair appears once, with `Source < Target`.
  #'
  #' @family coupling measures
  #'
  #' @examples
  #' library(biblionetwork)
  #' Ref_stagflation$Citing_ItemID_Ref <- as.character(Ref_stagflation$Citing_ItemID_Ref)
  #' # merging the references data with the citing author information in Nodes_stagflation
  #' entity_citations <- merge(Ref_stagflation,
  #'                           Nodes_stagflation,
  #'                           by.x = "Citing_ItemID_Ref",
  #'                           by.y = "ItemID_Ref")
  #'
  #' coupling_entity(entity_citations,
  #'                 source = "Citing_ItemID_Ref",
  #'                 ref = "ItemID_Ref",
  #'                 entity = "Author.y",
  #'                 method = "coupling_angle")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  id_ref <- id_art <- N <- Source <- Target <- weight <- nb_cit <- nb_ref <- nb_ref_Target <- nb_ref_Source <-
    nb_cit_entity <- nb_entity <- nb_cit_entity_Target <- nb_cit_entity_Source <- contribution <- Weighting_method <- idf <- Rs <- Rs_Target <- Rs_Source <- NULL

  method <- rlang::arg_match(method)
  check_bool(output_in_character, "output_in_character")
  check_threshold(weight_threshold)
  if (!is.data.frame(dt)) {
    cli::cli_abort("{.arg dt} must be a data frame or a data.table.")
  }
  check_column_name(entity, "entity")
  check_column_name(source, "source")
  check_column_name(ref, "ref")
  check_columns(dt, c(source, entity, ref), "dt")
  if (anyDuplicated(c(source, entity, ref)) > 0) {
    cli::cli_abort("{.arg source}, {.arg entity} and {.arg ref} must be three different columns.")
  }

  # A copy with the three columns, without missing values
  dt <- data.table::as.data.table(dt)[, c(source, entity, ref), with = FALSE]
  data.table::setnames(dt, c(source, entity, ref), c("id_art", "entity", "id_ref"))
  nb_missing <- sum(!stats::complete.cases(dt))
  if (nb_missing > 0) {
    cli::cli_warn("Dropping {nb_missing} row{?s} with a missing identifier.")
    dt <- dt[stats::complete.cases(dt)]
  }

  # N: the number of citing documents in the corpus
  nb_doc <- data.table::uniqueN(dt$id_art)

  # f_j: how many documents cite each reference (by citing document, not by
  # entity, to avoid double-counting documents with several entities)
  ref_nb_cit <- unique(dt[, list(id_art, id_ref)])[, list(nb_cit = .N), by = id_ref]

  # L(A): total number of citations of each entity; C_Aj: number of times an
  # entity cites a reference (number of rows, i.e. of documents of the entity)
  dt <- unique(dt)
  dt <- dt[, list(nb_cit_entity = .N), by = list(entity, id_ref)]
  dt[, nb_ref := as.numeric(sum(nb_cit_entity)), by = entity]
  # S(A): the citations of the entity weighted by the idf of the references (for the similarity)
  dt <- merge(dt, ref_nb_cit, by = "id_ref")
  dt[, idf := log(nb_doc / nb_cit)]
  dt[, Rs := sum(nb_cit_entity * idf), by = entity]
  entity_nb_ref <- unique(dt[, list(entity, nb_ref, Rs)])

  # References cited by a single entity cannot create a tie
  dt <- dt[, nb_entity := .N, by = id_ref][nb_entity > 1]
  data.table::setkey(dt, id_ref, entity)

  # Pairs of entities with sparse matrices (see coupling_core()). The number
  # of shared references is the product of the entity x reference matrix. The
  # sum of min(C_Aj, C_Bj) w_j uses that min(a, b) is the number of levels
  # k = 1, 2... reached by both a and b: each cell (entity, reference) with C
  # citations is expanded in C cells (entity, reference-and-level k), and the
  # cross-product of this larger matrix sums w_j over the levels reached by
  # both entities, which is w_j min(C_Aj, C_Bj).
  entities <- sort(entity_nb_ref$entity)
  refs_kept <- unique(dt$id_ref)
  i <- match(dt$entity, entities)
  j <- match(dt$id_ref, refs_kept)
  counts <- sparse_product(i, j, rep(1, nrow(dt)), length(entities), length(refs_kept))

  levels_per_ref <- tapply(dt$nb_cit_entity, j, max)
  offset <- c(0, cumsum(levels_per_ref))[seq_along(levels_per_ref)]
  cell <- rep(seq_len(nrow(dt)), dt$nb_cit_entity)
  level <- sequence(dt$nb_cit_entity)
  cell_weight <- if (method == "coupling_angle") rep(1, length(cell)) else dt$idf[cell]
  min_sum <- sparse_product(i[cell], offset[j[cell]] + level, cell_weight,
                            length(entities), sum(levels_per_ref))

  bib_coup <- data.table::data.table(Source = entities[counts$i], Target = entities[counts$j],
                                     N = as.integer(counts$x), weight = match_pairs(counts, min_sum))
  max_shared <- if (nrow(bib_coup) > 0) max(bib_coup$N) else 0L
  bib_coup <- bib_coup[N >= weight_threshold]
  if (nrow(bib_coup) == 0) {
    warn_no_edges(
      max_shared, weight_threshold,
      none = "No two entities cite a same reference: nothing can be linked.",
      unit = "shared references",
      hint = "Check that {.arg entity} and {.arg ref} are the right columns, and that references have the same identifiers across documents."
    )
  }

  # Normalisation by the number of citations of the two entities
  bib_coup <- merge(bib_coup, entity_nb_ref, by.x = "Target", by.y = "entity")
  data.table::setnames(bib_coup, c("nb_ref", "Rs"), c("nb_ref_Target", "Rs_Target"))
  bib_coup <- merge(bib_coup, entity_nb_ref, by.x = "Source", by.y = "entity")
  data.table::setnames(bib_coup, c("nb_ref", "Rs"), c("nb_ref_Source", "Rs_Source"))
  if (method == "coupling_strength") {
    bib_coup[, weight := weight / (nb_ref_Target * nb_ref_Source)]
  } else if (method == "coupling_angle") {
    bib_coup[, weight := weight / sqrt(nb_ref_Target * nb_ref_Source)]
  } else {
    # S = 0 only if all the references are cited by all the documents: 0 / 0 is set to 0
    bib_coup[, weight := weight / sqrt(Rs_Target * Rs_Source)]
    bib_coup[is.nan(weight), weight := 0]
  }
  bib_coup[, Weighting_method := method]

  finalise_edges(bib_coup, last = "Weighting_method", output_in_character = output_in_character)
}
