entity_network <- function(dt, source, ref, entity, network = c("coupling", "cocitation"), method = c("angle", "strength", "similarity", "jaccard", "vladutz"), weight_threshold = 1, output_in_character = FALSE)
{
  #' Aggregate a coupling or co-citation network at the level of entities
  #'
  #' `r lifecycle::badge("experimental")`
  #'
  #' @description
  #' Builds the edges of a coupling (or co-citation) network whose nodes are
  #' not documents but *entities* that aggregate documents: authors, journals,
  #' institutions, countries... It is not a new measure of proximity: it takes
  #' the measures of [biblio_coupling()] (or of [biblio_cocitation()]) and
  #' computes them for entities instead of documents. Since an entity
  #' publishes several documents, it can cite the same reference several
  #' times, and the function takes this into account: citing a reference ten
  #' times is more significant than citing it once. The counts are combined
  #' with the *minimum rule* of \insertCite{zhao2008b;textual}{biblionetwork}.
  #'
  #' @section Why use it in research:
  #' Coupling at the level of authors (author bibliographic coupling,
  #' \insertCite{zhao2008b}{biblionetwork}), journals or institutions maps
  #' who relies on the same literature, whatever the documents they publish.
  #' With `network = "cocitation"`, it maps which authors, journals or
  #' institutions are cited together, as in author co-citation analysis. It is
  #' a way to study the structure of a discipline through its journals or its
  #' authors, with fewer and denser nodes than the document-level network.
  #' Because entities are aggregates of documents, check that they are not too
  #' heterogeneous (a generalist journal citing everything is coupled with
  #' everyone), and that the number of documents per entity is large enough to
  #' give a stable bibliography. An article with several authors appears once
  #' for each of its authors: the same document then contributes to several
  #' entities.
  #'
  #' @section Intuition:
  #' Think of an entity (say a journal) as one big bibliography made of the
  #' bibliographies of all its documents, in which a reference appears as many
  #' times as the entity's documents cite it. Two journals are close when their
  #' big bibliographies overlap. Overlap is measured reference by reference by
  #' the *smaller* of the two counts: if journal A cites a reference 10 times and
  #' journal B twice, they share it twice (B is the limit). The methods then
  #' differ in what they do with these overlaps, as their document-level
  #' counterparts: `"angle"` only counts them and normalises by the sizes of the
  #' two big bibliographies; `"strength"` counts a shared rare reference more
  #' than a shared classic; `"similarity"` does the same but normalises by the
  #' "informational size" of each big bibliography, to give a cosine that
  #' cannot exceed 1; `"jaccard"` compares the overlap with the union of the
  #' two big bibliographies; `"vladutz"` discounts popular references steeply.
  #'
  #' @details
  #' Write \eqn{C_{Aj}} for the number of times entity \eqn{A} cites reference
  #' \eqn{j} (the number of its documents citing \eqn{j}), \eqn{N} for the
  #' number of citing documents in the table, \eqn{f_j} for the number of
  #' documents citing \eqn{j}, and \eqn{L(A) = \sum_j C_{Aj}} for the
  #' total number of citations made by \eqn{A}. Write also
  #' \eqn{m_{AB}(g) = \sum_{j} \min(C_{Aj}, C_{Bj}) \, g_j}, the overlap of the
  #' two entities, with the references weighted by \eqn{g_j}. According to
  #' `method`, the weight of the tie between \eqn{A} and \eqn{B} is
  #'
  #' * `"angle"`, with \eqn{g_j = 1}:
  #'   \deqn{w_{AB} = \frac{m_{AB}(1)}{\sqrt{L(A) \, L(B)}}}
  #' * `"strength"`, with \eqn{g_j = \log(N / f_j)}:
  #'   \deqn{w_{AB} = \frac{m_{AB}(g)}{L(A) \, L(B)}}
  #' * `"similarity"`, with \eqn{g_j = \log(N / f_j)} and
  #'   \eqn{S(A) = \sum_j C_{Aj} \log(N / f_j)}:
  #'   \deqn{w_{AB} = \frac{m_{AB}(g)}{\sqrt{S(A) \, S(B)}}}
  #' * `"jaccard"`, with \eqn{g_j = 1}:
  #'   \deqn{w_{AB} = \frac{m_{AB}(1)}{L(A) + L(B) - m_{AB}(1)}}
  #'   which is the ratio of the sum of the minima to the sum of the maxima of
  #'   the counts (the weighted Jaccard index);
  #' * `"vladutz"`, with \eqn{g_j = 1 / f_j}:
  #'   \deqn{w_{AB} = \frac{4 \, m_{AB}(g)}{L(A) + L(B)}}
  #'
  #' The sums run over the references cited by both entities, and \eqn{L}, \eqn{S}
  #' over all the references of the entity. The minimum of the two counts is
  #' the number of times the two entities cite the reference "together"
  #' \insertCite{zhao2008b}{biblionetwork}. The package follows the paper for
  #' the minimum rule with the coupling angle and strength; the other methods
  #' are the *same extension*, applied to the measures of
  #' [coupling_similarity()], [coupling_jaccard()] and [coupling_vladutz()]
  #' (the similarity is still bounded by 1, since
  #' \eqn{\min(C_{Aj}, C_{Bj}) \leq \sqrt{C_{Aj} C_{Bj}}} and by the
  #' Cauchy-Schwarz inequality). With a single citation per entity and
  #' reference, each method gives back the document-level measure. \eqn{f_j}
  #' counts citing documents, not entities, so that a document with several
  #' authors is not counted several times. References cited by a single entity
  #' cannot create a tie and are ignored in the overlaps, but they count in
  #' \eqn{L}.
  #'
  #' **Co-citation.** With `network = "cocitation"`, the roles of `source` and
  #' `ref` are swapped, as in [biblio_cocitation()]: the nodes are the entities
  #' of the *cited* references, and the `entity` column must describe `ref`
  #' (the author or the journal of the cited reference). Two entities are
  #' co-cited when documents cite references of both. The formulas above apply
  #' with the roles exchanged: \eqn{C_{Aj}} is the number of references of
  #' \eqn{A} cited by document \eqn{j}.
  #'
  #' The `weight_threshold` applies to the number of references shared by two
  #' entities (each counted once, whatever the number of times it is cited).
  #' The table of the user is not modified, rows with a missing identifier are
  #' dropped with a warning, and a zero-row table is returned, with a warning, if no reference
  #' is shared (or if no pair reaches `weight_threshold`). The memory warning
  #' of [coupling_strength()] applies.
  #'
  #' @inheritParams coupling_angle
  #' @param source Character scalar. The column of the citing documents.
  #'   Needed to count the documents, not to define the nodes (except for
  #'   `network = "cocitation"`, see the details).
  #' @param ref Character scalar. The column of the cited references.
  #' @param entity Character scalar. The column of the entities that are the
  #'   nodes of the network (authors, journals, institutions...). With
  #'   `network = "coupling"` it describes the citing documents (`source`); with
  #'   `network = "cocitation"` it describes the cited references (`ref`). A
  #'   document can appear with several entities (one row per entity and
  #'   reference).
  #' @param network `"coupling"` (default): the entities are linked when their
  #'   documents cite the same references. `"cocitation"`: they are linked when
  #'   their references are cited by the same documents.
  #' @param method The weighting method, one of `"angle"` (default),
  #'   `"strength"`, `"similarity"`, `"jaccard"` and `"vladutz"`: see the
  #'   details, and [biblio_coupling()] for their document-level versions.
  #' @param weight_threshold Number. The minimum number of shared references
  #'   for two entities to be linked (1 by default). With large entities such
  #'   as journals, a higher value is advisable.
  #' @param output_in_character Logical. If `TRUE`, `from` and `to` are
  #'   character columns (`FALSE` by default for this function: they keep the
  #'   type of the entity column).
  #'
  #' @return A `data.table` with one row per pair of entities: `from`, `to`,
  #'   the `weight`, the original identifiers in `Source` and `Target`, and the
  #'   `Weighting_method` (the `method`). Each pair appears once, with `Source < Target`.
  #'
  #' @family entity networks
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
  #' entity_network(entity_citations,
  #'                 source = "Citing_ItemID_Ref",
  #'                 ref = "ItemID_Ref",
  #'                 entity = "Author.y",
  #'                 method = "angle")
  #'
  #' # The same entities, linked when the documents of one cite the references of the other
  #' # (nodes: the journals of the cited references, a column of Ref_stagflation)
  #' head(entity_network(Ref_stagflation, source = "Citing_ItemID_Ref", ref = "ItemID_Ref",
  #'                     entity = "Journal", network = "cocitation", weight_threshold = 2))
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  id_ref <- id_art <- N <- Source <- Target <- weight <- nb_cit <- nb_ref <- nb_ref_Target <- nb_ref_Source <-
    nb_cit_entity <- nb_entity <- nb_cit_entity_Target <- nb_cit_entity_Source <- contribution <- Weighting_method <- idf <- inv_freq <- Rs <- Rs_Target <- Rs_Source <- NULL

  method <- rlang::arg_match(method)
  network <- rlang::arg_match(network)
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
  # Co-citation is coupling with the roles of source and ref swapped: the
  # "documents" are then the cited references (which carry the entity)
  if (network == "cocitation") {
    data.table::setnames(dt, c(ref, entity, source), c("id_art", "entity", "id_ref"))
  } else {
    data.table::setnames(dt, c(source, entity, ref), c("id_art", "entity", "id_ref"))
  }
  factors_to_character(dt, c("id_art", "entity", "id_ref"))
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
  dt[, inv_freq := 1 / nb_cit]
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
  # g_j: the weight given to a reference in the overlap (see the details)
  cell_weight <- switch(method,
                        angle = , jaccard = rep(1, length(cell)),
                        strength = , similarity = dt$idf[cell],
                        vladutz = dt$inv_freq[cell])
  min_sum <- sparse_product(i[cell], offset[j[cell]] + level, cell_weight,
                            length(entities), sum(levels_per_ref))

  bib_coup <- data.table::data.table(Source = entities[counts$i], Target = entities[counts$j],
                                     N = as.integer(counts$x), weight = match_pairs(counts, min_sum))
  max_shared <- if (nrow(bib_coup) > 0) max(bib_coup$N) else 0L
  bib_coup <- bib_coup[N >= weight_threshold]
  if (nrow(bib_coup) == 0) {
    warn_no_edges(
      max_shared, weight_threshold,
      none = if (network == "coupling") "No two entities cite a same reference: nothing can be linked." else "No two entities are cited by a same document: nothing can be linked.",
      unit = "shared references",
      hint = "Check that {.arg entity} and {.arg ref} are the right columns, and that references have the same identifiers across documents."
    )
  }

  # Normalisation by the number of citations of the two entities
  bib_coup <- merge(bib_coup, entity_nb_ref, by.x = "Target", by.y = "entity")
  data.table::setnames(bib_coup, c("nb_ref", "Rs"), c("nb_ref_Target", "Rs_Target"))
  bib_coup <- merge(bib_coup, entity_nb_ref, by.x = "Source", by.y = "entity")
  data.table::setnames(bib_coup, c("nb_ref", "Rs"), c("nb_ref_Source", "Rs_Source"))
  bib_coup[, weight := switch(
    method,
    angle = weight / sqrt(nb_ref_Target * nb_ref_Source),
    strength = weight / (nb_ref_Target * nb_ref_Source),
    # S = 0 only if all the references are cited by all the documents: 0 / 0 is set to 0
    similarity = {
      w <- weight / sqrt(Rs_Target * Rs_Source)
      w[is.nan(w)] <- 0
      w
    },
    jaccard = weight / (nb_ref_Target + nb_ref_Source - weight),
    vladutz = 4 * weight / (nb_ref_Target + nb_ref_Source)
  )]
  bib_coup[, Weighting_method := method]

  finalise_edges(bib_coup, last = "Weighting_method", output_in_character = output_in_character)
}
