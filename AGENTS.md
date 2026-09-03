# Repository Instructions

## Scope

`ivue` owns generic 3D visualization of data and embedded graphs. Keep graph
construction and gradient-flow analysis in their owning packages. Ordinary
plotting must not require `gflow`, `gflowui`, or Shiny.

## R Style

- Prefer dot-delimited names for ordinary R functions and variables.
- Preserve framework conventions for S3 methods and classes.
- Keep the initial public API small and consistent across plotting families.

## Rendering

- Prefer browser widgets backed by `rgl` null-device scenes.
- Select null-device operation before loading the `rgl` namespace.
- Restore temporary options and device state; do not open native windows at
  package load time or infer native graphics support from `DISPLAY` alone.
- Share scene-building logic between related plotting functions.
- Keep native display explicitly opt-in if it is retained.

## Migration

- Follow `MIGRATION.md` and record the source commit and source paths for each
  migrated group of functions.
- Do not migrate `.html` aliases or provide thin `.widget` aliases. Export
  canonical plotting names only.
- Keep the embedded-graph phase, but redesign `plot3D.graph` and
  `.compute.igraph.layout` for weighted-graph inputs before implementing them.
  Share input normalization across formats, distinguish weight semantics, and
  separate supplied coordinates from optional layout computation.
- Prefer a consistent, explicit new API over preserving inconsistent legacy
  arguments. Document changes and update callers rather than adding aliases.
- Migrate the plotting functions together with their required helpers and
  focused regression tests.
- Update downstream callers and verify them before removing source functions
  from their previous package.
- Preserve existing licenses and author attribution when moving code.

## Package QA

- Use the `r-package-qa` skill for package QA and documentation work.
- Edit roxygen source, then run `make document`; do not hand-edit `NAMESPACE`
  or generated Rd files.
- Run focused tests after adding behavior and `make check` for package checks.
- Keep build products and check output out of commits.
