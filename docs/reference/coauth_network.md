# Co-authorship edges, with full or fractional counting

Builds the edges of a co-authorship network from a table with one row
per author (or institution, or country) and document. Two authors are
linked when they have co-signed documents. The weight of the tie can
count each collaboration fully, or share it between the pairs of
co-authors of a document (*fractional counting*), following
(Perianes-Rodriguez et al. 2016; Leydesdorff and Park 2017-02) , and can
be normalised by the productivity of the two authors with a cosine.

## Usage

``` r
coauth_network(
  dt,
  authors,
  articles,
  method = c("full_counting", "fractional_counting", "fractional_counting_refined"),
  cosine_normalized = FALSE
)
```

## Arguments

- dt:

  A data frame or a `data.table` with one row per author and document.
  It is not modified.

- authors:

  Character scalar. The column of the authors (or institutions, or
  countries), the nodes of the network.

- articles:

  Character scalar. The column of the documents.

- method:

  `"full_counting"` (default), `"fractional_counting"` or
  `"fractional_counting_refined"` (see the details).

- cosine_normalized:

  Logical. If `TRUE`, divides the weight by the geometric mean of the
  numbers of co-authored documents of the two authors (Salton's cosine).

## Value

A `data.table` with one row per pair of authors: `from` and `to` (copies
of `Source` and `Target`, with the type of the `authors` column), the
`weight`, and the original identifiers in `Source` and `Target`. Each
pair appears once, with `Source > Target` (the orientation of the
previous versions of the package).

## Details

**\[experimental\]**

Write \\a\_{ik} = 1\\ if author \\i\\ signed document \\k\\, and \\n_k =
\sum_i a\_{ik}\\ for its number of authors. The weight of the tie
between \\i\\ and \\j\\ is, according to `method`:

- `"full_counting"`: the number of documents they co-signed, \$\$w\_{ij}
  = \sum\_{k} a\_{ik} a\_{jk}\$\$

- `"fractional_counting"` (Perianes-Rodriguez et al. 2016) : each
  document gives \\1/(n_k - 1)\\ to each pair, \$\$w\_{ij} = \sum\_{k}
  \frac{a\_{ik} a\_{jk}}{n_k - 1}\$\$ so that the weights of the ties of
  an author in a document sum to 1;

- `"fractional_counting_refined"`, inspired by (Leydesdorff and Park
  2017-02) : each document gives \\2 / (n_k (n_k - 1))\\ to each pair,
  \$\$w\_{ij} = \sum\_{k} \frac{2 \\ a\_{ik} a\_{jk}}{n_k (n_k - 1)}\$\$
  so that each document has a total weight of 1 in the network: the sum
  of all the weights equals the number of (multi-authored) documents.

If `cosine_normalized = TRUE`, the weight is divided by \\\sqrt{P_i
P_j}\\, with \\P_i\\ the number of co-authored documents of author \\i\\
(documents with a single author are ignored in the whole function, since
they create no tie).

Duplicated rows are counted once, rows with a missing identifier are
dropped with a warning, the table of the user is not modified, and a
zero-row table is returned, with a warning, if nobody co-authored a
document.

## Why use it in research

Co-authorship networks describe the social structure of a research
community: who collaborates with whom, the existence of collaborative
cliques, the central or bridging positions. The way collaborations are
counted changes the picture. With full counting, a document signed by
ten authors creates 45 ties of weight 1 and weighs much more in the
network than a document signed by two authors; fractional counting
corrects this by giving a document a total weight that does not depend
on its number of authors. Normalising by productivity prevents very
prolific authors from being linked to everybody. Perianes-Rodriguez et
al. (Perianes-Rodriguez et al. 2016) compare full and fractional
counting for bibliometric networks: read it before choosing. The nodes
can be authors, institutions or countries, the latter being the basis of
studies of international collaboration.

## Intuition

Think of each document as a pie of value 1 to share among the pairs of
its authors. With full counting, every pair of co-authors receives a
full pie: a document with ten authors distributes 45 pies, a document
with two authors distributes one. With fractional counting, a document
always distributes the same total (one pie in the refined version, or
one pie per author in the other), so that large collaborations do not
dominate. The cosine then asks whether two authors collaborate much
*relative to* how much each of them collaborates in general.

## References

Leydesdorff L, Park HW (2017-02). “Full and Fractional Counting in
Bibliometric Networks.” *Journal of Informetrics*, **11**(1), 117–120.
ISSN 17511577.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716303133>.  
  
Perianes-Rodriguez A, Waltman L, Van Eck NJ (2016). “Constructing
Bibliometric Networks: A Comparison between Full and Fractional
Counting.” *Journal of Informetrics*, **10**(4), 1178–1195.
<https://www.sciencedirect.com/science/article/pii/S1751157716302036?casa_token=AtzjmZ-1QmYAAAAA:2mlBPZsjGUleYi9mnybHODFw2RmMh3GHvRAuMYXygRm63cQOv07M4ixbAmJXuGq71tx2ug29baTp>.

## See also

Other co-citation and co-authorship measures:
[`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md)

## Examples

``` r
library(biblionetwork)
coauth_network(Authors_stagflation,
               authors = "Author",
               articles = "ItemID_Ref",
               method = "fractional_counting")
#>              from            to weight        Source        Target
#>            <char>        <char>  <num>        <char>        <char>
#>  1:       CHARI-V    ALBANESI-S   0.50       CHARI-V    ALBANESI-S
#>  2:  CHRISTIANO-L    ALBANESI-S   0.50  CHRISTIANO-L    ALBANESI-S
#>  3:  CHRISTIANO-L       CHARI-V   1.00  CHRISTIANO-L       CHARI-V
#>  4:   CUKIERMAN-A     BRUNNER-K   0.50   CUKIERMAN-A     BRUNNER-K
#>  5:  EICHENBAUM-M       CHARI-V   0.50  EICHENBAUM-M       CHARI-V
#>  6:  EICHENBAUM-M  CHRISTIANO-L   0.50  EICHENBAUM-M  CHRISTIANO-L
#>  7: EICHENGREEN-B       BORDO-M   1.00 EICHENGREEN-B       BORDO-M
#>  8:      EUSEPI-S     BULLARD-J   1.00      EUSEPI-S     BULLARD-J
#>  9:      FARMER-R       BEYER-A   1.00      FARMER-R       BEYER-A
#> 10:  FITZGERALD-T  CHRISTIANO-L   1.00  FITZGERALD-T  CHRISTIANO-L
#> 11:        GALI-J   BLANCHARD-O   1.00        GALI-J   BLANCHARD-O
#> 12:        GALI-J     CLARIDA-R   0.50        GALI-J     CLARIDA-R
#> 13:     GERTLER-M    BERNANKE-B   0.50     GERTLER-M    BERNANKE-B
#> 14:     GERTLER-M     CLARIDA-R   0.50     GERTLER-M     CLARIDA-R
#> 15:     GERTLER-M        GALI-J   0.50     GERTLER-M        GALI-J
#> 16:     GOODWIN-T      GISSER-M   1.00     GOODWIN-T      GISSER-M
#> 17:      GORDON-R        FRYE-J   2.00      GORDON-R        FRYE-J
#> 18:        GUST-C  CHRISTIANO-L   1.00        GUST-C  CHRISTIANO-L
#> 19: HALTIWANGER-J       DAVIS-S   1.00 HALTIWANGER-J       DAVIS-S
#> 20:      HOOPER-P   CECCHETTI-S   0.25      HOOPER-P   CECCHETTI-S
#> 21:     JACKMAN-R       GRUBB-D   0.50     JACKMAN-R       GRUBB-D
#> 22:      KASMAN-B   CECCHETTI-S   0.25      KASMAN-B   CECCHETTI-S
#> 23:      KASMAN-B      HOOPER-P   0.25      KASMAN-B      HOOPER-P
#> 24:      KILIAN-L      BARSKY-R   2.00      KILIAN-L      BARSKY-R
#> 25:        KING-R  GOODFRIEND-M   1.00        KING-R  GOODFRIEND-M
#> 26:      LAYARD-R       GRUBB-D   0.50      LAYARD-R       GRUBB-D
#> 27:      LAYARD-R     JACKMAN-R   0.50      LAYARD-R     JACKMAN-R
#> 28:       LIPPI-F   CUKIERMAN-A   1.00       LIPPI-F   CUKIERMAN-A
#> 29:      MANKIW-G        BALL-L   1.00      MANKIW-G        BALL-L
#> 30:    MCGREGOR-R    CHAPPELL-H   1.00    MCGREGOR-R    CHAPPELL-H
#> 31:     MELTZER-A     BRUNNER-K   0.50     MELTZER-A     BRUNNER-K
#> 32:     MELTZER-A   CUKIERMAN-A   0.50     MELTZER-A   CUKIERMAN-A
#> 33:        MORK-K        HALL-R   2.00        MORK-K        HALL-R
#> 34:      NELSON-E     DICECIO-C   1.00      NELSON-E     DICECIO-C
#> 35:      PAPELL-D    NIKOLSKO-R   1.00      PAPELL-D    NIKOLSKO-R
#> 36:   PESAVENTO-E     HERRERA-A   1.00   PESAVENTO-E     HERRERA-A
#> 37:      RASCHE-R       POOLE-W   0.50      RASCHE-R       POOLE-W
#> 38:       ROMER-D       ROMER-C   2.00       ROMER-D       ROMER-C
#> 39:        RUDD-J     BLINDER-A   1.00        RUDD-J     BLINDER-A
#> 40:       SACHS-J       BRUNO-M   3.00       SACHS-J       BRUNO-M
#> 41:     SARGENT-T      COGLEY-T   3.00     SARGENT-T      COGLEY-T
#> 42: SCHOENHOLTZ-K   CECCHETTI-S   0.25 SCHOENHOLTZ-K   CECCHETTI-S
#> 43: SCHOENHOLTZ-K      HOOPER-P   0.25 SCHOENHOLTZ-K      HOOPER-P
#> 44: SCHOENHOLTZ-K      KASMAN-B   0.25 SCHOENHOLTZ-K      KASMAN-B
#> 45:        SILL-K       LEDUC-S   0.50        SILL-K       LEDUC-S
#> 46:       STARK-T       LEDUC-S   0.50       STARK-T       LEDUC-S
#> 47:       STARK-T        SILL-K   0.50       STARK-T        SILL-K
#> 48:      STRAUB-R    BILBIIE-FO   1.00      STRAUB-R    BILBIIE-FO
#> 49:       TATOM-J      RASCHE-R   1.00       TATOM-J      RASCHE-R
#> 50:      TAYLOR-J       LEVIN-A   1.00      TAYLOR-J       LEVIN-A
#> 51:     TINSLEY-P     KOZICKI-S   1.00     TINSLEY-P     KOZICKI-S
#> 52:      WATSON-M    BERNANKE-B   0.50      WATSON-M    BERNANKE-B
#> 53:      WATSON-M   CECCHETTI-S   0.25      WATSON-M   CECCHETTI-S
#> 54:      WATSON-M     GERTLER-M   0.50      WATSON-M     GERTLER-M
#> 55:      WATSON-M      HOOPER-P   0.25      WATSON-M      HOOPER-P
#> 56:      WATSON-M      KASMAN-B   0.25      WATSON-M      KASMAN-B
#> 57:      WATSON-M SCHOENHOLTZ-K   0.25      WATSON-M SCHOENHOLTZ-K
#> 58:    WHEELOCK-D       POOLE-W   0.50    WHEELOCK-D       POOLE-W
#> 59:    WHEELOCK-D      RASCHE-R   0.50    WHEELOCK-D      RASCHE-R
#> 60:    WILLIAMS-J  ORPHANIDES-A   3.00    WILLIAMS-J  ORPHANIDES-A
#> 61:    WILLIAMS-N     SARGENT-T   0.50    WILLIAMS-N     SARGENT-T
#> 62:    WOODFORD-M   ROTEMBERG-J   1.00    WOODFORD-M   ROTEMBERG-J
#> 63:         ZHA-T     SARGENT-T   0.50         ZHA-T     SARGENT-T
#> 64:         ZHA-T    WILLIAMS-N   0.50         ZHA-T    WILLIAMS-N
#>              from            to weight        Source        Target
#>            <char>        <char>  <num>        <char>        <char>

# Toy example: three authors sign document 1, two sign document 2.
# With fractional counting, a-b gets 1/2 + 1/1 = 1.5
toy <- data.frame(author = c("a", "b", "c", "a", "b"),
                  paper = c(1, 1, 1, 2, 2))
coauth_network(toy, authors = "author", articles = "paper",
               method = "fractional_counting")
#>      from     to weight Source Target
#>    <char> <char>  <num> <char> <char>
#> 1:      b      a    1.5      b      a
#> 2:      c      a    0.5      c      a
#> 3:      c      b    0.5      c      b
```
