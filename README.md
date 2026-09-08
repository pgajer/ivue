# ivue

**ivue** is an R package for interactive three-dimensional visualization of data
and embedded graphs. It turns 3D coordinates into explorable scenes, combining
point clouds and graph edges with continuous or categorical colors, labels,
paths, and geometric overlays. Reusable color scales and explicit camera
controls help make comparisons consistent across views. Built on `rgl` and
`htmlwidgets`, ivue displays plots in RStudio or a web browser and exports them
as interactive HTML. It works with coordinates from your chosen analysis or
embedding method, keeping visualization independent of how those coordinates
were computed.

![Two synchronized point-only views of 12,000 retinal cells extracted after fitting a symmetric 4-nearest-neighbor graph layout on all 120,804 cells, colored by developmental stage and annotated cell type.](https://raw.githubusercontent.com/pgajer/ivue/302f7095c6e513e4ea1fd1d48099c8c7885f1d19/man/figures/readme-retinal-sknn.gif)

The same embedded point cloud is colored by developmental stage and annotated cell
type using reusable `ivue` group scales and a synchronized orthographic camera.
`dgraphs` builds a symmetric 4-nearest-neighbor graph on all **120,804 cells**,
using the first 20 PCs reconstructed from the published 3,290 high-variance
genes and `log10(CPT + 1)` representation. `grip` fits weighted-GRIP followed
by edge-KK refinement to this full graph. Only afterward are the same
stratified 12,000 cells selected for display, matching the published UMAP's
fitting population and the cell identities in the comparison below.
**The published UMAP uses Canberra distance; the sKNN graph uses Euclidean
distance.** `ivue` renders the resulting coordinates as points. Displayed cells come from the
107,052-cell retained mouse retinal-development dataset of
[Clark et al. (2019)](https://pmc.ncbi.nlm.nih.gov/articles/PMC6768831/).

## Get Started

Explore point clouds and embedded graphs with numerical or categorical colors.
Install ivue and its plotting backend with:

```r
install.packages(c("ivue", "rgl"))
```

Printing a returned widget displays it
in RStudio's Viewer or an interactive R session's browser. Assign it to a
variable to defer viewing, or save it as HTML. No native graphics window or
XQuartz setup is needed. ivue does not depend on gflow, gflowui, or Shiny.

During local development use `make install` in this repo.
`rgl` is a deferred-loaded suggested dependency so even `pkgload::load_all()`
does not initialize native graphics early. Color mapping and graph preparation work without it;
plotting requires it. `igraph` is optional for layout and igraph input, and
`Matrix` is optional for sparse input.

## Scope

- Point clouds, continuous values, and categorical groups.
- Embedded graphs specified by coordinates and edges.
- Labels, paths, geometric overlays, and reusable color legends.
- Interactive browser output and HTML export.

Graph construction, shortest-path computation, and gradient-flow analysis
remain with their respective analysis packages. `ivue` accepts their results
as coordinates, values, groups, and geometric layers. Optional graph layout
uses existing igraph algorithms with explicit weight semantics.

## Two Embeddings of Retinal Development

![Synchronized rotating vertex-only views of the same 12,000 retinal cells in published three-dimensional UMAP coordinates and the symmetric-kNN graph layout, both colored by developmental stage and initially oriented with their P14 centroids toward the viewer.](https://raw.githubusercontent.com/pgajer/ivue/bfcc4460bff200e7d66c80e2319455d260e3f973/man/figures/readme-retinal-comparison.gif)

This animation compares the published UMAP coordinates with the
weighted-GRIP plus edge-KK coordinates of the symmetric 4-nearest-neighbor graph.
Both embeddings were fitted on 120,804 cells before extracting these same
12,000 cells for display. UMAP uses **Canberra distance**, whereas sKNN uses
**Euclidean distance**, so this compares two complete embedding pipelines,
including their distance metrics. Both panels
show only vertices, so visible differences reflect the embeddings rather than
the graph's edge layer. Cell identities, developmental colors, point styling,
projection, and camera motion are held fixed. Each embedding is independently
oriented so that its **P14 centroid faces the viewer at the start**. These are
rigid display rotations, not refits or deformations. Both panels then complete
one rotation in 14.4 seconds using identical camera angles at each frame.
`ivue` renders the comparison; it
does not compute either embedding. See the retinal-development case study with
`vignette("retinal-development", package = "ivue")` for the complete plotting
workflow and provenance.

## Saddle Example

```r
library(ivue)
set.seed(1)
xs <- runif(250, -1, 1)
ys <- runif(250, -1, 1)
zs <- 1.2 * (xs^2 - ys^2)
X <- cbind(x = xs, y = ys, z = zs)

plot3D.plain(X, point.size = 5, axes = TRUE)
w <- plot3D.cont(X, values = zs, point.size = 5, axes = TRUE)
w
plot3D.groups(X, groups = ifelse(zs >= 0, "Nonnegative", "Negative"))
htmlwidgets::saveWidget(w, "saddle.html", selfcontained = FALSE)
```

All plot functions return an ordinary htmlwidget. There are no `.widget` or
`.html` aliases. Points use `point.size` in screen pixels; spheres use
`point.type = "sphere"` and `sphere.radius` in data units. `highlight` changes
styling without removing rows or refitting scales. Save files separately.

For coordinate axes through the origin and an initial z-up view:

```r
byr <- color.scale.cont(zs, center = 0, palette = c("blue", "yellow", "red"))
plot3D.cont(X, values = zs, scale = byr, axes = FALSE,
  layers = list(layer3D.axes(head.length = 0.04)),
  camera = camera.zup(elevation = 20, turn = -135))
```

The axes and camera are independent. `turn = 0` places x horizontally to the
right; `fov = 0` (the helper's default) gives orthographic projection. The
vignette also shows surface-area-uniform saddle sampling and axis styling.

## Triangular Surfaces

`layer3D.mesh(triangles)` draws supplied faces, where each row of `triangles`
contains three vertex indices into the plot coordinates. Face opacity (`alpha`)
and mesh-edge opacity (`edge.alpha`) are independent; shared edges are drawn
only once. Reuse the layer with other coordinates to show how the same mesh
deforms, preserving vertex identities and row order.

For the saddle, `geometry::delaunayn(X[, c("x", "y")])` constructs faces in
the original parameter plane. `geometry` is an add-on package, listed in
`Suggests` for the vignette; mesh rendering itself does not require it.
The complete plotting recipe is in
[`tools/saddle-delaunay.R`](https://github.com/pgajer/ivue/blob/main/tools/saddle-delaunay.R). The mesh is a display
overlay; it does not change any graph used for fitting or scoring.

## Gridded Reference Surfaces

`layer3D.surface(x, y, z)` keeps its own coordinates, independently of the
plotted points. Here `z[i, j]` is the height at `(x[i], y[j])`:

```r
x <- y <- seq(-1, 1, length.out = 51)
z <- outer(x, y, function(x, y) 1.2 * (x^2 - y^2))
reference <- layer3D.surface(x, y, z, col = "lightblue", alpha = 0.3)
plot3D.cont(X, values = X[, "z"], scale = sc,
  layers = list(reference, layer3D.axes()), camera = camera.zup())
```

Use `edges = TRUE` for grid lines and `lit = TRUE` for lighting. Neither
`geometry` nor a triangulation call is required. The grid is drawn as planar
triangles; increasing its resolution approximates the smooth surface more
closely. The same reference can be overlaid on MDS or refined coordinates
after aligning them to the original data. No alignment or rescaling is
performed by the plotting layer.

## Weighted Graphs

```r
edges <- data.frame(from = c("a", "b"), to = c("b", "c"), weight = c(2, 4))
g <- prepare.graph(edges, vertices = c("a", "b", "c", "isolate"),
                   weight.type = "distance")
g$edges
coords <- rbind(c = c(2, 0, 1), a = c(0, 0, 0),
                isolate = c(0, 2, 1), b = c(1, 1, 0))
values <- c(b = 20, isolate = 40, c = 30, a = 10)
plot3D.graph(g, X = coords, values = values, edge.width = 1 + g$edges$weight)

# Optional layout requires igraph. No weight inversion is performed.
plot3D.graph(g, layout = "kk")
# An igraph object without weights needs an explicit unweighted declaration.
plot3D.graph(igraph::make_ring(4), layout = "fr", weight.type = "unweighted")
```

`prepare.graph()` validates input without rgl and exposes the edge order used
for styling. **Weights do not automatically control edge width or color**;
the example chooses a width mapping explicitly. Prepared graphs can be reused.
Their integer edge endpoints index the current vertex table. To change vertex
order, prepare a new graph from IDs rather than reorder that table in place.

Supported formats: paired adjacency/weight lists, edge tables with explicit
vertices, dense/sparse adjacency matrices, and igraph objects. Vertex identity,
isolates, weights, and table attributes are preserved. Matrices use zero for
absent edges; lists/tables can represent zero-weight edges. This first version
rejects directed rendering, self-loops, and parallel edges explicitly.

Supply coordinates or request a layout, never both. Existing coordinates need
no igraph conversion. `fr` treats weights as strengths; `kk` treats them as
distances. Both require positive layout weights. Custom layout callbacks can
consume the normalized graph without igraph. Coordinate row names, when
present, must match vertex IDs exactly. Named values, groups, colors, and logical
highlight masks follow the same rule, independently of coordinate row order.
Unnamed vectors follow graph vertex order. Partial or duplicate names are errors.

## Development

```sh
make document
make check
make check-cran
make check-minimal
```

`make document` requires `roxygen2`. `make check` regenerates documentation,
builds the source package, and checks it without compiling a PDF manual.
Generated help files and `NAMESPACE` are tracked; build and check outputs are
ignored by Git.

`make check-cran` also checks the PDF manual and rebuilds the vignette.
`make check-minimal` checks without suggested packages, including the
backend-free color API and the missing-rgl installation message. On macOS,
set `R_TIDYCMD` to a modern HTML Tidy executable to validate the HTML manual.
After installation, `vignette("ivue-introduction", package = "ivue")` covers
shared scales, highlighting, graph inputs, layers, camera reuse, and export.

Source attribution is recorded in
[MIGRATION_PROVENANCE.md](https://github.com/pgajer/ivue/blob/main/inst/MIGRATION_PROVENANCE.md).
The [package checks](https://github.com/pgajer/ivue/actions/workflows/check.yaml)
cover supported R versions and operating systems as well as browser rendering.

`Rscript tools/render_examples.R` generates runnable HTML examples.
`node tools/browser_smoke.cjs` checks desktop/mobile canvas pixels, rotation,
zoom, console errors, and horizontal overflow with Playwright. Set
`PLAYWRIGHT_MODULE` and optionally `CHROME_PATH` when using external runtimes.
Build products and browser evidence are ignored by Git.

With the migrated gflowui installed, run `Rscript tools/shiny_smoke.R` and, in
another terminal, `node tools/shiny_smoke.cjs` for the Shiny rendering harness.
Stop the harness afterward. It listens on loopback port 4873 by default;
`IVUE_SMOKE_PORT` selects a different port in both scripts.

## Coordinate animations

Play recorded 2D or 3D coordinates with a timeline, speed controls, and an
interactive camera. All frames share vertex identities and viewing bounds;
NA rows represent inactive vertices, and incident edges stay hidden.

Generate a small Sierpinski layout trace with the optional `grip` package
(`install.packages("grip")`):

```r
edges <- grip::edges.sierpinski.triangle(level = 4)
tr <- grip::trace.grip(edges, n = max(edges), dim = 2,
                       preset = "carpet", seed = 1,
                       trace = "round", trace.every = 1)
player <- animate.frames(tr$frames, edges, max.frames = 40, fps = 5)
player
htmlwidgets::saveWidget(player, "triangle.html", selfcontained = TRUE)
# GIF export additionally requires magick; uses the initial orthographic view.
write.animation.gif(player, "triangle.gif", final.hold = 2)
```

Frames are shown without interpolation or coordinate alignment. At most 100
frames are retained by default; use `frame.index` or `max.frames` to change
that selection. GIF export is an orthographic diagram renderer rather than a
WebGL screenshot. See `vignette("animation", package = "ivue")` for Sierpinski
and saddle examples, including trace generation, frame selection, and export.
