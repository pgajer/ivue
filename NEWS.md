# ivue 0.1.0

- **README figures:** static retinal alternatives use version-pinned web links
  so they remain accessible from the source package, which excludes large
  repository figure assets.
- **Graphics cleanup:** GIF rendering and annotation drawing explicitly restore
  graphical parameters on success and failure, before closing export devices.
- **GIF camera correction:** smaller zoom values now enlarge both browser and
  GIF views. GIF framing uses the retained observer and bounds. Existing GIF
  recipes may change apparent size; check their output before reusing it.
- **Annotated GIFs:** `write.animation.gif(..., annotations = TRUE)` draws the
  fixed mapping legend and caption beside/below the scene. The default remains
  unannotated; long text requires sufficient output dimensions.
- **Shiny and keyboard controls:** complete animations now connect their scene
  and player IDs inside `renderUI()`. Reactive updates preserve control focus,
  leave unrelated inputs focused, and stop removed players. Frame sliders expose
  descriptive labels without announcing every playback tick.
- **Guide navigation:** task links and function-help links work in installed
  and hosted documentation, with a persistent first-export recipe.


- Prepared graphs and color scales now print concise summaries while retaining
  full list access.
- Point and graph views accept common framing `limits`, scene `description`,
  and keyboard view `controls`, including reset and downloadable camera recipes.
- Color legends provide a focusable scrolling region and readable table.
  Installed guides include small static saddle and animation alternatives.
- `animate.frames()` accepts a fixed `mapping` and interpretation `caption`,
  retained in saved HTML, and gives its player and slider descriptive names.

Initial release.

- **Getting started:** installed package help is visible in the help index,
  links directly to all five guides, and includes a small executable example.
  A documentation site offers rendered guides, function reference, and a built
  development package containing the installed vignettes.
- **Custom colors:** documentation specifies deterministic, pointwise mappings
  in data units and distinguishes callback behavior from palette centering.
- **Retinal provenance:** bundled metadata now records display transformations,
  including explicit unavailable parameters in the historical graph cache.
  Coordinates, annotations, graph weights, and fitted diagnostics are unchanged.

- **Observation identity:** point plots now match named values, groups, colors,
  logical highlight masks, and style colors to explicit coordinate row IDs,
  using the same exact-match rule as graph plots. Unnamed vectors remain
  positional; use `unname()` to retain that behavior when names are not IDs.
  Invalid or incomplete names are errors. Default categorical scales use
  annotation order before alignment in both point and graph views. Widget
  metadata adds `observation.ids`; `row.ids` remains integer row positions.

- **3D visualization:** `plot3D.plain()`, `plot3D.cont()`,
  `plot3D.groups()`, and `plot3D.graph()` display point clouds and embedded
  weighted graphs with numerical or categorical colors and highlighting.
  Browser widgets use `rgl` without requiring a native graphics window.

- **Geometric layers:** edges, paths, labels, triangular meshes, gridded
  reference surfaces, and origin-crossing coordinate axes can be combined
  with plotted observations.

- **Consistent views:** reusable continuous and categorical color scales
  provide matching legends. Plots default to an orthographic z-up camera;
  `camera.zup()` and explicit camera settings support reproducible views.

- **Animation and sharing:** `animate.frames()` plays recorded 2D or 3D
  coordinates with timeline and speed controls. Widgets can be saved as
  interactive HTML, and `write.animation.gif()` exports orthographic
  animations through the optional `magick` package.

- **Graph inputs:** `prepare.graph()` accepts edge tables, paired adjacency
  and weight lists, dense or sparse adjacency matrices, and igraph objects.
  Vertex-ID matching keeps coordinates and annotations aligned. Supplied
  layouts can be displayed directly; optional igraph layouts use explicit
  distance or strength weight semantics.

- **Documentation:** five installed vignettes include a task-oriented catalog
  of all 18 public functions and reproducible data recipes, alongside the
  plotting introduction, retinal case study, and animation guide. Compact examples keep
  the self-contained HTML guides usable offline.
