# Bundled example data

## Recorded animation example

`sierpinski-trace.rds` contains a level-4 Sierpinski triangle edge list and
40 recorded two-dimensional layout frames from the grip R package (GPL >= 3,
Pawel Gajer). It also contains frame metadata, the original selected indices,
and the exact grip package version, source commit, and solver settings in
`provenance`. No alignment or normalization was applied.

This is public vignette example data, not a benchmark or a reference optimum.
Regenerate from the ivue repository with:

```
Rscript tools/generate-animation-example.R /path/to/grip
```

The generator requires grip and pkgload. The bundled vignette and installed
ivue package read the record without requiring grip. The source checkout's
R/ and src/ directories must be clean when recording provenance.

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
doi:10.1016/j.neuron.2019.04.010, GEO GSE118614. The README figure provenance
in `man/figures/README.md` records the full preparation workflow.
