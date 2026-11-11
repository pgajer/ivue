#!/usr/bin/env Rscript
# Render saved scientific coordinates; this script never fits an embedding.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% c(3L, 4L)) stop("Usage: Rscript tools/render-retinal-sgd-comparison.R LEFT.rds RIGHT.rds OUTPUT_DIRECTORY [PROCRUSTES_ALIGNMENT.rds]")
if (!file.exists("DESCRIPTION")) stop("Run from the ivue repository root.")
options(rgl.useNULL = TRUE)
pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)
source("tools/retinal-view-orientation.R")
inputs <- normalizePath(args[1:2], mustWork = TRUE)
out <- args[3]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out)
fits <- lapply(inputs, readRDS)
metadata <- readRDS("artifacts/retinal-readme/retinal-sknn-layout.rds")$metadata
stopifnot(identical(fits[[1]]$cells, fits[[2]]$cells),
          identical(fits[[1]]$display.ids, fits[[2]]$display.ids),
          identical(fits[[1]]$graph.sha256, fits[[2]]$graph.sha256))
index <- match(fits[[1]]$display.ids, rownames(metadata))
stopifnot(!anyNA(index), !anyDuplicated(index), length(index) == 12000L)
metadata <- metadata[index, , drop = FALSE]
for (fit in fits) {
    stopifnot(nrow(fit$coordinates) == 120804L,
              identical(fit$cells[fit$display.indices], fit$display.ids),
              identical(unname(fit$coordinates[fit$display.indices, , drop = FALSE]),
                        unname(fit$display.coordinates)))
}
camera <- camera.zup(elevation = 18, turn = -28, fov = 0, zoom = 0.5)
alignment <- NULL
if (length(args) == 4L) {
    alignment <- readRDS(args[4])
    stopifnot(identical(unname(alignment$input.sha256), unname(vapply(inputs,
        function(p) digest::digest(file = p, algo = "sha256"), ""))),
        identical(alignment$cells, fits[[1]]$cells),
        identical(dim(alignment$aligned), dim(fits[[2]]$coordinates)),
        all(is.finite(alignment$aligned)))
    first <- orient.retinal.stage(fits[[1]]$display.coordinates, metadata$age, camera)
    center <- colMeans(fits[[1]]$display.coordinates)
    # Apply one common display rotation after the full-population alignment.
    second <- sweep(alignment$aligned[fits[[2]]$display.indices, , drop = FALSE],
                    2L, center, "-") %*% t(first$rotation)
    oriented <- list(first, list(coordinates = second, rotation = first$rotation,
        common.reference.center = center, orientation = "same rotation as reference"))
} else {
    oriented <- lapply(fits, function(fit)
        orient.retinal.stage(fit$display.coordinates, metadata$age, camera))
}
# One shared isotropic display scale retains relative sizes between the fits.
radius <- max(vapply(oriented, function(x)
    max(sqrt(rowSums(x$coordinates^2))), numeric(1)))
coordinates <- lapply(oriented, function(x) x$coordinates / radius)
alignment.display.error <- NULL
if (!is.null(alignment)) {
    expected <- sqrt(rowSums((alignment$aligned[fits[[2]]$display.indices, , drop = FALSE] -
                              fits[[1]]$display.coordinates)^2))
    actual <- sqrt(rowSums((coordinates[[2]] - coordinates[[1]])^2)) * radius
    alignment.display.error <- max(abs(actual - expected))
    stopifnot(alignment.display.error < 1e-10 * max(1, max(expected)))
}
limits <- matrix(c(-1, 1), 3, 2, byrow = TRUE)
age.levels <- c("E11", "E12", "E14", "E16", "E18", "P0", "P2", "P5", "P8", "P14")
colors <- setNames(c("#512A84", "#4148A4", "#2E68B4", "#1686B7", "#009FA8",
                     "#28B58B", "#67C36B", "#A4C84F", "#D2B943", "#E2873C"), age.levels)
age <- factor(metadata$age, levels = age.levels)
stopifnot(!anyNA(age))
scale <- color.scale.groups(age, colors = colors)
titles <- vapply(fits, function(fit) sprintf("%d pivots / %d SGD passes",
    fit$fit.settings$n.pivots, fit$fit.settings$max_iter), "")
different.pivots <- fits[[1]]$fit.settings$n.pivots != fits[[2]]$fit.settings$n.pivots
comparison.note <- if (different.pivots)
    "Stochastic gradient descent (SGD) fits sparse graph-distance constraints. Pivots select the additional long-range constraints. Pivot count and pass count both change here, so this comparison does not isolate their separate effects." else
    "The pivot count is fixed. Both fits use the same seed and hybrid learning-rate schedule settings, stretched across the requested number of passes. This compares fresh fits, not continuation of the shorter run."
alignment.note <- if (is.null(alignment)) NULL else sprintf(
    "After full-population similarity Procrustes alignment, RMS displacement is %.2f%% of the reference cloud's RMS radius. The candidate is uniformly rescaled by %.6f; %s.",
    100 * alignment$transform$normalized.rms, alignment$transform$scale,
    if (alignment$transform$reflection.used) "the optimal alignment includes a reflection" else "the optimal alignment does not require a reflection")
orientation.note <- if (is.null(alignment))
    "The displayed cells are selected only after fitting the full population. Each display is centered and independently rotated, without reflection, to face the P14 centroid toward the camera. Both use one shared isotropic scale and identical bounds. These are orientation conventions, not anatomical registration or evidence that either layout recovers true geometry." else
    "Similarity Procrustes alignment minimizes the sum of squared displacements over all 120,804 matching cells, allowing translation, rotation or reflection, and one uniform scale. The 12,000 display cells are then selected. Both aligned clouds receive the same P14-facing reference rotation, common display scale, and identical bounds. No independent rotation is applied afterward. RMS radius means the square root of the mean squared distance from the reference centroid. Alignment measures agreement between fits, not agreement with true geometry."
widgets <- lapply(seq_along(fits), function(i) {
    w <- plot3D.groups(coordinates[[i]], age, scale = scale, legend.show = FALSE,
        point.size = 2.2, alpha = 0.82, axes = FALSE, aspect = "equal",
        camera = camera, limits = limits, width = NULL, height = 500L,
        controls = FALSE, description = paste(titles[i], ": 12,000 retinal cells colored by developmental stage."))
    w$elementId <- paste0("retinal-sgd-", i)
    w
})
tags <- htmltools::tags
button <- function(id, symbol, label) tags$button(id = id, type = "button",
    title = label, `aria-label` = label, htmltools::HTML(symbol))
legend <- tags$div(class = "legend", `aria-label` = "Developmental stage",
    Map(function(label, color) tags$span(tags$i(style = paste0("background:", color)), label),
        names(colors), unname(colors)))
document <- tags$html(lang = "en",
    tags$head(tags$title("Retinal development: two sparse-SGD embeddings"),
        tags$meta(charset = "utf-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
        tags$style(htmltools::HTML(paste(readLines("tools/retinal-sgd-comparison.css"), collapse = "\n")))),
    tags$body(tags$main(
        tags$header(tags$p(class = "eyebrow", "Retinal development / full-population fits"),
            tags$h1(if (is.null(alignment)) "Two sparse-SGD embeddings" else "Procrustes-aligned sparse-SGD embeddings"),
            tags$p(class = "intro", "Both fits use the same 120,804-cell Euclidean symmetric 4-nearest-neighbor graph. The same 12,000 cells are displayed below; neither fit includes edge-KK refinement.")),
        tags$div(class = "toolbar", role = "toolbar", `aria-label` = "Linked camera controls",
            tags$div(class = "buttons",
                button("rotate-left", "&#8592;", "Rotate both views left"),
                button("rotate-right", "&#8594;", "Rotate both views right"),
                button("rotate-up", "&#8593;", "Rotate both views up"),
                button("rotate-down", "&#8595;", "Rotate both views down"),
                button("zoom-in", "+", "Zoom both views in"),
                button("zoom-out", "&#8722;", "Zoom both views out"),
                button("reset", "&#8634;", "Reset both views"),
                button("play", "&#9654;", "Start synchronized rotation")),
            tags$span(class = "camera-note", if (is.null(alignment))
                "Shared scale / P14-facing initial view" else "Procrustes aligned / shared framing")),
        tags$div(class = "views", lapply(seq_along(widgets), function(i)
            tags$section(class = "view", `aria-labelledby` = paste0("title-", i),
                tags$h2(id = paste0("title-", i), titles[i]), widgets[[i]]))),
        tags$div(class = "legend-band", tags$strong("Developmental stage"), legend),
        if (!is.null(alignment.note)) tags$p(class = "note", alignment.note),
        tags$p(class = "note", comparison.note),
        tags$details(tags$summary("Data and comparison conditions"),
            tags$p("Clark et al. (2019) mouse retinal development data; the frozen graph uses Euclidean distances on the same 20-PC matrix as the preceding experiment. It has 374,597 undirected edges and one connected component. Both runs use one random initialization with seed 20190619, inverse-squared pair weights, and the same hybrid learning-rate schedule."),
            tags$p(orientation.note)),
        tags$noscript(tags$p("JavaScript and WebGL are required for the interactive views.")),
        tags$footer("Retinal embedding comparison under the conditions stated above.")),
        tags$script(htmltools::HTML(paste(readLines("tools/retinal-sgd-comparison.js"), collapse = "\n")))))
htmltools::save_html(document, file.path(out, "comparison-with-dependencies.html"),
                     libdir = file.path(out, "lib"))
template <- normalizePath("tools/retinal-sgd-template.html", mustWork = TRUE)
# A raw block preserves widget scripts without parsing their contents as Markdown.
writeLines(c("```{=html}", readLines(file.path(out, "comparison-with-dependencies.html")), "```"),
           file.path(out, "comparison-embed.md"))
rmarkdown::pandoc_convert(file.path(out, "comparison-embed.md"),
    from = "markdown", to = "html", output = file.path(out, "retinal-sgd-comparison.html"),
    options = c("--standalone", "--embed-resources", "--template",
                template))
jsonlite::write_json(list(inputs = inputs,
    input.sha256 = vapply(inputs, function(p) digest::digest(file = p, algo = "sha256"), ""),
    graph.sha256 = fits[[1]]$graph.sha256,
    displayed.ids.sha256 = digest::digest(fits[[1]]$display.ids, algo = "sha256"),
    common.display.radius = radius, camera = camera, limits = limits,
    alignment.display.max.displacement.error = alignment.display.error,
    alignment = if (is.null(alignment)) NULL else list(file = normalizePath(args[4]),
        sha256 = digest::digest(file = args[4], algo = "sha256"), method = alignment$method,
        transform = alignment$transform),
    orientation = lapply(oriented, function(x) x[setdiff(names(x), "coordinates")]),
    generated = format(Sys.time(), tz = "UTC")),
    file.path(out, "render-provenance.json"), auto_unbox = TRUE, pretty = TRUE, digits = 16)
saveRDS(list(coordinates = coordinates, ids = fits[[1]]$display.ids,
             common.display.radius = radius, alignment = !is.null(alignment)),
        file.path(out, "display-coordinates.rds"))
cat("Wrote", file.path(out, "retinal-sgd-comparison.html"), "\n")
