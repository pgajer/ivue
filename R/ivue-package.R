#' ivue: Interactive 3D Visualization of Data and Graphs
#'
#' Explore three-dimensional point clouds and embedded graphs with numerical
#' or categorical annotations, reusable color scales, and geometric layers.
#'
#' @section Getting started:
#' Install both the package and its optional plotting backend with
#' `install.packages(c("ivue", "rgl"))`. Plotting requires rgl, while color
#' mapping and [prepare.graph()] work without it. No XQuartz setup is required.
#'
#' [plot3D.plain()] shows a point cloud, [plot3D.cont()] maps numerical values,
#' and [plot3D.groups()] maps categorical annotations. Each returns a browser
#' widget. Printing it in RStudio opens the Viewer; in an interactive R console
#' it opens the browser. Function execution itself does not launch a browser.
#' Use `htmlwidgets::saveWidget()` to export HTML for later viewing or sharing.
#'
#' [prepare.graph()] exposes IDs, edge order, and attributes before rendering.
#' [plot3D.graph()] accepts that object with supplied coordinates or an explicit
#' layout. Weights do not automatically control edge width or color.
#'
#' @section Guides:
#' Five installed vignettes provide complementary starting points:
#' \itemize{
#' \item `vignette("function-guide", package = "ivue")`: task-oriented function catalog.
#' \item `vignette("example-data", package = "ivue")`: reproducible inputs and reusable recipes.
#' \item `vignette("ivue-introduction", package = "ivue")`: detailed plotting controls.
#' \item `vignette("retinal-development", package = "ivue")`: data provenance and case study.
#' \item `vignette("animation", package = "ivue")`: recorded frames and export.
#' }
#'
#' @section Rendering:
#' Widgets use private rgl null-device scenes. The rgl namespace is loaded only
#' when rendering; caller options and the previous device are restored.
#' See `vignette("ivue-introduction", package = "ivue")` for worked examples.
#'
#' @keywords internal
"_PACKAGE"
