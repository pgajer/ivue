# ivue

Interactive 3D visualization of data and graphs in R.

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
the original parameter plane. `geometry` is an optional external tool, not a
base R package or an ivue dependency. The complete plotting recipe is in
[`tools/saddle-delaunay.R`](tools/saddle-delaunay.R). The mesh is a display
overlay; it does not change any graph used for fitting or scoring.

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
