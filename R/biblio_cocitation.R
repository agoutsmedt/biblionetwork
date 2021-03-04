biblio_cocitation <- function(dt, source, ref, normalized_weight_only=TRUE, weight_threshold = 1, output_in_character = TRUE)
{
  #' Calculating the Coupling Angle Measure for Edges in a Co-citation Network
  #'
  #' @description This function is basically the same as the [biblio_coupling()] function but it is explicitly framed
  #' for bibliographic co-citation network (and not for bibliographic coupling networks). It takes a data frame
  #' with direct citations, and calculates the number of times two references are citing together, and calculate a measure
  #' similar to the coupling angle value \insertCite{sen1983}{biblionetwork}: it divides the number of times two references are
  #' cited together by the square root of the product of the total number of citations (in the whole corpus) of each reference.
  #' The more two references are cited in general, the more they have to be cited together for their link to be important.
  #'
  #' @details This function uses data.table package and is thus very fast. It allows the user to compute the coupling angle
  #' on a very large data frame quickly.
  #'
  #' @param dt
  #' The dataframe with citing and cited documents.
  #'
  #' @param source
  #' The column name of the source identifiers, that is the documents that are citing.
  #'
  #' @param ref
  #' The column name of the cited references identifiers. In co-citation network, these references are the nodes of the network.
  #'
  #' @param normalized_weight_only
  #' If set to FALSE, the function returns the weights normalized by the cosine measure,
  #' but also simply the number of times two references are cited together.
  #'
  #' @param weight_threshold
  #' Correspond to the value of the non-normalized weights of edges. The function just keeps the edges
  #' that have a non-normalized weight superior to the `weight_threshold`. In a large bibliographic co-citation network,
  #' you can consider for instance that being cited only once together is not sufficient/significant for two references to be linked together.
  #' This parameter could also be modified to avoid creating intractable networks with too many edges.
  #'
  #' @param output_in_character
  #' If TRUE, the function ends by transforming the `from` and `to` columns in character, to make the
  #' creation of a [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph easier.
  #'
  #' @return A data.table with the articles (or authors) identifier in `from` and `to` columns,
  #' with one or two additional columns (the coupling angle measure and
  #' the number of shared references). It also keeps a copy of `from` and `to` in the `Source` and `Target` columns. This is useful is you
  #' are using the tidygraph package then, where `from` and `to` values are modified when creating a graph.
  #'
  #' @examples
  #' library(biblionetwork)
  #' biblio_cocitation(Ref_stagflation,
  #' source = "Citing_ItemID_Ref",
  #' ref = "ItemID_Ref")
  #'
  #' # It is basically the same as:
  #' biblio_coupling(Ref_stagflation,
  #' source = "ItemID_Ref",
  #' ref = "Citing_ItemID_Ref")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export
  #' @import data.table
  #' @import Rdpack


  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  id_ref <- id_art <- N <- .N <- Source <- Target <- weight <- nb_cit_Target <- nb_cit_Source <- NULL

  # Making sure the table is a datatable
  dt <- data.table(dt)

  # Renaming and simplifying
  setnames(dt, c(source,ref), c("id_art", "id_ref"))
  dt <- dt[,c("id_art","id_ref")]
  setkey(dt,id_ref,id_art)

  # removing duplicated citations with exactly the same source and target
  dt <- unique(dt)

  # remove loop
  dt <- dt[id_art!=id_ref]

  # Computing how many items a reference is cited
  id_nb_cit <-  dt[,list(nb_cit = .N),by=id_ref]

  # Removing articles with only one reference in the bibliography:
  dt <- dt[,N := .N, by = id_art][N > 1][, list(id_art,id_ref)]

  #Creating every combinaison of articles per references
  bib_cocit <- dt[,list(Target = rep(id_ref[1:(length(id_ref)-1)],(length(id_ref)-1):1),
                       Source = rev(id_ref)[sequence((length(id_ref)-1):1)]),
                 by= id_art]

  # remove loop
  bib_cocit <- bib_cocit[Source!=Target]

  # Inverse Source and Target so that couple of Source/Target are always on the same side
  bib_cocit <- unique(bib_cocit[Source > Target, c("Target", "Source") := list(Source, Target)]) # exchanging and checking for doublons

  #Calculating the weight
  bib_cocit <- bib_cocit[,.N,by=list(Target,Source)] # This is the number of go references

  # keeping edges over threshold
  bib_cocit <- bib_cocit[N>=weight_threshold]

  # We than do manipulations to normalize this number with the cosine measure
  bib_cocit <-  merge(bib_cocit, id_nb_cit, by.x = "Target",by.y = "id_ref" )
  data.table::setnames(bib_cocit,"nb_cit", "nb_cit_Target")
  bib_cocit <-  merge(bib_cocit, id_nb_cit, by.x = "Source",by.y = "id_ref" )
  data.table::setnames(bib_cocit,"nb_cit", "nb_cit_Source")
  bib_cocit[,weight := N/sqrt(nb_cit_Target*nb_cit_Source)] # cosine measure

  # Renaming columns
  data.table::setnames(bib_cocit, c("N"),
                       c("nb_shared_citations"))

  # Transforming the Source and Target columns in character (and keeping the Source and Target in copy)
  # Then selection which columns to return
  if(output_in_character == TRUE){
    bib_cocit$from <- as.character(bib_cocit$Source)
    bib_cocit$to <- as.character(bib_cocit$Target)
    if(normalized_weight_only==TRUE){
      bib_cocit[, c("from","to","weight","Source","Target")]
    } else {
      bib_cocit[, c("from","to","weight","nb_shared_citations","Source","Target")]
    }
  } else{
    if(normalized_weight_only==TRUE){
      bib_cocit[, c("Source","Target","weight")]
    } else {
      bib_cocit[, c("Source","Target","weight","nb_shared_references")]
    }
  }

}
