# Aggregate a coupling or co-citation network at the level of entities

Builds the edges of a coupling (or co-citation) network whose nodes are
not documents but *entities* that aggregate documents: authors,
journals, institutions, countries... It is not a new measure of
proximity: it takes the measures of
[`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md)
(or of
[`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md))
and computes them for entities instead of documents. Since an entity
publishes several documents, it can cite the same reference several
times, and the function takes this into account: citing a reference ten
times is more significant than citing it once. The counts are combined
with the *minimum rule* of Zhao and Strotmann (2008) .

## Usage

``` r
entity_network(
  dt,
  source,
  ref,
  entity,
  network = c("coupling", "cocitation"),
  method = c("angle", "strength", "similarity", "jaccard", "vladutz"),
  weight_threshold = 1,
  output_in_character = FALSE
)
```

## Arguments

- dt:

  A data frame or a `data.table` of direct citations, one row per link
  between a citing document and a cited reference. It is not modified.

- source:

  Character scalar. The column of the citing documents. Needed to count
  the documents, not to define the nodes (except for
  `network = "cocitation"`, see the details).

- ref:

  Character scalar. The column of the cited references.

- entity:

  Character scalar. The column of the entities that are the nodes of the
  network (authors, journals, institutions...). With
  `network = "coupling"` it describes the citing documents (`source`);
  with `network = "cocitation"` it describes the cited references
  (`ref`). A document can appear with several entities (one row per
  entity and reference).

- network:

  `"coupling"` (default): the entities are linked when their documents
  cite the same references. `"cocitation"`: they are linked when their
  references are cited by the same documents.

- method:

  The weighting method, one of `"angle"` (default), `"strength"`,
  `"similarity"`, `"jaccard"` and `"vladutz"`: see the details, and
  [`biblio_coupling()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_coupling.md)
  for their document-level versions.

- weight_threshold:

  Number. The minimum number of shared references for two entities to be
  linked (1 by default). With large entities such as journals, a higher
  value is advisable.

- output_in_character:

  Logical. If `TRUE`, `from` and `to` are character columns (`FALSE` by
  default for this function: they keep the type of the entity column).

## Value

A `data.table` with one row per pair of entities: `from`, `to`, the
`weight`, the original identifiers in `Source` and `Target`, and the
`Weighting_method` (the `method`). Each pair appears once, with
`Source < Target`.

## Details

**\[experimental\]**

Write \\C\_{Aj}\\ for the number of times entity \\A\\ cites reference
\\j\\ (the number of its documents citing \\j\\), \\N\\ for the number
of citing documents in the table, \\f_j\\ for the number of documents
citing \\j\\, and \\L(A) = \sum_j C\_{Aj}\\ for the total number of
citations made by \\A\\. Write also \\m\_{AB}(g) = \sum\_{j}
\min(C\_{Aj}, C\_{Bj}) \\ g_j\\, the overlap of the two entities, with
the references weighted by \\g_j\\. According to `method`, the weight of
the tie between \\A\\ and \\B\\ is

- `"angle"`, with \\g_j = 1\\: \$\$w\_{AB} =
  \frac{m\_{AB}(1)}{\sqrt{L(A) \\ L(B)}}\$\$

- `"strength"`, with \\g_j = \log(N / f_j)\\: \$\$w\_{AB} =
  \frac{m\_{AB}(g)}{L(A) \\ L(B)}\$\$

- `"similarity"`, with \\g_j = \log(N / f_j)\\ and \\S(A) = \sum_j
  C\_{Aj} \log(N / f_j)\\: \$\$w\_{AB} = \frac{m\_{AB}(g)}{\sqrt{S(A) \\
  S(B)}}\$\$

- `"jaccard"`, with \\g_j = 1\\: \$\$w\_{AB} = \frac{m\_{AB}(1)}{L(A) +
  L(B) - m\_{AB}(1)}\$\$ which is the ratio of the sum of the minima to
  the sum of the maxima of the counts (the weighted Jaccard index);

- `"vladutz"`, with \\g_j = 1 / f_j\\: \$\$w\_{AB} = \frac{4 \\
  m\_{AB}(g)}{L(A) + L(B)}\$\$

The sums run over the references cited by both entities, and \\L\\,
\\S\\ over all the references of the entity. The minimum of the two
counts is the number of times the two entities cite the reference
"together" (Zhao and Strotmann 2008) . The package follows the paper for
the minimum rule with the coupling angle and strength; the other methods
are the *same extension*, applied to the measures of
[`coupling_similarity()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_similarity.md),
[`coupling_jaccard()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_jaccard.md)
and
[`coupling_vladutz()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_vladutz.md)
(the similarity is still bounded by 1, since \\\min(C\_{Aj}, C\_{Bj})
\leq \sqrt{C\_{Aj} C\_{Bj}}\\ and by the Cauchy-Schwarz inequality).
With a single citation per entity and reference, each method gives back
the document-level measure. \\f_j\\ counts citing documents, not
entities, so that a document with several authors is not counted several
times. References cited by a single entity cannot create a tie and are
ignored in the overlaps, but they count in \\L\\.

**Co-citation.** With `network = "cocitation"`, the roles of `source`
and `ref` are swapped, as in
[`biblio_cocitation()`](https://agoutsmedt.github.io/biblionetwork/reference/biblio_cocitation.md):
the nodes are the entities of the *cited* references, and the `entity`
column must describe `ref` (the author or the journal of the cited
reference). Two entities are co-cited when documents cite references of
both. The formulas above apply with the roles exchanged: \\C\_{Aj}\\ is
the number of references of \\A\\ cited by document \\j\\.

The `weight_threshold` applies to the number of references shared by two
entities (each counted once, whatever the number of times it is cited).
The table of the user is not modified, rows with a missing identifier
are dropped with a warning, and a zero-row table is returned, with a
warning, if no reference is shared (or if no pair reaches
`weight_threshold`). The memory warning of
[`coupling_strength()`](https://agoutsmedt.github.io/biblionetwork/reference/coupling_strength.md)
applies.

## Why use it in research

Coupling at the level of authors (author bibliographic coupling, (Zhao
and Strotmann 2008) ), journals or institutions maps who relies on the
same literature, whatever the documents they publish. With
`network = "cocitation"`, it maps which authors, journals or
institutions are cited together, as in author co-citation analysis. It
is a way to study the structure of a discipline through its journals or
its authors, with fewer and denser nodes than the document-level
network. Because entities are aggregates of documents, check that they
are not too heterogeneous (a generalist journal citing everything is
coupled with everyone), and that the number of documents per entity is
large enough to give a stable bibliography. An article with several
authors appears once for each of its authors: the same document then
contributes to several entities.

## Intuition

Think of an entity (say a journal) as one big bibliography made of the
bibliographies of all its documents, in which a reference appears as
many times as the entity's documents cite it. Two journals are close
when their big bibliographies overlap. Overlap is measured reference by
reference by the *smaller* of the two counts: if journal A cites a
reference 10 times and journal B twice, they share it twice (B is the
limit). The methods then differ in what they do with these overlaps, as
their document-level counterparts: `"angle"` only counts them and
normalises by the sizes of the two big bibliographies; `"strength"`
counts a shared rare reference more than a shared classic;
`"similarity"` does the same but normalises by the "informational size"
of each big bibliography, to give a cosine that cannot exceed 1;
`"jaccard"` compares the overlap with the union of the two big
bibliographies; `"vladutz"` discounts popular references steeply.

## References

Zhao D, Strotmann A (2008). “Author Bibliographic Coupling: Another
Approach to Citation-Based Author Knowledge Network Analysis.”
*Proceedings of the American Society for Information Science and
Technology*, **45**(1), 1–10.
<https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/meet.2008.1450450292>.

## Examples

``` r
library(biblionetwork)
Ref_stagflation$Citing_ItemID_Ref <- as.character(Ref_stagflation$Citing_ItemID_Ref)
# merging the references data with the citing author information in Nodes_stagflation
entity_citations <- merge(Ref_stagflation,
                          Nodes_stagflation,
                          by.x = "Citing_ItemID_Ref",
                          by.y = "ItemID_Ref")

entity_network(entity_citations,
                source = "Citing_ItemID_Ref",
                ref = "ItemID_Ref",
                entity = "Author.y",
                method = "angle")
#>             from          to     weight     Source      Target Weighting_method
#>           <char>      <char>      <num>     <char>      <char>           <char>
#>    1: ALBANESI-S      BALL-L 0.04859295 ALBANESI-S      BALL-L            angle
#>    2: ALBANESI-S    BARSKY-R 0.06302187 ALBANESI-S    BARSKY-R            angle
#>    3: ALBANESI-S     BEYER-A 0.03458572 ALBANESI-S     BEYER-A            angle
#>    4: ALBANESI-S  BILBIIE-FO 0.06428243 ALBANESI-S  BILBIIE-FO            angle
#>    5: ALBANESI-S     BORDO-M 0.04351941 ALBANESI-S     BORDO-M            angle
#>   ---                                                                          
#> 1545:    VELDE-F   WACHTER-M 0.01883109    VELDE-F   WACHTER-M            angle
#> 1546:    VELDE-F WEINTRAUB-S 0.12909944    VELDE-F WEINTRAUB-S            angle
#> 1547:    VELDE-F     WEISE-C 0.06846532    VELDE-F     WEISE-C            angle
#> 1548:    VELDE-F     YOUNG-W 0.04803845    VELDE-F     YOUNG-W            angle
#> 1549:  WACHTER-M WEINTRAUB-S 0.14586499  WACHTER-M WEINTRAUB-S            angle

# The same entities, linked when the documents of one cite the references of the other
# (nodes: the journals of the cited references, a column of Ref_stagflation)
head(entity_network(Ref_stagflation, source = "Citing_ItemID_Ref", ref = "ItemID_Ref",
                    entity = "Journal", network = "cocitation", weight_threshold = 2))
#> Warning: Dropping 738 rows with a missing identifier.
#>          from                   to    weight     Source               Target
#>        <char>               <char>     <num>     <char>               <char>
#> 1: 11147 NBER          AM ECON REV 0.1235604 11147 NBER          AM ECON REV
#> 2: 11147 NBER CENTRAL BANKING THEO 0.8164966 11147 NBER CENTRAL BANKING THEO
#> 3: 11147 NBER CONQUEST AM INFLATIO 0.3535534 11147 NBER CONQUEST AM INFLATIO
#> 4: 11147 NBER      J ECON PERSPECT 0.3086067 11147 NBER      J ECON PERSPECT
#> 5: 11147 NBER      J MONETARY ECON 0.1280369 11147 NBER      J MONETARY ECON
#> 6: 11147 NBER         J POLIT ECON 0.2108185 11147 NBER         J POLIT ECON
#>    Weighting_method
#>              <char>
#> 1:            angle
#> 2:            angle
#> 3:            angle
#> 4:            angle
#> 5:            angle
#> 6:            angle
```
