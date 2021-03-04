coupling_entity <- function(dt, source, ref, entity, weight_threshold = 1, output_in_character = FALSE, method = c("coupling_strength","coupling_angle"))
{
  #' Creating Coupling Networks at Entity Level
  #'
  #' This function creates the edges of a network of entities from a direct citations data frame (i.e. documents citing references).
  #' Entities could be authors, affiliations, journals, _etc_. Consequently, coupling links are calculated using the coupling angle measure
  #' (like [biblio_coupling()]) or the coupling strength measure (like [coupling_strength()]. But it also takes into account the fact that
  #' an entity can cite several times a reference, and considers that citing 10 times a ref is more significant that citing it only once (see [details](#details)).
  #'
  #' @param dt
  #' The table with citing and cited documents.
  #'
  #' @param source
  #' The column name of the source identifiers, that is the documents that are citing.
  #'
  #' @param ref
  #' The column name of the cited references identifiers.
  #'
  #' @param entity
  #' The column name of the entity (authors, journals, institutions) that are citing.
  #'
  #' @param weight_threshold
  #' Corresponds to the value of the non-normalized weights of edges. The function just keeps the edges
  #' that have a non-normalized weight superior to the `weight_threshold`. In other words, if you set the
  #' parameter to 2, the function keeps only the edges between nodes that share at least two references
  #' in common in their bibliography. In a large bibliographic coupling network,
  #' you can consider for instance that sharing only one reference is not sufficient/significant
  #' for two entities (above all when large entities like journals and institutions) to be linked together.
  #' This parameter could also be modified to avoid creating intractable networks with too many edges.
  #'
  #' @param output_in_character
  #' If TRUE, the function ends by transforming the `from` and `to` columns in character, to make the
  #' creation of a [tidygraph](https://tidygraph.data-imaginist.com/index.html) network easier.
  #'
  #' @param method Choose the method you want to use for calculating the edges weights: either `"coupling_strength"` like in the
  #' [coupling_strength()] function, or `"coupling_angle"` like in the [biblio_coupling()] function.
  #'
  #' @details
  #' Coupling links are calculated depending of the number of references two authors (or any entity) share,
  #' taking into account the minimum number of times two authors are citing each references.
  #' For instance, if two entities share a reference in common, the first one citing it twice (in other words, citing it in two different articles),
  #' the second one three times, the function takes two as the minimum value. In addition to the features of the coupling strength measure (see [coupling_strength()])
  #' or the coupling angle measure (see [biblio_coupling()]), it means that, if two entities share two reference in common, if the first reference is cited
  #' at least four times by the two entities, whereas the second reference is cited at least only once, the first reference contributes more to the edge weight than
  #' the second reference. This use of minimum shared reference for entities coupling comes from \insertCite{zhao2008b;textual}{biblionetwork}. It looks like
  #' this for the coupling strength:
  #'
  #' \deqn{\frac{1}{L(A)}.\frac{1}{L(A)}\sum_{j} Min(C_{Aj},C_{Bj}).(log({\frac{N}{freq(R_{j})}}))}
  #'
  #' with \eqn{C_{Aj}} and \eqn{C_{Bj}} the number of time documents A and B cite the reference j.
  #'
  #' @return A data.table with the entity identifiers in `from` and `to` columns, with the coupling strength or coupling angle measures in
  #' another column, as well as the method used. It also keeps a copy of `from` and `to` in the `Source` and `Target` columns. This is useful is you
  #' are using the tidygraph package then, where `from` and `to` values are modified when creating a graph.
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
  #' @import data.table
  #' @import Rdpack

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  id_ref <- id_art <- N <- Source <- Target <- weight <- nb_cit <- . <- nb_ref_Target <- nb_ref_Source <- nb_ref <- nb_cit_entity <- nb_entity <- nb_cit <- nb_cit_entity_Target <- nb_cit_entity_Source <- NULL

  # Making sure the table is a datatable
  dt <- data.table(dt)

  # Renaming, calculating number of articles and simplifying
  setnames(dt, c(source,entity,ref), c("id_art","entity", "id_ref"))

  # Calculating the total number of articles in the data frame
  nb_doc <-  length(unique(dt[,id_art]))

  # Computing how many times each document is cited (by citing article, not by entity, to avoid double-counting)
  ref_nb_cit <-  unique(unique(dt[,c("id_art","id_ref")])[,list(nb_cit = .N),by=id_ref])

  # cleaning and setting the key
  dt <- dt[,list(entity,id_ref)]
  setkey(dt,id_ref,entity)

  # calculating the number of ref per-entity and the number of time a ref is cited by an entity
  dt <- unique(dt[, nb_ref := .N, by = "entity"][, nb_cit_entity := .N, by = c("entity","id_ref")])

  # calculating the number of entities citing a ref and removing refs cited by only one entity
  dt <- dt[,nb_entity := .N, by = id_ref][nb_entity > 1]

  # Creating every combinaison of articles per references
  dt_reduce <- dt[, list(entity,id_ref)]
  bib_coup <- dt_reduce[,list(Target = rep(entity[1:(length(entity)-1)],(length(entity)-1):1),
                              Source = rev(entity)[sequence((length(entity)-1):1)]),
                        by= id_ref]
  # remove loop
  bib_coup <- bib_coup[Source!=Target]
  # Inverse Source and Target so that couple of Source/Target are always on the same side
  bib_coup <- bib_coup[Source > Target, c("Target", "Source") := list(Source, Target)] # exchanging

  ###### Add columns with info for weighting
  #Calculating the number of references in common and deleting the links between articles that share less than weight_threshold
  bib_coup <- bib_coup[,N:= .N,by=list(Target,Source)][N>=weight_threshold]

  # nb_doc
  bib_coup[,nb_doc:=nb_doc]
  # merge the number of occurence of a ref in a document
  bib_coup <-  merge(bib_coup, ref_nb_cit, by = "id_ref")
  # merge the lenght of reference list
  bib_coup <-  merge(bib_coup, unique(dt[,c("entity","nb_ref")]), by.x = "Target",by.y = "entity" )
  setnames(bib_coup,"nb_ref", "nb_ref_Target")
  bib_coup <-  merge(bib_coup, unique(dt[,c("entity","nb_ref")]), by.x = "Source",by.y = "entity" )
  setnames(bib_coup,"nb_ref", "nb_ref_Source")

  # merge the number of times a ref is cited by an author
  bib_coup <-  merge(bib_coup, unique(dt[,c("entity","id_ref","nb_cit_entity")]), by.x = c("Target","id_ref"),by.y = c("entity","id_ref"))
  setnames(bib_coup,"nb_cit_entity", "nb_cit_entity_Target")
  bib_coup <-  merge(bib_coup, unique(dt[,c("entity","id_ref","nb_cit_entity")]), by.x = c("Source","id_ref"),by.y = c("entity","id_ref"))
  setnames(bib_coup,"nb_cit_entity", "nb_cit_entity_Source")

  # CS

  if(method == "coupling_strength"){
  bib_coup[,weight := (sum(min(nb_cit_entity_Target,nb_cit_entity_Source)*log(nb_doc/nb_cit))) / (nb_ref_Target*nb_ref_Source), .(Source,Target)]
  } else {
    bib_coup[,weight := sum(min(nb_cit_entity_Target,nb_cit_entity_Source))/sqrt(nb_ref_Target*nb_ref_Source), .(Source,Target)]
    }

  # copying the Source and Target columns in case of using Tidygraph later
  bib_coup[, `:=` (from = Source, to = Target, Weighting_method = method)]

  #Transforming in character
  if(output_in_character == TRUE){
    bib_coup$from <- as.character(bib_coup$from)
    bib_coup$to <- as.character(bib_coup$to)
  }

  bib_coup <- unique(bib_coup[, c("from","to","weight","Source","Target","Weighting_method")])

  return (bib_coup)

}
