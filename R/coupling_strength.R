coupling_strength <- function(dt, source, ref, weight_threshold = 1, output_in_character = TRUE)
{
  #' Calculating the Coupling Strength Measure for Edges
  #'
  #' @description
  #' This function calculates the coupling strength measure \insertCite{@following @vladutz1984 and @shen2019}{biblionetwork}
  #' from a direct citation data frame. It is a refinement of [biblio_coupling()]:
  #' it takes into account the frequency with which a reference shared by two articles has been cited in the whole corpus.
  #' In other words, the most cited references are less important in the links between two articles, than references that have
  #' been rarely cited. To a certain extent, it is similar to the \href{https://en.wikipedia.org/wiki/Tf%E2%80%93idf}{tf-idf} measure.
  #'
  #' @param dt
  #' The data frame with citing and cited documents.
  #'
  #' @param source
  #' the column name of the source identifiers, that is the documents that are citing.
  #'
  #' @param ref
  #'the column name of the references that are cited.
  #'
  #' @param weight_threshold
  #' Corresponds to the value of the non-normalized weights of edges. The function just keeps the edges
  #' that have a non-normalized weight superior to the `weight_threshold`. In other words, if you set the
  #' parameter to 2, the function keeps only the edges between nodes that share at least two references
  #' in common in their bibliography. In a large bibliographic coupling network,
  #' you can consider for instance that sharing only one reference is not sufficient/significant for two articles to be linked together.
  #' This parameter could also be modified to avoid creating intractable networks with too many edges.
  #'
  #' @param output_in_character
  #' If TRUE, the function ends by transforming the `from` and `to` columns in character, to make the
  #' creation of a [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph easier.
  #'
  #' @return A data.table with the articles identifiers in `from` and `to` columns, with the coupling strength measure in
  #' another column. It also keeps a copy of `from` and `to` in the `Source` and `Target` columns. This is useful is you
  #' are using the tidygraph package then, where `from` and `to` values are modified when creating a graph.
  #'
  #' @examples
  #' library(biblionetwork)
  #' coupling_strength(Ref_stagflation,
  #' source = "Citing_ItemID_Ref",
  #' ref = "ItemID_Ref")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export
  #' @import data.table
  #' @import Rdpack
  #'

  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  id_ref <- id_art <- N <- Source <- Target <- weight <- nb_cit <- . <- nb_ref_Target <- nb_ref_Source <- NULL

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

  # Computing how many items each citing document has (necessary for normalization later)
  id_nb_ref <-  dt[,list(nb_ref = .N),by=id_art]

  # Removing references cited only once:
  dt <- dt[,N := .N, by = id_ref][N > 1][, list(id_art,id_ref)]

  # Computing how many times each reference is cited
  ref_nb_cit <-  dt[,list(nb_cit = .N),by=id_ref]

  # Computing the total number of documents in the corpus.
  nb_doc <-  dt[unique(id_art)][,list(n_document = .N)]

  # Creating every combinaison of articles per references
  bib_coup <- dt[,list(Target = rep(id_art[1:(length(id_art)-1)],(length(id_art)-1):1),
                       Source = rev(id_art)[sequence((length(id_art)-1):1)]),
                 by= id_ref]

  # remove loop
  bib_coup <- bib_coup[Source!=Target]

  # Inverse Source and Target so that couple of Source/Target are always on the same side
  bib_coup <- unique(bib_coup[Source > Target, c("Target", "Source") := list(Source, Target)]) # exchanging

  ###### Add columns with info for weighting
  #Calculating the number of references in common and deleting the links between articles that share less than weight_threshold
  bib_coup <- bib_coup[,N:= .N,by=list(Target,Source)][N>=weight_threshold]

  # integrating the number of documents
  bib_coup[,nb_doc:=nb_doc]

  # merge the number of occurence of a ref in a document
  bib_coup <-  merge(bib_coup, ref_nb_cit, by = "id_ref")

  # merge the lenght of reference list
  bib_coup <-  merge(bib_coup, id_nb_ref, by.x = "Target",by.y = "id_art" )
  setnames(bib_coup,"nb_ref", "nb_ref_Target")
  bib_coup <-  merge(bib_coup, id_nb_ref, by.x = "Source",by.y = "id_art" )
  setnames(bib_coup,"nb_ref", "nb_ref_Source")

  # CS
  bib_coup[,weight := (sum(log(nb_doc/nb_cit))) / (nb_ref_Target*nb_ref_Source), .(Source,Target)]

  # Keep only unique couple
  bib_coup <- unique(bib_coup)

  # copying the Source and Target columns in case of using Tidygraph later
  bib_coup[, `:=` (from = Source, to = Target)]

  #Transforming in character
  if(output_in_character == TRUE){
      bib_coup$from <- as.character(bib_coup$from)
      bib_coup$to <- as.character(bib_coup$to)
  }

 return (unique(bib_coup[, c("from","to","weight","Source","Target")]))

  }

