# ivue

Interactive 3D visualization of data and graphs in R.

## Status

Version `0.1.0` is the first release candidate for browser-first plotting on `rgl`
null-device scenes. It is independent of `gflow`, `gflowui`, and Shiny. No native
graphics window or XQuartz setup is needed for ordinary plotting. This is not
yet a CRAN release.

```r
install.packages(c("remotes", "rgl"))
remotes::install_github("pgajer/ivue")
```

The current implementation is on `main`. During local development use
`make install` in this repo.
`rgl` is a deferred-loaded suggested dependency so even `pkgload::load_all()`
does not initialize native graphics early. Color mapping works without it;
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
scale <- color.scale.cont(zs, center = 0,
                         palette = c("#2166AC", "#F7F7F7", "#B2182B"))
w <- plot3D.cont(X, values = zs, scale = scale, point.size = 5, axes = TRUE)
w
plot3D.cltrs(X, groups = ifelse(zs >= 0, "Nonnegative", "Negative"))
htmlwidgets::saveWidget(w, "saddle.html", selfcontained = FALSE)
```

All plot functions return an ordinary htmlwidget. There are no `.widget` or
`.html` aliases. Points use `point.size` in screen pixels; spheres use
`point.type = "sphere"` and `sphere.radius` in data units. `highlight` changes
styling without removing rows or refitting scales. Save files separately.

## Weighted Graphs

```r
g <- list(adj.list = list(2L, c(1L, 3L), 2L, integer()),
          weight.list = list(2, c(2, 4), 4, numeric()))
coords <- rbind(c(0, 0, 0), c(1, 1, 0), c(2, 0, 1), c(0, 2, 1))
plot3D.graph(g, X = coords,
             layers = list(layer3D.path(c(1, 2, 3)), layer3D.labels(4, "Isolate")))

# Optional layout requires igraph. No weight inversion is performed.
plot3D.graph(g, layout = "kk", weight.type = "distance")
```

Supported formats: paired adjacency/weight lists, edge tables with explicit
vertices, dense/sparse adjacency matrices, and igraph objects. Vertex identity,
isolates, weights, and table attributes are preserved. Matrices use zero for
absent edges; lists/tables can represent zero-weight edges. This first version
rejects directed rendering, self-loops, and parallel edges explicitly.

Supply coordinates or request a layout, never both. Existing coordinates need
no igraph conversion. `fr` treats weights as strengths; `kk` treats them as
distances. Both require positive layout weights. Custom layout callbacks can
consume the normalized graph without igraph. Coordinate row names, when
present, must match vertex IDs exactly. Values/groups follow graph vertex order.

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

See [MIGRATION_STATUS.md](https://github.com/pgajer/ivue/blob/main/MIGRATION_STATUS.md)
for implemented scope and verification, and
[MIGRATION.md](https://github.com/pgajer/ivue/blob/main/MIGRATION.md) for the specification.
Current release evidence is in
[RELEASE_VALIDATION.md](https://github.com/pgajer/ivue/blob/main/RELEASE_VALIDATION.md);
the [submission checklist](https://github.com/pgajer/ivue/blob/main/CRAN-SUBMISSION-CHECKLIST.md) distinguishes a checked
candidate from a completed CRAN submission.

`Rscript tools/render_examples.R` generates runnable HTML examples.
`node tools/browser_smoke.cjs` checks desktop/mobile canvas pixels, rotation,
zoom, console errors, and horizontal overflow with Playwright. Set
`PLAYWRIGHT_MODULE` and optionally `CHROME_PATH` when using external runtimes.
Build products and browser evidence are ignored by Git.

With the migrated gflowui installed, run `Rscript tools/shiny_smoke.R` and, in
another terminal, `node tools/shiny_smoke.cjs` for the Shiny rendering harness.
Stop the harness afterward. It listens on loopback port 4873 by default;
`IVUE_SMOKE_PORT` selects a different port in both scripts.
