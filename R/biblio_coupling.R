biblio_coupling <- function(dt, source, ref, normalized_weight_only=TRUE, weight_threshold = 1, output_in_character = TRUE)
{
  #' Calculating The Coupling Angle Measure For Edges
  #'
  #' @description This function calculates the number of references that different articles share together, as well as
  #' the coupling angle value of edges in a bibliographic coupling network \insertCite{sen1983}{biblionetwork}, from a direct
  #' citation data frame. This is a standard way to build bibliographic coupling network using Salton's cosine measure:
  #' it divides the number of references that two articles share by the rootsquare of the product of
  #' both articles bibliography lengths. It avoids giving too much importance to articles with a large bibliography.
  #'
  #' @details This function uses data.table package and is thus very fast. It allows the user to compute the coupling angle
  #' on a very large dataframe very quickly.
  #'
  #' This function is a relatively general function that can also be used
  #' 1. for co-citation networks (just by inversing the `source` and `ref` columns).
  #' If you want to avoid confusion, rather use the `biblio_cocit` function.
  #' 1. for title co-occurence networks (taking care of
  #' the lenght of the title thanks to the coupling angle measure);
  #' 1. for co-authorship networks (taking care of the
  #' number of co-authors an author has collaborated with on a period). For co-authorship,
  #' rather use the `coauth_network` function.
  #'
  #' @param dt
  #' For bibliographic coupling (or co-citation), the dataframe with citing and cited documents. It could also be used
  #' 1) for title co-occurence network, with `source` being the articles,
  #' and `ref` being the list of words in articles titles;
  #' 2) for co-authorship network,
  #' with `source` being the authors, and `ref` the list of articles.
  #'
  #' @param source
  #' the column name of the source identifiers, that is the documents that are citing. In coupling network, these documents
  #' are the nodes of the network.
  #'
  #' @param ref
  #'the column name of the cited references identifiers.
  #'
  #' @param normalized_weight_only
  #' if set to FALSE, the function returns the weights normalized by the cosine measure,
  #' but also simply the number of shared references.
  #'
  #' @param weight_threshold
  #' Correspond to the value of the non-normalized weights of edges. The function just keeps the edges
  #' that have a non-normalized weight superior to the `weight_threshold`. In a large bibliographic coupling network,
  #' you can consider for instance that sharing only one reference is not sufficient/significant for two articles to be linked together.
  #' This parameter could also be modified to avoid creating untractable networks with too many edges.
  #'
  #' @param output_in_character
  #' If TRUE, the function ends by transforming the `from` and `to` columns in character, to make the
  #' creation of a [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph easier.
  #'
  #' @return A data.table with the articles (or authors) identifier in `from` and `to` columns, with one or two additional columns (the coupling angle measure and
  #' the number of shared references). It also keeps a copy of `from` and `to` in the `Source` and `Target` columns. This is useful is you
  #' are using the tidygraph package then, where `from` and `to` values are modified when creating a graph.
  #'
  #' @examples
  #' library(biblionetwork)
  #' biblio_coupling(Ref_stagflation,
  #' source = "Citing_ItemID_Ref",
  #' ref = "ItemID_Ref",
  #' weight_threshold = 3)
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
  dt <- data.table::data.table(dt)

  # Renaming and simplifying
  data.table::setnames(dt, c(source,ref), c("id_art", "id_ref"))
  dt <- dt[,c("id_art","id_ref")]
  data.table::setkey(dt,id_ref,id_art)

  # removing duplicated citations with exactly the same source and target
  dt <- unique(dt)

  # remove loop
  dt <- dt[id_art!=id_ref]

  # Computing how many items each citing document has (necessary for normalization later)
  id_nb_cit <-  dt[,list(nb_cit = .N),by=id_art]

  # Removing references cited only once:
  dt <- dt[,N := .N, by = id_ref][N > 1][, list(id_art,id_ref)]

  #Creating every combinaison of articles per references
  bib_coup <- dt[,list(Target = rep(id_art[1:(length(id_art)-1)],(length(id_art)-1):1),
                       Source = rev(id_art)[sequence((length(id_art)-1):1)]),
                 by= id_ref]

  # remove loop
  bib_coup <- bib_coup[Source!=Target]

  # Inverse Source and Target so that couple of Source/Target are always on the same side
  bib_coup <- unique(bib_coup[Source > Target, c("Target", "Source") := list(Source, Target)]) # exchanging and checking for doublons

  #Calculating the weight
  bib_coup <- bib_coup[,.N,by=list(Target,Source)] # This is the number of go references

  # keeping edges over threshold
  bib_coup <- bib_coup[N>=weight_threshold]

  # We than do manipulations to normalize this number with the cosine measure
  bib_coup <-  merge(bib_coup, id_nb_cit, by.x = "Target",by.y = "id_art" )
  data.table::setnames(bib_coup,"nb_cit", "nb_cit_Target")
  bib_coup <-  merge(bib_coup, id_nb_cit, by.x = "Source",by.y = "id_art" )
  data.table::setnames(bib_coup,"nb_cit", "nb_cit_Source")
  bib_coup[,weight := N/sqrt(nb_cit_Target*nb_cit_Source)] # cosine measure

  # Renaming columns
  data.table::setnames(bib_coup, c("N"),
           c("nb_shared_references"))

  # Transforming the Source and Target columns in character (and keeping the Source and Target in copy)
  # Then selection which columns to return
  if(output_in_character == TRUE){
    bib_coup$from <- as.character(bib_coup$Source)
    bib_coup$to <- as.character(bib_coup$Target)
    if(normalized_weight_only==TRUE){
      bib_coup[, c("from","to","weight","Source","Target")]
    } else {
      bib_coup[, c("from","to","weight","nb_shared_references","Source","Target")]
    }
  } else{
    if(normalized_weight_only==TRUE){
      bib_coup[, c("Source","Target","weight")]
    } else {
      bib_coup[, c("Source","Target","weight","nb_shared_references")]
    }
  }

}

