coauth_network <- function(dt, authors, articles, method = c("full_counting","fractional_counting","fractional_counting_refined"), cosine_normalized = FALSE)
{
  #' Creating Co-Authorship Network with Different Measures for Weights
  #'
  #' @description This function creates an edge list for co-authorship networks from a data frame with a list of entities and their publications.
  #' The weight of edges can be calculated following different methods. The nodes of the network could be indifferently authors,
  #' institutions or countries.
  #'
  #' @details Weights can be calculated with:
  #' 1. the `"full_counting"` method: the linkds between authors correspond to their absolute number of collaborations.
  #' 1. the `"fractional_counting"` method which takes into account the number of authors in each article,
  #' following \insertCite{perianes-rodriguez2016b}{biblionetwork} equation:
  #' \deqn{\sum_{k = 1}^{M} \frac{a_{ik}.a_{jk}}{n_{k}-1}} with M the total number of articles, \eqn{a_{ik}.a_{jk}}
  #' which takes 1 if author i and j have co-written the article k, and \eqn{n_{k}} the number of authors for article k.
  #' 1. the `fractional_counting_refined` method, inspired by \insertCite{leydesdorff2017}{biblionetwork}
  #' which is similar to `fractional_counting` but which is formalised in a way
  #' that allows the sum of weights to equal the number of articles in the corpus: \deqn{\sum_{k = 1}^{M} \frac{a_{ik}.a_{jk}.2}{n_{k}.(n_{k}-1)}}.
  #'
  #' In addition, it is possible to take into account the total number of collaborations of two linked authors.
  #' If `cosine_normalized` is set to `True`, the weight calculated with one of the three methods above is divided by
  #' \eqn{\sqrt{C_{i}.C_{j}}}, with \eqn{C_{i}} being the number of articles co-written by author i.
  #'
  #' @param dt
  #' The data frame with authors (or institutions or countries) and the list of documents they have published.
  #'
  #' @param authors
  #' The column name of the source identifiers, that is the authors (or institutions or countries).
  #'
  #' @param articles
  #' The column name of the documents identifiers.
  #'
  #' @param method
  #' Method for calculating the edges weights, to be chosen among "full_counting","fractional_counting" or "fractional_counting_refined".
  #'
  #' @param cosine_normalized
  #' Possibility to take into account the total number of articles written by two linked authors and to normalize the weight of their link
  #' using Salton's cosine.
  #'
  #' @return A data.table with the authors (or institutions or countries) identifier in `from` and `to` columns, with a `weight` column
  #' whose values depend on the method chosen. It also keeps a copy of `from` and `to` in the `Source` and `Target` columns. This is useful is you
  #' are using the tidygraph package then, where `from` and `to` values are modified when creating a graph.
  #'
  #' @examples
  #' library(biblionetwork)
  #' coauth_network(Authors_stagflation,
  #' authors = "Author",
  #' articles = "ItemID_Ref",
  #' method = "fractional_counting")
  #'
  #' @references
  #' \insertAllCited{}
  #'
  #' @export
  #' @import data.table
  #' @import Rdpack


  # Listing the variables not in the global environment to avoid a "note" saying "no visible binding for global variable ..." when using check()
  # See https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  id_ref <- id_art <- N <- .N <- Source <- Target <- weight <- nb_art_Target <- nb_art_Source <- nb_auth <-  NULL

  # Making sure the table is a datatable
  dt <- data.table(dt)

  # Renaming and simplifying
  setnames(dt, c(authors,articles), c("authors", "articles"))
  dt <- dt[,c("authors","articles")]
  setkey(dt,authors,articles)

  # removing duplicated citations with exactly the same source and target
  dt <- unique(dt)

  # Removing articles with only one author:
  dt <- dt[,nb_auth := .N, by = articles][nb_auth > 1]

  # Calculating a "share" of contribution depending on the number of author
  nb_art <-  dt[, nb_art := .N, by = "authors"]

  # copying the file for later
  dt_reduce <- dt[,c("authors","articles")]

  #Creating every combinaison of articles per references
  coauth <- dt_reduce[,list(Target = rep(authors[1:(length(authors)-1)],(length(authors)-1):1),
                       Source = rev(authors)[sequence((length(authors)-1):1)]),
                 by= articles]

  # remove loop
  coauth <- coauth[Source!=Target]

  #Calculating the links between authors with the full counting method
  coauth <- coauth[,N := .N, by=c("Source","Target")]

  # We merge with the number of authors per article
  coauth <-  merge(coauth, unique(dt[,c("articles","nb_auth")]), by = "articles" )

  # using the standard fractionnal counting method or the refined one

  if(method == "full_counting"){
    coauth <- unique(coauth[, weight := N][,c("Source","Target","weight")])
  } else { if(method == "fractional_counting"){
    coauth <- unique(coauth[, weight := sum(1/(nb_auth-1)), c("Source","Target")][,c("Source","Target","weight")])
  } else {
    coauth <- unique(coauth[, weight := sum(2/(nb_auth*(nb_auth-1))), c("Source","Target")][,c("Source","Target","weight")])
  }
    }

  if(cosine_normalized == TRUE){
    coauth <-  merge(coauth, unique(nb_art[,c("authors","nb_art")]), by.x = "Target",by.y = "authors" )
    data.table::setnames(coauth,"nb_art", "nb_art_Target")
    coauth <-  merge(coauth, unique(nb_art[,c("authors","nb_art")]), by.x = "Source",by.y = "authors" )
    data.table::setnames(coauth,"nb_art", "nb_art_Source")
    coauth[,weight := weight/sqrt(nb_art_Target*nb_art_Source)][, c("Source","Target","weight")]
  }

  # copying the Source and Target columns in case of using Tidygraph later
  coauth <- coauth[, `:=` (from = Source, to = Target)][, c("from","to","weight","Source","Target")]

  return(coauth)
}
