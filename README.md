# ivue

Interactive 3D visualization of data and graphs in R.

## Status

This repository currently contains the package scaffold, version `0.0.0.9000`.
There are no exported plotting functions yet. Migration of the generic
`plot3D.*` utilities from `gflow` is the next development phase.

The intended foundation is `rgl` with browser-based `htmlwidgets` output.
The plotting package will be independent of `gflow`, `gflowui`, and Shiny.
Dependencies will be added as their functionality is migrated.

## Scope

- Point clouds, continuous values, and categorical groups.
- Embedded graphs specified by coordinates and edges.
- Labels, paths, geometric overlays, and reusable color legends.
- Interactive browser output and HTML export.

Graph construction, shortest-path computation, and gradient-flow analysis
remain with their respective analysis packages. `ivue` will accept their
results as ordinary coordinates, values, groups, and geometric layers.

## Development

```sh
make document
make check
```

`make document` requires `roxygen2`. `make check` regenerates documentation,
builds the source package, and checks it without compiling a PDF manual.
Generated help files and `NAMESPACE` are tracked; build and check outputs are
ignored by Git.

See [MIGRATION.md](MIGRATION.md) for the extraction sequence and acceptance
criteria.
