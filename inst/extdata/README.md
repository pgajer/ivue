# Bundled example data

## Retinal-development case study

`retinal-development.rds` contains visualization-ready values for the package's
retinal-development case study: published 3D UMAP coordinates, an independently
computed symmetric-kNN graph layout, a weighted edge table, categorical age and
cell-type annotations, and scientific provenance for the same 12,000 cells.
Both embeddings were fitted on all 120,804 cells before display subsampling:
published UMAP uses Canberra distance, and the symmetric 4-nearest-neighbor
graph uses Euclidean distance with weighted-GRIP plus edge-KK. The edge table
is the induced subgraph on the displayed cells, not a new sample-fitted graph.
Cell identifiers are synthetic. The object contains no expression or PC matrix,
barcodes, sample identifiers, or local paths.

Regenerate it after `make readme-retinal-layout` with:

```
Rscript tools/generate-retinal-vignette-data.R
```

The source data are from Clark et al. (2019), Neuron 102:1111-1126.e5,
doi:10.1016/j.neuron.2019.04.010, GEO GSE118614. The
[README figure provenance](https://github.com/pgajer/ivue/blob/main/man/figures/README.md)
records the full preparation workflow.

### Source terms

Published UMAP coordinates and annotations come from the Goff lab's
[cellular phenotype data](https://github.com/gofflab/developing_mouse_retina_scRNASeq#cellular-phenotype-data),
the March 11, 2021 update including horizontal cells. The source table's MD5
checksum is retained in `provenance$source.md5`. Graph coordinates and edge
weights were computed for this example from the GEO expression data.

The upstream data are publicly available. The repository's
[use agreement](https://github.com/gofflab/developing_mouse_retina_scRNASeq/blob/3bfeea29ecc957d59e4a156229449b060ffda0a8/README.md#use-agreement)
states a prepublication consent restriction tied to January 1, 2019.
No separate dataset license was found in the repository reviewed on
September 8, 2026. Public availability and the elapsed embargo date are not
assertions of public-domain status or a new permission grant. The package's
GPL declaration covers its code; it does not itself establish third-party
rights in these source values. These available terms and the remaining
uncertainty are disclosed in the CRAN submission comments for assessment.
