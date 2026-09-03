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

- Record the source commit, source paths, and attribution for migrated code in
  `inst/MIGRATION_PROVENANCE.md`.
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

## Private Agent Work Products

- Keep internal audits, agent handoffs, planning notes, and release working
  records under `~/.codex/private/ivue/`, not in the repository.
- Organize private material by workstream, with `audits/`, `handoffs/`,
  `plans/`, or `validation/` subdirectories as needed. Maintain a workstream
  README recording each file's origin, former path, purpose, and disposition.
- Keep public package documentation, formal submission comments, source
  attribution, regression tests, and reusable validation/CI tools in Git.
- Builds and tests must never depend on private files. When moving a tracked
  internal record, preserve it privately and use a normal Git deletion;
  do not rewrite repository history without separate explicit authorization.
- Private files are not backed up by repository pushes. Do not store secrets
  or credentials in the private tree.
