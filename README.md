# ivue

**ivue** is an R package for interactive three-dimensional visualization of data
and embedded graphs. Combine point clouds and graph edges with numerical or
categorical colors, labels, paths, and surfaces; explore them in RStudio or a
web browser; and share them as interactive HTML. Reusable color scales and
camera controls keep related views consistent, while coordinate animations
let you follow a changing shape or recorded layout. ivue works with coordinates
from your chosen analysis or embedding method.

The following animation shows the same 12,000 mouse retinal cells colored by
developmental stage and annotated cell type. Shared coordinates and synchronized
views show how the two annotations relate. The data come from
[Clark et al. (2019)](https://pmc.ncbi.nlm.nih.gov/articles/PMC6768831/);
the layout was computed with `dgraphs` and `grip`, then rendered with ivue.
The [retinal-development vignette](vignettes/retinal-development.Rmd) presents
the complete example and its provenance, while the
[introduction vignette](vignettes/ivue-introduction.Rmd) explains the plotting
controls.

![Two synchronized point-only views of 12,000 retinal cells extracted after fitting a symmetric 4-nearest-neighbor graph layout on all 120,804 cells, colored by developmental stage and annotated cell type.](https://raw.githubusercontent.com/pgajer/ivue/302f7095c6e513e4ea1fd1d48099c8c7885f1d19/man/figures/readme-retinal-sknn.gif)

## Get Started

To create your own views, install ivue from GitHub. This also builds the three
vignettes for reading from R; `knitr`, `rmarkdown`, and Pandoc are needed for
that step. RStudio includes Pandoc.

```r
install.packages(c("remotes", "rgl", "knitr", "rmarkdown"))
remotes::install_github("pgajer/ivue", build_vignettes = TRUE)
```

Start with a coordinate matrix, one observation per row. This sample from a
saddle is colored by height:

```r
library(ivue)
set.seed(1)
x <- runif(250, -1, 1)
y <- runif(250, -1, 1)
X <- cbind(x = x, y = y, z = 1.2 * (x^2 - y^2))
plot3D.cont(X, values = X[, "z"], legend.title = "Saddle height")
```

The plot opens in RStudio's Viewer or your browser, where you can rotate and
zoom it. No native graphics window or XQuartz setup is needed. Assign the
returned widget to a variable to reuse it or save it with
`htmlwidgets::saveWidget()`.

## Three Embeddings of Retinal Development

The same plotting controls also let you compare coordinate systems while
keeping observations and colors fixed. Below, the retinal cells appear in
published UMAP coordinates, a symmetric-kNN graph layout fitted with
weighted-GRIP followed by edge-KK refinement, and a PHATE embedding.

![Three synchronized point-only views of the same 12,000 retinal cells in published UMAP, symmetric-kNN weighted-GRIP plus edge-KK, and PHATE coordinates, colored by developmental stage and initially oriented with their P14 centroids toward the viewer.](https://raw.githubusercontent.com/pgajer/ivue/a2c26a5dd60a5b110a8291a686c58c6a1f43920f/man/figures/readme-retinal-phate-comparison.gif)

All three embeddings were fitted on **120,804 cells** before selecting the same
12,000 retained retinal cells for display. UMAP uses **Canberra distance**;
the symmetric 4-nearest-neighbor graph and PHATE use **Euclidean distance**.
PHATE uses 2,000 spectral landmarks and an automatically selected diffusion
time. All panels show points without edges and complete a rotation in
14.4 seconds, starting with their P14 centroids facing the viewer. ivue
renders the supplied coordinates without computing the embeddings.

## Learn More

The vignettes develop these examples and show how to adapt them to your data:

- [Point clouds and weighted graphs](vignettes/ivue-introduction.Rmd): colors,
  highlighting, meshes and reference surfaces, graph inputs, cameras, and HTML
  export.
- [Retinal-development case study](vignettes/retinal-development.Rmd): reproduce
  the point-cloud and graph views using the bundled data, with shared palettes
  and the full data and embedding provenance.
- [Coordinate animations](vignettes/animation.Rmd): generate and play a
  Sierpinski layout trace, animate changing surfaces, and export HTML or GIFs.

The links above show the source guides on GitHub. Open the rendered guides
from your installation with:

```r
vignette("ivue-introduction", package = "ivue")
vignette("retinal-development", package = "ivue")
vignette("animation", package = "ivue")
```

Report problems or suggest improvements in the
[issue tracker](https://github.com/pgajer/ivue/issues).
