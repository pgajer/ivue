# ivue 0.0.0.9001

- Added canonical browser-first point, continuous-color, group, and weighted
  graph plots with shared scene lifecycle and no output-name aliases.
- Added reusable color scales, consistent legends, geometric/callback layers,
  coordinate identity metadata, and independent HTML export.
- Added weighted graph normalization and optional weight-aware igraph layouts.
- Added null-device, color, graph, baseline, and browser regression checks.
- Added an introductory saddle/graph vignette, runnable examples for every
  export, full manual checks, and checks without suggested packages.
- Preserve igraph's existing `id` attribute as `.igraph.id`; reject ambiguous
  table columns and mismatched named weight lists.
- Apply global opacity consistently to legend swatches and continuous ramps.
- Reject invalid complex numeric controls and binned diverging centers that
  were previously ignored; binned scales can use explicit bin colors.
- Normalize matrix adjacency rows without repeatedly scanning all edges.

# ivue 0.0.0.9000

* Created the initial package scaffold and local Git repository before
  migration of plotting utilities from `gflow`.
