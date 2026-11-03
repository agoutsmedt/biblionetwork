# Coupling edges between entities (deprecated)

`coupling_entity()` was renamed
[`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md),
because it is not a measure of coupling of its own but the aggregation
of the coupling (or co-citation) measures at the level of entities. It
is kept as a wrapper, that accepts the former names of the methods
(`"coupling_strength"`, `"coupling_angle"`, `"coupling_similarity"`),
and will be removed in a future version.

## Usage

``` r
coupling_entity(
  dt,
  source,
  ref,
  entity,
  weight_threshold = 1,
  output_in_character = FALSE,
  method = c("coupling_strength", "coupling_angle", "coupling_similarity")
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

- weight_threshold:

  Number. The minimum number of shared references for two entities to be
  linked (1 by default). With large entities such as journals, a higher
  value is advisable.

- output_in_character:

  Logical. If `TRUE`, `from` and `to` are character columns (`FALSE` by
  default for this function: they keep the type of the entity column).

- method:

  `"coupling_strength"` (default), `"coupling_angle"` or
  `"coupling_similarity"`: the former names of the methods `"strength"`,
  `"angle"` and `"similarity"` of
  [`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md).
  The `Weighting_method` column of the result keeps the former name.

## Value

See
[`entity_network()`](https://agoutsmedt.github.io/biblionetwork/reference/entity_network.md).

## Details

**\[deprecated\]**
