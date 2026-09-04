# ivue 0.1.0

- Add layer3D.axes for origin-crossing coordinate axes with solid 3D arrowheads,
  and camera.zup for reproducible z-up initial views. Illustrate them with an
  area-uniform saddle sample and a blue-yellow-red scale in the vignette.
- Treat numeric and complex NaN groups as missing while preserving literal
  "NaN" categories and accurate legend counts.
- Use plot3D.groups as the canonical categorical plot name, without a cltrs
  alias. Add backend-free prepare.graph for inspecting and reusing graph data.
- Align named graph values, groups, colors, and logical highlight masks by
  exact vertex ID; reject partial, duplicate, missing, or extra names.
- Pass color alpha and plot opacity to actual point, sphere, edge, path, and
  label materials; retain documented highlight-style overrides.
- Freeze numeric palette indices in fitted scales, handle empty and missing
  factor levels, and automatically distinguish nearby legend boundaries.
- Normalize extreme finite ranges without overflow and reject contradictory
  explicit limits and bin boundaries.
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
