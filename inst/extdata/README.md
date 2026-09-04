# Recorded animation example

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
