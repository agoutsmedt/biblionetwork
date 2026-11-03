# How to use biblionetwork

This vignette is a guided tour of the functions of `biblionetwork`,
using the data included in the package (see [Section 1](#sec-data)).
Every function turns a **table of links between two kinds of items**
(for instance documents and the references they cite) into the **edges
of a network** whose nodes are one of the two kinds, with a weight for
each edge. The functions differ by the kind of nodes and by the way the
weight is computed.

``` r
library(biblionetwork)
library(data.table)
```

| You want to link… | Because they… | Function |
|----|----|----|
| citing documents | share references ([Kessler 1963](#ref-kessler1963)) | [`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md) (see [Section 2](#sec-coupling)) |
| cited references | are cited together ([Small 1973](#ref-small1973)) | [`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md) (see [Section 3](#sec-cocitation)) |
| authors, journals, institutions | cite the same references (or are cited together) through their documents ([Zhao and Strotmann 2008](#ref-zhao2008b)) | [`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md) (see [Section 4](#sec-entity)) |
| authors, institutions, countries | co-sign documents | [`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md) (see [Section 5](#sec-coauthorship)) |

Table 1: Which function for which network?

## The data included in the package

The package contains bibliometric data built by Goutsmedt
([2021](#ref-goutsmedt2021a)): the academic articles and books,
published between 1975 and 2013, that tried to explain the US
stagflation of the 1970s, and the references they cite.

- `Ref_stagflation` is a table of **direct citations**: one row per link
  between a citing document (`Citing_ItemID_Ref`) and a cited document
  (`ItemID_Ref`). It is the typical input of the coupling and
  co-citation functions.
- `Nodes_stagflation` describes the stagflation documents, and the
  references cited by at least two of them (one row per document, with
  the first author only).
- `Authors_stagflation` lists the stagflation documents with *all* their
  authors (one row per author and document). It is the input of the
  co-authorship function.

``` r
Ref_stagflation[1:5, 1:2]
```

    #>    Citing_ItemID_Ref ItemID_Ref
    #>                <int>      <int>
    #> 1:        1111111131 1111111354
    #> 2:          20623867   49263876
    #> 3:          25850485      72060
    #> 4:          16995857     202546
    #> 5:         106566088     209143

Every function of the package needs only **two columns of identifiers**,
that you name in the arguments `source` and `ref`. The names of the
columns in your own data do not matter, and the table you give is never
modified.

## Bibliographic coupling: `biblio_coupling()`

Two documents are *bibliographically coupled* when they cite the same
references ([Kessler 1963](#ref-kessler1963)): the more their
bibliographies overlap, the more likely they are to address related
questions.
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md)
takes a table of direct citations and returns the list of the pairs of
documents that share at least one reference, with a weight for each
pair.

``` r
edges <- biblio_coupling(Ref_stagflation,
                         source = "Citing_ItemID_Ref",
                         ref = "ItemID_Ref",
                         normalized_weight_only = FALSE)
edges
```

    #>             from         to     weight nb_shared_references     Source
    #>           <char>     <char>      <num>                <int>      <int>
    #>    1:    1021902    1184127 0.04622502                    1    1021902
    #>    2:     214927    2207578 0.14605935                    4     214927
    #>    3:    1184127    2901822 0.04233338                    1    1184127
    #>    4:    1184130    2901822 0.05184758                    1    1184130
    #>    5:    1717556    2901822 0.02804964                    1    1717556
    #>   ---
    #> 2712: 1111111122 1111111183 0.05572782                    1 1111111122
    #> 2713: 1111111134 1111111183 0.04256283                    1 1111111134
    #> 2714: 1111111146 1111111183 0.05212860                    1 1111111146
    #> 2715: 1111111161 1111111183 0.04050542                    2 1111111161
    #> 2716: 1111111182 1111111183 0.27060404                    8 1111111182
    #>           Target
    #>            <int>
    #>    1:    1184127
    #>    2:    2207578
    #>    3:    2901822
    #>    4:    2901822
    #>    5:    2901822
    #>   ---
    #> 2712: 1111111183
    #> 2713: 1111111183
    #> 2714: 1111111183
    #> 2715: 1111111183
    #> 2716: 1111111183

The output is an **edge list**:

- `from` and `to` are the identifiers of the two documents (as
  characters, which is what graph packages such as `tidygraph` expect;
  set `output_in_character = FALSE` to skip them);
- `weight` is the weight of the tie;
- `nb_shared_references` is the number of references the two documents
  share. It is displayed only if `normalized_weight_only = FALSE`;
- `Source` and `Target` keep the original identifiers (with their
  original type). Each pair appears once, with `Source < Target`: the
  network is undirected.

### The default weight: the coupling angle

By default, the weight is the **coupling angle** (or cosine) of Sen and
Gan ([1983](#ref-sen1983)), the standard way of normalising coupling. It
divides the number of references two documents share by the geometric
mean of the lengths of their bibliographies:

w\_{AB} = \frac{\|R(A) \cap R(B)\|}{\sqrt{L(A) \\ L(B)}}

where R(A) is the set of references of document A, \|R(A) \cap R(B)\|
the number of references shared by A and B, and L(A) = \|R(A)\| the
length of the bibliography of A. Without the denominator, a literature
review with 200 references would be linked to almost everybody, simply
because it cites a lot. The weight lies between 0 (nothing in common)
and 1 (identical bibliographies). The same measure is available under
its own name,
[`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md),
which is what
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md)
calls when you do not choose another `method`.

> **What counts as the length of a bibliography?**
>
> L(A) counts *all* the references of A present in your table, including
> those that no other document cites. They cannot create a tie, but they
> make the bibliography longer, and so they lower the weights of A. If
> you want to ignore them, remove them from the table before calling the
> function.

### Choosing the minimal number of shared references

In a large corpus, sharing a single reference is weak evidence that two
documents are related, and keeping all such pairs produces very dense
networks. `weight_threshold` sets the minimal number of shared
references for a pair to be kept. It applies to the *number of shared
references*, not to the normalised weight.

``` r
biblio_coupling(Ref_stagflation,
                source = "Citing_ItemID_Ref",
                ref = "ItemID_Ref",
                weight_threshold = 3)
```

    #>            from         to     weight     Source     Target
    #>          <char>     <char>      <num>      <int>      <int>
    #>   1:     214927    2207578 0.14605935     214927    2207578
    #>   2:    5160307    6714008 0.09128709    5160307    6714008
    #>   3:    1717556    7815498 0.16564729    1717556    7815498
    #>   4:     214927    8456979 0.09733285     214927    8456979
    #>   5:    2207578    8456979 0.11846978    2207578    8456979
    #>  ---
    #> 958:   39858452 1111111180 0.06596992   39858452 1111111180
    #> 959:  151268764 1111111180 0.09464970  151268764 1111111180
    #> 960:    1021902 1111111183 0.08674724    1021902 1111111183
    #> 961:  106566092 1111111183 0.05710402  106566092 1111111183
    #> 962: 1111111182 1111111183 0.27060404 1111111182 1111111183

Raising the threshold is also the simplest way to keep a network
tractable.

> **Very popular references and memory**
>
> The functions first list the pairs of documents that cite a same
> reference. A reference cited by n documents creates n(n-1)/2 pairs: a
> classic cited by 50,000 documents creates more than a billion of them.
> The package uses sparse matrices to keep this under control, but very
> popular references can still exhaust the memory of your computer on a
> large corpus. Split the corpus (by time window, for instance) or
> remove the most cited references before building the network.

### Other weights: the `method` argument

The coupling angle gives the same importance to every shared reference.
But two documents that both cite a classic cited by half of the corpus
are not as clearly related as two documents that both cite an obscure
article. Several measures take this into account, in the spirit of the
[tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf) weighting of
information retrieval ([Spärck Jones 1972](#ref-sparckjones1972)). They
are all available through the `method` argument of
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
and each has its own function:

| `method` | Function | Intuition |
|----|----|----|
| `"angle"` (default) | [`coupling_angle()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_angle.md) | Shared references relative to the length of the two bibliographies (a cosine) ([Sen and Gan 1983](#ref-sen1983)). |
| `"jaccard"` | [`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md) | Of everything the two documents cite, the share they both cite ([Sen and Gan 1983](#ref-sen1983)). |
| `"strength"` | [`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md) | A shared *rare* reference counts more than a shared classic ([Vladutz and Cook 1984](#ref-vladutz1984); [Shen et al. 2019](#ref-shen2019)). |
| `"similarity"` | [`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md) | The same idea, as a cosine bounded by 1 ([Shen et al. 2019](#ref-shen2019)). |
| `"vladutz"` | [`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md) | A shared reference counts 1/f_j: a very steep discount of popular references ([Vladutz and Cook 1984](#ref-vladutz1984)). |

Table 2: The weights of document coupling

In the formulas below, N is the number of citing documents in the table
and f_j the number of documents that cite the reference j (its
*frequency*): the weight \log(N/f_j) of a reference is the inverse
document frequency (idf), high for rare references and close to zero for
references cited by almost everybody.

**Coupling strength** ([Shen et al. 2019](#ref-shen2019)) sums the idf
of the shared references, and divides by the lengths of the two
bibliographies:

w\_{AB} = \frac{1}{L(A) \\ L(B)} \sum\_{j \in R(A) \cap R(B)}
\log\left(\frac{N}{f_j}\right)

Use it when a few references are cited by most documents of your corpus
(the classics of the field): sharing them says little about the
proximity of two documents. The price is a measure that depends on the
whole corpus, and whose scale (it is not bounded by 1) is not comparable
across corpora.

``` r
biblio_coupling(Ref_stagflation,
                source = "Citing_ItemID_Ref",
                ref = "ItemID_Ref",
                method = "strength",
                weight_threshold = 3)
```

    #>            from         to      weight     Source     Target
    #>          <char>     <char>       <num>      <int>      <int>
    #>   1:     214927    2207578 0.020008623     214927    2207578
    #>   2:    5160307    6714008 0.010611749    5160307    6714008
    #>   3:    1717556    7815498 0.035262345    1717556    7815498
    #>   4:     214927    8456979 0.011939901     214927    8456979
    #>   5:    2207578    8456979 0.012807897    2207578    8456979
    #>  ---
    #> 958:   39858452 1111111180 0.005118578   39858452 1111111180
    #> 959:  151268764 1111111180 0.007465000  151268764 1111111180
    #> 960:    1021902 1111111183 0.006925280    1021902 1111111183
    #> 961:  106566092 1111111183 0.002896722  106566092 1111111183
    #> 962: 1111111182 1111111183 0.038292193 1111111182 1111111183

**Coupling similarity** ([Shen et al. 2019](#ref-shen2019), Eq. 8) is
the idf-weighted cosine. Each document is described by the
“informational size” of its bibliography, S(A) = \sum\_{j \in R(A)}
\log(N/f_j), and

w\_{AB} = \frac{\sum\_{j \in R(A) \cap R(B)} \log(N/f_j)}{\sqrt{S(A) \\
S(B)}}

It generalises the coupling angle (if all the references had the same
idf, we would get the angle back) and is bounded by 1.

``` r
coupling_similarity(Ref_stagflation,
                    source = "Citing_ItemID_Ref",
                    ref = "ItemID_Ref",
                    weight_threshold = 3)
```

    #>            from         to     weight     Source     Target
    #>          <char>     <char>      <num>      <int>      <int>
    #>   1:     214927    2207578 0.12438825     214927    2207578
    #>   2:    5160307    6714008 0.07382317    5160307    6714008
    #>   3:    1717556    7815498 0.13924311    1717556    7815498
    #>   4:     214927    8456979 0.08470689     214927    8456979
    #>   5:    2207578    8456979 0.09897134    2207578    8456979
    #>  ---
    #> 958:   39858452 1111111180 0.05799043   39858452 1111111180
    #> 959:  151268764 1111111180 0.07948371  151268764 1111111180
    #> 960:    1021902 1111111183 0.05330234    1021902 1111111183
    #> 961:  106566092 1111111183 0.03780964  106566092 1111111183
    #> 962: 1111111182 1111111183 0.24285542 1111111182 1111111183

The two other measures are mostly useful for comparison.
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md)
divides the number of shared references by the size of the *union* of
the two bibliographies, and penalises more strongly pairs of
bibliographies of very different lengths.
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md)
implements the first formula that discounted popular references
([Vladutz and Cook 1984](#ref-vladutz1984)), which Shen et al.
([2019](#ref-shen2019)) later corrected with the idf.

### Comparing the measures on your corpus

The measures do not have the same scale, so their weights cannot be
compared directly, but their distributions and rankings can.
[`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md)
computes several measures at once (listing the pairs of documents only
once), and
[`summarise_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/summarise_weights.md),
[`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md),
[`overlap_top_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/overlap_top_weights.md),
[`merge_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/merge_weights.md)
and
[`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md)
compare them.

``` r
measures <- compute_couplings(Ref_stagflation,
                              source = "Citing_ItemID_Ref",
                              ref = "ItemID_Ref",
                              weight_threshold = 2)
# Rank correlation between the measures (1 = the same ranking of the pairs)
round(correlate_weights(measures), 2)
```

    #>            angle strength similarity jaccard vladutz
    #> angle       1.00     0.85       0.96    0.98    0.69
    #> strength    0.85     1.00       0.90    0.81    0.73
    #> similarity  0.96     0.90       1.00    0.94    0.84
    #> jaccard     0.98     0.81       0.94    1.00    0.70
    #> vladutz     0.69     0.73       0.84    0.70    1.00
    #> attr(,"n_pairs")
    #> [1] 1501

Whether the choice of the measure matters on your corpus, which pairs of
documents the measures disagree on, and how the communities change is
the subject of [the vignette on comparing
measures](https://agoutsmedt.github.io/biblionetwork/articles/comparing_measures.md).

## Co-citation: `biblio_cocitation()`

Coupling links the documents that *cite*; co-citation links the
documents that are *cited*: two references are co-cited when a same
document cites both ([Small 1973](#ref-small1973)). It is the mirror
image of coupling, and it is obtained by swapping the roles of the two
columns.
[`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md)
does the swap for you: the citing documents stay in `source` and the
references in `ref`, and the nodes of the network are the references.

``` r
biblio_cocitation(Ref_stagflation,
                  source = "Citing_ItemID_Ref",
                  ref = "ItemID_Ref",
                  weight_threshold = 2)
```

    #>             from         to    weight     Source     Target
    #>           <char>     <char>     <num>      <int>      <int>
    #>    1:     181882     214939 0.2121320     181882     214939
    #>    2:     214931     214939 0.2581989     214931     214939
    #>    3:     181882     364710 0.3162278     181882     364710
    #>    4:     214939     364710 0.2236068     214939     364710
    #>    5:     181483     364716 0.6123724     181483     364716
    #>   ---
    #> 4495:   51129176 1111112159 1.0000000   51129176 1111112159
    #> 4496: 1111111579 1111112159 1.0000000 1111111579 1111112159
    #> 4497: 1111111590 1111112159 1.0000000 1111111590 1111112159
    #> 4498: 1111111595 1111112159 1.0000000 1111111595 1111112159
    #> 4499: 1111111802 1111112159 1.0000000 1111111802 1111112159

You get the same result by hand with
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
by inverting the two columns:

``` r
by_hand <- biblio_coupling(Ref_stagflation,
                           source = "ItemID_Ref",
                           ref = "Citing_ItemID_Ref",
                           weight_threshold = 2)
all.equal(by_hand, biblio_cocitation(Ref_stagflation,
                                     source = "Citing_ItemID_Ref",
                                     ref = "ItemID_Ref",
                                     weight_threshold = 2))
```

    #> [1] TRUE

[`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md)
also has a `method` argument, with the same measures as coupling. There
is a difference of interpretation, though: coupling ties are fixed once
the documents are published (they depend only on their own
bibliographies), whereas co-citation ties change as new documents cite
the references. Coupling is therefore better suited to comparing
successive time windows, and co-citation to describing how a literature
is perceived at a given moment.

## Aggregating at the level of entities: `entity_network()`

You may want to link authors, institutions or journals rather than
documents. This is not a different kind of network, nor a different
measure: it is the *same* coupling (or co-citation), computed for
entities that aggregate documents. An entity publishes several documents
and can cite the same reference several times.
[`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md)
takes this into account: for each reference shared by two entities, it
counts the **minimum** number of times the two entities cite it ([Zhao
and Strotmann 2008](#ref-zhao2008b)). If one author cites a reference in
two of their articles and another in three, the reference counts for
two.

The consequence is that a reference that two entities cite repeatedly
contributes more to the tie than a reference each of them cites once.
With the coupling strength, the weight is

w\_{AB} = \frac{1}{L(A) \\ L(B)} \sum\_{j} \min(C\_{Aj}, C\_{Bj}) \\
\log\left(\frac{N}{f_j}\right)

where C\_{Aj} and C\_{Bj} are the numbers of times A and B cite the
reference j, L(A) is the total number of citations made by A, N the
number of citing documents and f_j the number of documents citing j. The
`method` argument accepts the same methods as
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md)
(`"angle"`, `"strength"`, `"similarity"`, `"jaccard"` and `"vladutz"`),
each adapted with the minimum rule (see
[`?entity_network`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md)
for the formulas), and the `network` argument chooses between
`"coupling"` (entities that cite the same references) and `"cocitation"`
(entities whose references are cited together, as in author co-citation
analysis).

The input needs one row per citation *and* per entity: we merge the
table of direct citations with the table of authors. A document with
several authors appears several times, hence `allow.cartesian = TRUE`.

``` r
entity_citations <- merge(Ref_stagflation,
                          Authors_stagflation,
                          by.x = "Citing_ItemID_Ref",
                          by.y = "ItemID_Ref",
                          allow.cartesian = TRUE)

entity_network(entity_citations,
               source = "Citing_ItemID_Ref",
               ref = "ItemID_Ref",
               entity = "Author.y",
               method = "angle")
```

    #>             from         to      weight     Source     Target Weighting_method
    #>           <char>     <char>       <num>     <char>     <char>           <char>
    #>    1: ALBANESI-S     BALL-L 0.048592953 ALBANESI-S     BALL-L            angle
    #>    2: ALBANESI-S   BARSKY-R 0.063021872 ALBANESI-S   BARSKY-R            angle
    #>    3: ALBANESI-S    BEYER-A 0.034585723 ALBANESI-S    BEYER-A            angle
    #>    4: ALBANESI-S BILBIIE-FO 0.064282435 ALBANESI-S BILBIIE-FO            angle
    #>    5: ALBANESI-S    BORDO-M 0.043519414 ALBANESI-S    BORDO-M            angle
    #>   ---
    #> 3461: WILLIAMS-J WILLIAMS-N 0.028213825 WILLIAMS-J WILLIAMS-N            angle
    #> 3462: WILLIAMS-J    YOUNG-W 0.008748736 WILLIAMS-J    YOUNG-W            angle
    #> 3463: WILLIAMS-J      ZHA-T 0.028213825 WILLIAMS-J      ZHA-T            angle
    #> 3464: WILLIAMS-N      ZHA-T 1.000000000 WILLIAMS-N      ZHA-T            angle
    #> 3465: WOODFORD-M    YOUNG-W 0.020672456 WOODFORD-M    YOUNG-W            angle

For a co-citation network of entities, the `entity` column must describe
the *cited* reference (the author or the journal of the cited document)
rather than the citing one. Here, the journals of the cited documents:

``` r
entity_network(Ref_stagflation,
                    source = "Citing_ItemID_Ref",
                    ref = "ItemID_Ref",
                    entity = "Journal",
                    network = "cocitation",
                    weight_threshold = 3)
```

    #> Warning: Dropping 738 rows with a missing identifier.

    #>                    from                   to    weight            Source
    #>                  <char>               <char>     <num>            <char>
    #>    1: 15 EUR CENTR BANK          AM ECON REV 0.1513300 15 EUR CENTR BANK
    #>    2: 15 EUR CENTR BANK CARNEGIE-ROCHESTER C 0.2773501 15 EUR CENTR BANK
    #>    3: 15 EUR CENTR BANK             ECON INQ 0.6546537 15 EUR CENTR BANK
    #>    4: 15 EUR CENTR BANK      J MONETARY ECON 0.1568125 15 EUR CENTR BANK
    #>    5: 15 EUR CENTR BANK MONETARY POLICY RULE 0.2672612 15 EUR CENTR BANK
    #>   ---
    #> 1010:    REV ECON DYNAM        REV ECON STAT 0.2433321    REV ECON DYNAM
    #> 1011:    REV ECON DYNAM        REV ECON STUD 0.3746343    REV ECON DYNAM
    #> 1012:     REV ECON STAT        REV ECON STUD 0.2525907     REV ECON STAT
    #> 1013:     REV ECON STUD STUDIES BUSINESS CYC 0.3535534     REV ECON STUD
    #> 1014:     REV ECON STUD  UNPUB WHY INFLATION 0.3535534     REV ECON STUD
    #>                     Target Weighting_method
    #>                     <char>           <char>
    #>    1:          AM ECON REV            angle
    #>    2: CARNEGIE-ROCHESTER C            angle
    #>    3:             ECON INQ            angle
    #>    4:      J MONETARY ECON            angle
    #>    5: MONETARY POLICY RULE            angle
    #>   ---
    #> 1010:        REV ECON STAT            angle
    #> 1011:        REV ECON STUD            angle
    #> 1012:        REV ECON STUD            angle
    #> 1013: STUDIES BUSINESS CYC            angle
    #> 1014:  UNPUB WHY INFLATION            angle

## Co-authorship: `coauth_network()`

Co-authorship links the authors (or institutions, or countries) who sign
documents together. You could build it with
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md),
authors being the `source` and documents the `ref`, but coupling is not
designed for it: what matters here is how to **count a collaboration**.
[`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md)
offers three ways, and an optional normalisation by the productivity of
the authors.

To see what they do, take a toy example: three authors, a, b and c, sign
document 1; a and b sign document 2.

``` r
toy <- data.frame(author = c("a", "b", "c", "a", "b"),
                  paper  = c(1, 1, 1, 2, 2))
```

**Full counting** (`"full_counting"`) gives one point to each pair of
authors for each document they co-sign. The weight is the number of
co-signed documents. Here a–b gets 2 points, and a–c and b–c one point
each. The problem is that big collaborations weigh more: a document with
ten authors creates 45 pairs, so it adds 45 points to the network,
whereas a document with two authors adds one.

``` r
coauth_network(toy, authors = "author", articles = "paper", method = "full_counting")
```

    #>      from     to weight Source Target
    #>    <char> <char>  <num> <char> <char>
    #> 1:      b      a      2      b      a
    #> 2:      c      a      1      c      a
    #> 3:      c      b      1      c      b

**Fractional counting** (`"fractional_counting"`) shares the value of a
document among the co-authors, so that a large collaboration does not
dominate ([Perianes-Rodriguez, Waltman, and Van Eck
2016](#ref-perianes-rodriguez2016b)). A document with n authors gives
1/(n-1) to each pair of its authors, so that the weights of all the ties
of an author in this document sum to one: each author “spends” one unit
of collaboration per document, split among the co-authors. In the toy
example, document 1 has three authors, so each of its three pairs
receives 1/2; document 2 has two authors, so a–b receives 1. The weight
of a–b is 1/2 + 1 = 1.5, and that of a–c and b–c is 1/2: the pair that
collaborated in a small team is worth more than a pair in a large team.
Perianes-Rodriguez, Waltman, and Van Eck
([2016](#ref-perianes-rodriguez2016b)) compare full and fractional
counting on bibliometric networks, and show that the choice changes the
picture.

``` r
coauth_network(toy, authors = "author", articles = "paper", method = "fractional_counting")
```

    #>      from     to weight Source Target
    #>    <char> <char>  <num> <char> <char>
    #> 1:      b      a    1.5      b      a
    #> 2:      c      a    0.5      c      a
    #> 3:      c      b    0.5      c      b

**Refined fractional counting** (`"fractional_counting_refined"`),
inspired by Leydesdorff and Park ([2017-02](#ref-leydesdorff2017)), goes
one step further: each *document*, rather than each author, has a total
weight of one in the network. A document with n authors creates n(n-1)/2
pairs, so each pair gets 2/(n(n-1)). Document 1 gives 1/3 to each of its
three pairs (3 \times 1/3 = 1) and document 2 gives 1 to a–b. The weight
of a–b is 1/3 + 1 \approx 1.33. The sum of all the weights of the
network is then the number of co-authored documents.

``` r
coauth_network(toy, authors = "author", articles = "paper", method = "fractional_counting_refined")
```

    #>      from     to    weight Source Target
    #>    <char> <char>     <num> <char> <char>
    #> 1:      b      a 1.3333333      b      a
    #> 2:      c      a 0.3333333      c      a
    #> 3:      c      b 0.3333333      c      b

In all cases, documents with a single author are ignored, since they
create no tie.

**Normalising by productivity.** Prolific authors have many
collaborations simply because they publish a lot. With
`cosine_normalized = TRUE`, the weight is divided by \sqrt{P_i P_j},
where P_i is the number of co-authored documents of author i (Salton’s
cosine, as for the coupling angle). The weight then measures whether two
authors collaborate a lot *relative to* how much each of them
collaborates in general. In the toy example, P_a = P_b = 2 and P_c = 1:
with full counting, a–b gets 2/\sqrt{2 \times 2} = 1 and a–c gets
1/\sqrt{2 \times 1} \approx 0.71.

``` r
coauth_network(toy, authors = "author", articles = "paper",
               method = "full_counting", cosine_normalized = TRUE)
```

    #>      from     to    weight Source Target
    #>    <char> <char>     <num> <char> <char>
    #> 1:      b      a 1.0000000      b      a
    #> 2:      c      a 0.7071068      c      a
    #> 3:      c      b 0.7071068      c      b

On the stagflation authors, with fractional counting and the cosine
normalisation:

``` r
coauth_network(Authors_stagflation,
               authors = "Author",
               articles = "ItemID_Ref",
               method = "fractional_counting",
               cosine_normalized = TRUE)
```

    #>              from            to    weight        Source        Target
    #>            <char>        <char>     <num>        <char>        <char>
    #>  1:       CHARI-V    ALBANESI-S 0.3535534       CHARI-V    ALBANESI-S
    #>  2:  CHRISTIANO-L    ALBANESI-S 0.2500000  CHRISTIANO-L    ALBANESI-S
    #>  3:  CHRISTIANO-L       CHARI-V 0.3535534  CHRISTIANO-L       CHARI-V
    #>  4:   CUKIERMAN-A     BRUNNER-K 0.3535534   CUKIERMAN-A     BRUNNER-K
    #>  5:  EICHENBAUM-M       CHARI-V 0.3535534  EICHENBAUM-M       CHARI-V
    #>  6:  EICHENBAUM-M  CHRISTIANO-L 0.2500000  EICHENBAUM-M  CHRISTIANO-L
    #>  7: EICHENGREEN-B       BORDO-M 1.0000000 EICHENGREEN-B       BORDO-M
    #>  8:      EUSEPI-S     BULLARD-J 1.0000000      EUSEPI-S     BULLARD-J
    #>  9:      FARMER-R       BEYER-A 1.0000000      FARMER-R       BEYER-A
    #> 10:  FITZGERALD-T  CHRISTIANO-L 0.5000000  FITZGERALD-T  CHRISTIANO-L
    #> 11:        GALI-J   BLANCHARD-O 0.7071068        GALI-J   BLANCHARD-O
    #> 12:        GALI-J     CLARIDA-R 0.3535534        GALI-J     CLARIDA-R
    #> 13:     GERTLER-M    BERNANKE-B 0.3535534     GERTLER-M    BERNANKE-B
    #> 14:     GERTLER-M     CLARIDA-R 0.3535534     GERTLER-M     CLARIDA-R
    #> 15:     GERTLER-M        GALI-J 0.2500000     GERTLER-M        GALI-J
    #> 16:     GOODWIN-T      GISSER-M 1.0000000     GOODWIN-T      GISSER-M
    #> 17:      GORDON-R        FRYE-J 1.0000000      GORDON-R        FRYE-J
    #> 18:        GUST-C  CHRISTIANO-L 0.5000000        GUST-C  CHRISTIANO-L
    #> 19: HALTIWANGER-J       DAVIS-S 1.0000000 HALTIWANGER-J       DAVIS-S
    #> 20:      HOOPER-P   CECCHETTI-S 0.2500000      HOOPER-P   CECCHETTI-S
    #> 21:     JACKMAN-R       GRUBB-D 0.5000000     JACKMAN-R       GRUBB-D
    #> 22:      KASMAN-B   CECCHETTI-S 0.2500000      KASMAN-B   CECCHETTI-S
    #> 23:      KASMAN-B      HOOPER-P 0.2500000      KASMAN-B      HOOPER-P
    #> 24:      KILIAN-L      BARSKY-R 1.0000000      KILIAN-L      BARSKY-R
    #> 25:        KING-R  GOODFRIEND-M 1.0000000        KING-R  GOODFRIEND-M
    #> 26:      LAYARD-R       GRUBB-D 0.5000000      LAYARD-R       GRUBB-D
    #> 27:      LAYARD-R     JACKMAN-R 0.5000000      LAYARD-R     JACKMAN-R
    #> 28:       LIPPI-F   CUKIERMAN-A 0.7071068       LIPPI-F   CUKIERMAN-A
    #> 29:      MANKIW-G        BALL-L 1.0000000      MANKIW-G        BALL-L
    #> 30:    MCGREGOR-R    CHAPPELL-H 1.0000000    MCGREGOR-R    CHAPPELL-H
    #> 31:     MELTZER-A     BRUNNER-K 0.5000000     MELTZER-A     BRUNNER-K
    #> 32:     MELTZER-A   CUKIERMAN-A 0.3535534     MELTZER-A   CUKIERMAN-A
    #> 33:        MORK-K        HALL-R 1.0000000        MORK-K        HALL-R
    #> 34:      NELSON-E     DICECIO-C 1.0000000      NELSON-E     DICECIO-C
    #> 35:      PAPELL-D    NIKOLSKO-R 1.0000000      PAPELL-D    NIKOLSKO-R
    #> 36:   PESAVENTO-E     HERRERA-A 1.0000000   PESAVENTO-E     HERRERA-A
    #> 37:      RASCHE-R       POOLE-W 0.3535534      RASCHE-R       POOLE-W
    #> 38:       ROMER-D       ROMER-C 1.0000000       ROMER-D       ROMER-C
    #> 39:        RUDD-J     BLINDER-A 1.0000000        RUDD-J     BLINDER-A
    #> 40:       SACHS-J       BRUNO-M 1.0000000       SACHS-J       BRUNO-M
    #> 41:     SARGENT-T      COGLEY-T 0.8660254     SARGENT-T      COGLEY-T
    #> 42: SCHOENHOLTZ-K   CECCHETTI-S 0.2500000 SCHOENHOLTZ-K   CECCHETTI-S
    #> 43: SCHOENHOLTZ-K      HOOPER-P 0.2500000 SCHOENHOLTZ-K      HOOPER-P
    #> 44: SCHOENHOLTZ-K      KASMAN-B 0.2500000 SCHOENHOLTZ-K      KASMAN-B
    #> 45:        SILL-K       LEDUC-S 0.5000000        SILL-K       LEDUC-S
    #> 46:       STARK-T       LEDUC-S 0.5000000       STARK-T       LEDUC-S
    #> 47:       STARK-T        SILL-K 0.5000000       STARK-T        SILL-K
    #> 48:      STRAUB-R    BILBIIE-FO 1.0000000      STRAUB-R    BILBIIE-FO
    #> 49:       TATOM-J      RASCHE-R 0.7071068       TATOM-J      RASCHE-R
    #> 50:      TAYLOR-J       LEVIN-A 1.0000000      TAYLOR-J       LEVIN-A
    #> 51:     TINSLEY-P     KOZICKI-S 1.0000000     TINSLEY-P     KOZICKI-S
    #> 52:      WATSON-M    BERNANKE-B 0.3535534      WATSON-M    BERNANKE-B
    #> 53:      WATSON-M   CECCHETTI-S 0.1767767      WATSON-M   CECCHETTI-S
    #> 54:      WATSON-M     GERTLER-M 0.2500000      WATSON-M     GERTLER-M
    #> 55:      WATSON-M      HOOPER-P 0.1767767      WATSON-M      HOOPER-P
    #> 56:      WATSON-M      KASMAN-B 0.1767767      WATSON-M      KASMAN-B
    #> 57:      WATSON-M SCHOENHOLTZ-K 0.1767767      WATSON-M SCHOENHOLTZ-K
    #> 58:    WHEELOCK-D       POOLE-W 0.5000000    WHEELOCK-D       POOLE-W
    #> 59:    WHEELOCK-D      RASCHE-R 0.3535534    WHEELOCK-D      RASCHE-R
    #> 60:    WILLIAMS-J  ORPHANIDES-A 1.0000000    WILLIAMS-J  ORPHANIDES-A
    #> 61:    WILLIAMS-N     SARGENT-T 0.2500000    WILLIAMS-N     SARGENT-T
    #> 62:    WOODFORD-M   ROTEMBERG-J 1.0000000    WOODFORD-M   ROTEMBERG-J
    #> 63:         ZHA-T     SARGENT-T 0.2500000         ZHA-T     SARGENT-T
    #> 64:         ZHA-T    WILLIAMS-N 0.5000000         ZHA-T    WILLIAMS-N
    #>              from            to    weight        Source        Target
    #>            <char>        <char>     <num>        <char>        <char>

Note that, for historical reasons,
[`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md)
orients its edges with `Source > Target`, the opposite of the other
functions.

## Filtering the edges: thresholds and backbones

A bibliometric network built from a large corpus is often too dense to
be read or clustered: almost every pair of documents shares at least one
reference. There are two ways of simplifying it.

- **A threshold**, as seen above: `weight_threshold` keeps the pairs
  sharing at least k references. It is simple and fast, but arbitrary,
  and it is *global*: the same threshold applies to a document with a
  hundred references and to a document with five.
- **A backbone**: keep only the ties that are statistically unlikely
  under a null model, that is, the ties that are stronger than what the
  position of the nodes in the network would produce by chance. This is
  the aim of the [`backbone`](https://github.com/zpneal/backbone)
  package ([Neal 2026](#ref-neal2026)), which is complementary to
  `biblionetwork`: `biblionetwork` computes the edges and their weights,
  `backbone` decides which ones are worth keeping.

`backbone` offers two families of methods, and they do not start from
the same object.

**Filters of weighted networks** (`backbone_from_weighted()`, with the
disparity filter of Serrano, Boguñá, and Vespignani
([2009](#ref-serrano2009)) for instance) start from a *weighted one-mode
network*. They can be run directly on the edges produced by
`biblionetwork`: convert the edge list into a graph and give it to
`backbone`. Since these filters assume that the weights are strengths of
ties, it is more natural to feed them with the *number of shared
references* (`normalized_weight_only = FALSE`) than with a cosine.

``` r
edges <- biblio_coupling(Ref_stagflation,
                         source = "Citing_ItemID_Ref",
                         ref = "ItemID_Ref",
                         normalized_weight_only = FALSE,
                         weight_threshold = 2)

# The weighted graph; the number of shared references is the weight
graph <- igraph::graph_from_data_frame(
  edges[, .(from, to, weight = nb_shared_references)],
  directed = FALSE
)

# The disparity filter: keep an edge if its weight is significantly high
# compared to the other edges of (at least one of) its two nodes
backbone <- backbone::backbone_from_weighted(graph, model = "disparity", alpha = 0.05)
c(edges_before = igraph::ecount(graph), edges_after = igraph::ecount(backbone))
```

    #> edges_before  edges_after
    #>         1501           16

**Filters of bipartite projections** (`backbone_from_projection()`, with
models such as `"sdsm"`, the stochastic degree sequence model) do not
start from the edges but from the *original two-mode table*: they
compare the number of references that two documents share with the
number expected if documents cited references at random, given how many
references each document cites and how many documents cite each
reference. The input is the table of citations as an incidence matrix
(documents in rows, references in columns), which is the same table as
the one you give to `biblionetwork`.

``` r
# Incidence matrix of the citations: 1 if the document (row) cites the reference (column)
incidence <- unclass(table(Ref_stagflation$Citing_ItemID_Ref, Ref_stagflation$ItemID_Ref))
incidence[incidence > 1] <- 1

# Statistically significant coupling ties (the filter is applied to the rows)
backbone_sdsm <- backbone::backbone_from_projection(incidence, model = "sdsm", alpha = 0.05)
sum(backbone_sdsm) / 2   # number of ties kept (the matrix is symmetric)
```

    #> [1] 553

Two practical remarks.

- The statistical models test the *count* of shared references, not a
  normalised weight. Run them on the full table, **without** a
  `weight_threshold`: a pair removed by the threshold cannot be tested.
  The backbone then replaces the threshold. You can use `biblionetwork`
  afterwards, on the pairs kept, if you want the normalised weights of
  the surviving ties (merge the two edge lists by pair of documents).
- These tests are computationally heavier than the edge computation of
  `biblionetwork`, and the null models are not designed for the huge
  corpora that `biblionetwork` handles: on a large corpus, split it by
  time window, or start from the filters of weighted networks.

`networkflow` integrates both steps: its function
`build_dynamic_networks()` can compute the coupling edges and apply a
statistical backbone for each time window (see the
[`networkflow`](https://agoutsmedt.github.io/networkflow/)
documentation).

## Beyond bibliometrics

Nothing in the functions of `biblionetwork` is specific to bibliography.
They take a table with two columns, “a *source* that is linked to a
*ref*”, and build the network of the sources that share refs (coupling)
or of the refs that share sources (co-citation). The words “document”
and “reference” are only the vocabulary of the field in which the
package was written. Whenever you have a two-mode relation, the same
questions can be asked:

| Source (“citing”) | Ref (“cited”) | Coupling links sources that… | Co-citation links refs that… |
|----|----|----|----|
| article | reference | cite the same references | are cited by the same articles |
| social media account | account followed | follow the same accounts (an audience in common) | are followed by the same accounts |
| social media account | post reposted | repost the same posts | are reposted by the same accounts |
| post | hashtag, link, mention | use the same hashtags, links or mentions | are used in the same posts |
| document | word | use the same words | appear in the same documents |

Table 3: A two-mode table, many networks

### Networks of accounts on a social media platform

Take a table of the accounts of a social media platform and the accounts
they follow. Two accounts that follow many of the same accounts probably
listen to the same voices: this is the bibliographic coupling of the
“follows” (the account is the “document”, the accounts it follows are
its “bibliography”). In the same way, two accounts that repost the same
posts are close in what they amplify. The following table is invented,
for the sake of the example.

``` r
follows <- data.table(
  account = c("ann", "ann", "ann", "ben", "ben", "ben", "cleo", "cleo", "dan", "dan", "eve", "eve", "eve"),
  follows = c("news_desk", "dev_tools", "open_web", "news_desk", "dev_tools", "open_web",
              "news_desk", "celebrity", "celebrity", "news_desk", "celebrity", "dev_tools", "open_web")
)

# Accounts close because they follow the same accounts
biblio_coupling(follows, source = "account", ref = "follows", normalized_weight_only = FALSE)
```

    #>       from     to    weight nb_shared_references Source Target
    #>     <char> <char>     <num>                <int> <char> <char>
    #>  1:    ann    ben 1.0000000                    3    ann    ben
    #>  2:    ann   cleo 0.4082483                    1    ann   cleo
    #>  3:    ben   cleo 0.4082483                    1    ben   cleo
    #>  4:    ann    dan 0.4082483                    1    ann    dan
    #>  5:    ben    dan 0.4082483                    1    ben    dan
    #>  6:   cleo    dan 1.0000000                    2   cleo    dan
    #>  7:    ann    eve 0.6666667                    2    ann    eve
    #>  8:    ben    eve 0.6666667                    2    ben    eve
    #>  9:   cleo    eve 0.4082483                    1   cleo    eve
    #> 10:    dan    eve 0.4082483                    1    dan    eve

Here `news_desk` and `celebrity` are followed by almost everybody:
following them says little. The idf-based methods, designed for the
“classics” of a bibliography, are exactly what is needed to discount the
accounts followed by a large audience:

``` r
biblio_coupling(follows, source = "account", ref = "follows", method = "strength")
```

    #>       from     to     weight Source Target
    #>     <char> <char>      <num> <char> <char>
    #>  1:    ann    ben 0.13831053    ann    ben
    #>  2:    ann   cleo 0.03719059    ann   cleo
    #>  3:    ben   cleo 0.03719059    ben   cleo
    #>  4:    ann    dan 0.03719059    ann    dan
    #>  5:    ben    dan 0.03719059    ben    dan
    #>  6:   cleo    dan 0.18349229   cleo    dan
    #>  7:    ann    eve 0.11351681    ann    eve
    #>  8:    ben    eve 0.11351681    ben    eve
    #>  9:   cleo    eve 0.08513760   cleo    eve
    #> 10:    dan    eve 0.08513760    dan    eve

This is how coupling is used on social media data: popular targets (an
account followed by millions) are the equivalent of the classics of a
field, and the warning on memory of [Section 2](#sec-coupling) matters
even more, as such targets are much more frequent than in a
bibliography. Reposts work the same way, with `source` the account and
`ref` the reposted post. And co-citation answers the mirror question:
*which posts are reposted by the same accounts?*

``` r
reposts <- data.table(
  account = c("ann", "ann", "ben", "ben", "cleo", "cleo", "dan"),
  post    = c("p1", "p2", "p1", "p2", "p2", "p3", "p3")
)
biblio_cocitation(reposts, source = "account", ref = "post")
```

    #>      from     to    weight Source Target
    #>    <char> <char>     <num> <char> <char>
    #> 1:     p1     p2 0.8164966     p1     p2
    #> 2:     p2     p3 0.4082483     p2     p3

Because a network of this kind is often dense (and the measures do not
tell which ties are “surprising”), the backbone of
[Section 6](#sec-backbone) is particularly useful there.

### Networks of words

A text is a “document” that “cites” words. The coupling of texts links
the texts that use the same words; the co-citation of words links the
words that appear together. We illustrate it with the titles of the
stagflation documents.

``` r
titles <- Nodes_stagflation[!is.na(Title), .(ItemID_Ref, Title)]

# One row per title and distinct word. Short words and a few stop words are dropped:
# like popular references, very frequent words create a huge number of pairs and carry little meaning.
stop_words <- c("the", "and", "for", "with", "from", "that", "this", "its", "are", "was",
                "into", "their", "between", "some", "what", "how", "when", "than", "have", "new")
words <- titles[, .(word = unique(tolower(unlist(strsplit(Title, "[^A-Za-z]+"))))), by = ItemID_Ref]
words <- words[nchar(word) > 3 & !word %in% stop_words]
words[1:5]
```

    #>    ItemID_Ref      word
    #>        <char>    <char>
    #> 1:  112854189   richard
    #> 2:  112854189     nixon
    #> 3:  112854189 pressured
    #> 4:  112854189    arthur
    #> 5:  112854189     burns

Titles are coupled when they share words. The coupling strength gives
more weight to rare words than to words such as “inflation” or “policy”,
present in many titles:

``` r
title_edges <- biblio_coupling(words, source = "ItemID_Ref", ref = "word",
                               method = "strength", normalized_weight_only = FALSE,
                               weight_threshold = 2)
title_edges[order(-weight)][1:5]
```

    #>          from       to   weight nb_shared_references     Source   Target
    #>        <char>   <char>    <num>                <int>     <char>   <char>
    #> 1:   15862899   804985 2.172583                    2   15862899   804985
    #> 2:  105203318   927924 1.563913                    2  105203318   927924
    #> 3: 1111111190 49791437 1.376890                    2 1111111190 49791437
    #> 4:   37660505  6071710 1.376890                    2   37660505  6071710
    #> 5:   37799073 44208484 1.350867                    3   37799073 44208484

Words are linked when they appear in the same titles (this is the
co-citation of words). The words that always appear together are the
fixed expressions of the corpus:

``` r
word_edges <- biblio_cocitation(words, source = "ItemID_Ref", ref = "word",
                                weight_threshold = 2, normalized_weight_only = FALSE)
word_edges[order(-nb_shared_citations)][1:8, .(from, to, weight, nb_shared_citations)]
```

    #>         from        to    weight nb_shared_citations
    #>       <char>    <char>     <num>               <int>
    #> 1:  monetary    policy 0.7441311                  97
    #> 2:     great inflation 0.3400046                  23
    #> 3: inflation    policy 0.1533110                  22
    #> 4:    states    united 0.9770084                  21
    #> 5:    policy     rules 0.3127716                  18
    #> 6: inflation  monetary 0.1154735                  15
    #> 7:  monetary     rules 0.2687343                  14
    #> 8:     price    shocks 0.3614784                  14

The same logic applies to any “bag of …” representation (n-grams,
keywords, hashtags, named entities, topics of a topic model…). For the
words in the titles of references,
[`coupling_descriptive()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_descriptive.md)
implements a more elaborate approach ([Liu 2017](#ref-liu2017)), which
couples documents that cite *different but related* references.

### What to check before using it outside bibliometrics

- **Orientation.** `source` is the node of the network produced by
  [`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md);
  `ref` is what the nodes share. If the network you obtain has the wrong
  nodes, you probably swapped the columns (the function warns you when
  no pair is found).
- **Popular targets.** A target shared by very many sources (a
  celebrity, a stop word) creates a quadratic number of pairs and
  carries little information. Remove it, or use a method that discounts
  it, or work by time window.
- **The meaning of “length”.** The normalisation by the length of the
  bibliography assumes that having many refs is a form of dilution. For
  an account following 10,000 accounts, this is reasonable; for a text,
  the length of the document in words may be a different matter.
- **Time.** Coupling ties are fixed when the source is created. For
  social media data, the “follows” are not dated in the same way as
  references: think about the moment at which the table is observed.

## A last word on choosing

| Question | Nodes | Function |
|----|----|----|
| Which documents rely on the same literature? Which research fronts? ([Kessler 1963](#ref-kessler1963); [Boyack and Klavans 2010](#ref-boyack2010)) | citing documents | [`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md) |
| Same, but not driven by the classics of the corpus ([Shen et al. 2019](#ref-shen2019)) | citing documents | `biblio_coupling(method = "strength")` or `"similarity"` |
| Does the choice of the measure matter on my corpus? | citing documents | [`compute_couplings()`](https://agoutsmedt.github.io/biblionetwork/reference/compute_couplings.md), then [`correlate_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/correlate_weights.md), [`plot_weights()`](https://agoutsmedt.github.io/biblionetwork/reference/plot_weights.md) |
| Which authors, journals or institutions rely on the same literature (or are cited together)? ([Zhao and Strotmann 2008](#ref-zhao2008b)) | entities | [`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md) |
| Which cited texts are perceived as belonging together? ([Small 1973](#ref-small1973)) | cited references | [`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md) |
| Who collaborates with whom? ([Perianes-Rodriguez, Waltman, and Van Eck 2016](#ref-perianes-rodriguez2016b); [Leydesdorff and Park 2017-02](#ref-leydesdorff2017)) | authors, institutions, countries | [`coauth_network()`](https://agoutsmedt.github.io/biblionetwork/reference/coauth_network.md) |
| Which of these ties are not due to chance? ([Neal 2026](#ref-neal2026)) | any | the `backbone` package |

Table 4: Which measure for which research question?

All the functions return undirected edges (one row per pair), never
modify the table you give them, and return an empty table, with a
warning that says why, when no pair of nodes is linked.

## References

Boyack, Kevin W., and Richard Klavans. 2010. “Co-Citation Analysis,
Bibliographic Coupling, and Direct Citation: Which Citation Approach
Represents the Research Front Most Accurately?” *Journal of the American
Society for Information Science and Technology* 61 (12): 2389–2404.
<https://doi.org/10.1002/asi.21419>.

Goutsmedt, Aurélien. 2021. “From the Stagflation to the Great Inflation:
Explaining the US Economy of the 1970s.” *Revue d’Economie Politique*
Forthcoming.
<https://aurelien-goutsmedt.com/media/pdf/stagflation-great-inflation.pdf>.

Kessler, M. M. 1963. “Bibliographic Coupling Between Scientific Papers.”
*American Documentation* 14 (1): 10–25.
<https://doi.org/10.1002/asi.5090140103>.

Leydesdorff, Loet, and Han Woo Park. 2017-02. “Full and Fractional
Counting in Bibliometric Networks.” *Journal of Informetrics* 11 (1):
117–20.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716303133>.

Liu, Rey-Long. 2017. “A New Bibliographic Coupling Measure with
Descriptive Capability.” *Scientometrics* 110 (2): 915–35.
<https://doi.org/10.1007/s11192-016-2196-7>.

Neal, Zachary P. 2026. “Backbone 3.0: An R Package for Extracting
Network Backbones.” *PLOS ONE* 21 (5): e0349258.
<https://doi.org/10.1371/journal.pone.0349258>.

Perianes-Rodriguez, Antonio, Ludo Waltman, and Nees Jan Van Eck. 2016.
“Constructing Bibliometric Networks: A Comparison Between Full and
Fractional Counting.” *Journal of Informetrics* 10 (4): 1178–95.
<https://www.sciencedirect.com/science/article/pii/S1751157716302036?casa_token=AtzjmZ-1QmYAAAAA:2mlBPZsjGUleYi9mnybHODFw2RmMh3GHvRAuMYXygRm63cQOv07M4ixbAmJXuGq71tx2ug29baTp>.

Sen, Subir K., and Shymal K. Gan. 1983. “A Mathematical Extension of the
Idea of Bibliographic Coupling and Its Applications.” *Annals of Library
Science and Documentation* 30 (2).

Serrano, M. Ángeles, Marián Boguñá, and Alessandro Vespignani. 2009.
“Extracting the Multiscale Backbone of Complex Weighted Networks.”
*Proceedings of the National Academy of Sciences* 106 (16): 6483–88.
<https://doi.org/10.1073/pnas.0808904106>.

Shen, Si, Danhao Zhu, Ronald Rousseau, Xinning Su, and Dongbo Wang.
2019. “A Refined Method for Computing Bibliographic Coupling Strengths.”
*Journal of Informetrics* 13 (2): 605–15.
<https://linkinghub.elsevier.com/retrieve/pii/S1751157716300244>.

Small, Henry. 1973. “Co-Citation in the Scientific Literature: A New
Measure of the Relationship Between Two Documents.” *Journal of the
American Society for Information Science* 24 (4): 265–69.
<https://doi.org/10.1002/asi.4630240406>.

Spärck Jones, Karen. 1972. “A Statistical Interpretation of Term
Specificity and Its Application in Retrieval.” *Journal of
Documentation* 28 (1): 11–21.

Vladutz, George, and James Cook. 1984. “Bibliographic Coupling and
Subject Relatedness.” *Proceedings of the American Society for
Information Science* 21: 204–7.

Zhao, Dangzhi, and Andreas Strotmann. 2008. “Author Bibliographic
Coupling: Another Approach to Citation-Based Author Knowledge Network
Analysis.” *Proceedings of the American Society for Information Science
and Technology* 45 (1): 1–10.
<https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/meet.2008.1450450292>.
