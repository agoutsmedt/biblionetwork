# Bibliographic coupling edges using the titles of the references (DescriptiveBC)

The *DescriptiveBC* measure of (Liu 2017) . In the standard
bibliographic coupling, two references are either the same or completely
different. Here two *different* references can be partly similar if
their titles share words, so that two documents can be coupled even if
they cite few identical references.

## Usage

``` r
coupling_descriptive(
  dt,
  source,
  ref,
  title,
  targets = NULL,
  min_weight = 0,
  output_in_character = TRUE,
  stopwords = NULL,
  max_documents = 5000
)
```

## Arguments

- dt:

  A data frame or a `data.table` of direct citations, one row per link
  between a citing document and a cited reference. It is not modified.

- source:

  Character scalar. The column of the citing documents: they are the
  nodes of the coupling network.

- ref:

  Character scalar. The column of the cited references.

- title:

  Character scalar. The column with the title of the cited reference
  (one title per reference).

- targets:

  Optional vector of identifiers of documents (values of `source`). If
  given, only the pairs involving at least one target are computed.

- min_weight:

  Number. Only pairs with a weight strictly above it are returned (0 by
  default: all the pairs with some similarity). There is no
  `weight_threshold` here, since two documents need not share any
  reference.

- output_in_character:

  Logical. If `TRUE` (default), the identifiers are also returned as
  character columns `from` and `to`, to build a
  [tidygraph](https://tidygraph.data-imaginist.com/index.html) graph
  more easily.

- stopwords:

  Character vector of words to ignore in the titles (`NULL`: none).

- max_documents:

  Number. The maximum number of documents allowed without `targets`.

## Value

A `data.table` with one row per pair of documents with a weight above
`min_weight`: `from` and `to` (character if
`output_in_character = TRUE`), the `weight`, and the original
identifiers in `Source` and `Target` (`Source < Target`).

## Details

**\[experimental\]**

The similarity of two references \\r_1\\ and \\r_2\\ is 1 if they are
the same reference, and otherwise the Jaccard index of the sets of terms
of their titles, \\\mathrm{Sim}(r_1, r_2) = \|T(r_1) \cap T(r_2)\| /
\|T(r_1) \cup T(r_2)\|\\. The weight between documents \\A\\ and \\B\\,
with reference sets \\R_A\\ and \\R_B\\, is

\$\$w\_{AB} = \frac{\sum\_{r \in R_A} \max\_{r' \in R_B} \mathrm{Sim}(r,
r') + \sum\_{r' \in R_B} \max\_{r \in R_A} \mathrm{Sim}(r,
r')}{\|R_A\| + \|R_B\|}\$\$

(Eq. 5 of the paper). It lies between 0 and 1. If no two references are
similar except identical ones, it is \\2 \|R_A \cap R_B\| / (\|R_A\| +
\|R_B\|)\\, the Dice coefficient of the bibliographies.

Terms are the words of the titles, in lower case, without the
`stopwords` that you give (for instance `stopwords::stopwords("en")`):
without them, words such as "the" or "of" create similarities between
unrelated titles. The paper does not specify other pre-processing (no
stemming here). A reference without title is only similar to itself. If
a reference has several titles in the table, the first is used, with a
warning.

*Computing cost.* Unlike the other coupling measures, there is no
natural set of candidate pairs: two documents sharing no reference can
be similar through the words of the titles. All the pairs of documents
are therefore potentially concerned, and the cost grows with the square
of the number of documents. The function (i) computes the similarity of
the pairs of references sharing a term with sparse matrices, and (ii)
for each target document, finds the best matches of its references. With
a very large corpus, give the `targets` (the documents for which you
want the neighbours, as in the paper, where each article is compared
with candidates) or restrict the corpus by time windows. Removing stop
words reduces the number of similar references a lot. By default, more
than `max_documents` documents without `targets` is an error.

## Why use it in research

Two papers on the same question often cite different but related works
(the same idea in a working paper and in a journal article, two papers
on the same model). Classical coupling misses them, and the sparsity of
citations makes it dominated by a few shared references (Liu 2017) .
Using the words of the titles of the references recovers part of this
relatedness. It also lets you say *why* two documents are related: see
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md).
The price is a dependence on the quality of the titles (language,
abbreviations, missing titles) and a much higher computing cost, since
almost any two documents can have some similarity (see below). Liu
evaluates the measure on biomedical articles, against expert judgements
of relatedness: check on your own field that title words are informative
(in the social sciences titles are often metaphorical).

## Intuition

Imagine that you compare two reading lists, and that you are allowed to
match each book of the first list with its *closest* book in the second:
the same book is a perfect match (1), a book whose title shares half of
its words is a half match, unrelated titles do not match (0). The
measure is the average quality of the best matches, in both directions.

## References

Liu R (2017). “A New Bibliographic Coupling Measure with Descriptive
Capability.” *Scientometrics*, **110**(2), 915–935.
[doi:10.1007/s11192-016-2196-7](https://doi.org/10.1007/s11192-016-2196-7)
.

## See also

Other coupling measures:
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md),
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md),
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md),
[`descriptive_terms()`](https://agoutsmedt.github.io/biblionetwork/reference/descriptive_terms.md)

## Examples

``` r
library(biblionetwork)
# a and b cite different references, with partly shared title words
toy <- data.frame(
  doc = c("a", "a", "b", "b"),
  ref = c("r1", "r2", "r1", "r3"),
  title = c("inflation expectations", "oil supply shocks",
            "inflation expectations", "supply shocks prices")
)
# 1 for r1; r2 and r3 share 2 of 4 terms: w = (1 + 0.5 + 1 + 0.5) / 4
coupling_descriptive(toy, source = "doc", ref = "ref", title = "title")
#>      from     to weight Source Target
#>    <char> <char>  <num> <char> <char>
#> 1:      a      b   0.75      a      b
```
