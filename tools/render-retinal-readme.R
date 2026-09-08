#!/usr/bin/env Rscript

# Build synchronized ivue views of one retinal-development representation.
options(rgl.useNULL = TRUE)

args <- commandArgs(trailingOnly = TRUE)
view.arg <- grep("^--view=", args, value = TRUE)
if (length(view.arg) != 1L) {
    stop("Supply exactly one of --view=sknn, --view=umap, or --view=comparison.")
}
view <- sub("^--view=", "", view.arg)
if (!view %in% c("sknn", "umap", "comparison")) {
    stop("Unknown retinal view: ", view)
}

if (!file.exists("DESCRIPTION")) {
    stop("Run this script from the ivue repository root.")
}
if (!requireNamespace("pkgload", quietly = TRUE)) {
    stop("Package 'pkgload' is required to render the README animation.")
}
for (package in c("htmltools", "jsonlite", "rgl")) {
    if (!requireNamespace(package, quietly = TRUE)) {
        stop(sprintf("Package '%s' is required to render the README animation.", package))
    }
}

pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)

out <- file.path("artifacts", "retinal-readme")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("man", "figures"), recursive = TRUE, showWarnings = FALSE)

layout.file <- Sys.getenv(
    "IVUE_RETINAL_LAYOUT",
    file.path(out, "retinal-sknn-layout.rds")
)
if (!file.exists(layout.file)) {
    stop("Prepared retinal graph not found. Run tools/prepare-retinal-readme.R first.")
}
retinal <- readRDS(layout.file)
needed <- c(
    "coordinates", "graph", "metadata", "k.selection", "input", "layout",
    "source.paths", "fitting.graph"
)
if (!all(needed %in% names(retinal))) {
    stop("The prepared retinal graph is missing required fields.")
}
if (retinal$fitting.graph$vertices != 120804L ||
    retinal$k.selection$selected != 4L) {
    stop("Rebuild the full-population k = 4 layout before rendering these views.")
}
sampled <- retinal$metadata
sknn.X <- retinal$coordinates
if (view == "sknn") {
    X <- sknn.X
} else {
    metadata.file <- Sys.getenv(
        "IVUE_RETINAL_DATA", retinal$source.paths[["metadata"]]
    )
    if (!file.exists(metadata.file)) {
        stop("Retinal UMAP metadata not found: ", metadata.file)
    }
    source <- utils::read.csv(
        metadata.file, row.names = 1L, check.names = FALSE,
        stringsAsFactors = FALSE
    )
    columns <- c("umap_coord1", "umap_coord2", "umap_coord3")
    if (!all(columns %in% names(source))) {
        stop("Retinal metadata does not contain the published 3D UMAP coordinates.")
    }
    selected <- match(rownames(sampled), rownames(source))
    if (anyNA(selected) || anyDuplicated(selected)) {
        stop("Prepared graph cells do not map uniquely to the UMAP metadata.")
    }
    if (!identical(source$age[selected], as.character(sampled$age)) ||
        !identical(source$umap2_CellType[selected], as.character(sampled$cell.type))) {
        stop("UMAP labels do not match the prepared graph sample.")
    }
    X <- as.matrix(source[selected, columns, drop = FALSE])
    X <- sweep(X, 2L, colMeans(X), "-")
    rownames(X) <- rownames(sampled)
}
valid.coordinates <- function(X) {
    is.matrix(X) && ncol(X) == 3L && nrow(X) == nrow(sampled) &&
        all(is.finite(X))
}
if (!valid.coordinates(X) ||
    (view == "comparison" && !valid.coordinates(sknn.X))) {
    stop("Every retinal coordinate set must be a finite n-by-3 matrix.")
}

age.levels <- c("E11", "E12", "E14", "E16", "E18",
                "P0", "P2", "P5", "P8", "P14")
cell.levels <- c(
    "Early RPCs", "Late RPCs", "Neurogenic Cells",
    "Retinal Ganglion Cells", "Amacrine Cells", "Horizontal Cells",
    "Photoreceptor Precursors", "Cones", "Rods", "Bipolar Cells",
    "Muller Glia"
)
if (!setequal(unique(sampled$age), age.levels)) {
    stop("Developmental-stage labels differ from the expected source data.")
}
if (!setequal(unique(sampled$cell.type), cell.levels)) {
    stop("Cell-type labels differ from the expected source data.")
}
sampled$age <- factor(sampled$age, levels = age.levels)
sampled$cell.type <- factor(sampled$cell.type, levels = cell.levels)
sample.size <- nrow(sampled)

age.colors <- stats::setNames(c(
    "#512A84", "#4148A4", "#2E68B4", "#1686B7", "#009FA8",
    "#28B58B", "#67C36B", "#A4C84F", "#D2B943", "#E2873C"
), age.levels)
cell.colors <- stats::setNames(c(
    "#3B6C8E", "#7A5195", "#D45087", "#E45756", "#F58518",
    "#9C755F", "#54A24B", "#72B7B2", "#4C78A8", "#B279A2",
    "#8F9D44"
), cell.levels)

point.size <- if (view == "sknn") 2.1 else 2.2
alpha <- if (view == "sknn") 0.84 else 0.78
camera <- camera.zup(elevation = 18, turn = -28, fov = 0, zoom = 0.64)
common <- list(point.size = point.size, alpha = alpha, axes = FALSE,
               aspect = "equal", camera = camera, width = 520L,
               height = 360L, background.color = "white")
age.scale <- color.scale.groups(sampled$age, colors = age.colors)
cell.scale <- color.scale.groups(sampled$cell.type, colors = cell.colors)
make.view <- function(X, groups, scale, edges = FALSE) {
    plot.args <- list(
        X = X, groups = groups, scale = scale, legend.show = FALSE
    )
    if (edges) {
        plot.args <- c(list(
            graph = retinal$graph, vertices = rownames(X),
            weight.type = "distance", edge.col = "#59687324", edge.width = 1
        ), plot.args)
        do.call(plot3D.graph, c(plot.args, common))
    } else {
        do.call(plot3D.groups, c(plot.args, common))
    }
}
if (view == "comparison") {
    views <- list(
        make.view(X, sampled$age, age.scale),
        make.view(sknn.X, sampled$age, age.scale)
    )
    panel.titles <- c("Published 3D UMAP (Canberra)", "sKNN k = 4 (Euclidean)")
} else {
    views <- list(
        make.view(X, sampled$age, age.scale),
        make.view(X, sampled$cell.type, cell.scale)
    )
    panel.titles <- c("Developmental stage", "Annotated cell type")
}
views[[1]]$elementId <- "retina-age"
views[[2]]$elementId <- "retina-cell-type"

frame.count <- 72L
fps <- if (view == "comparison") 5L else 10L
angles <- (seq_len(frame.count) - 1L) * 360 / frame.count
matrices <- lapply(angles, function(angle) as.vector(
    camera.zup(elevation = 18, turn = -28 + angle,
               fov = 0, zoom = 0.57)$userMatrix
))
config <- jsonlite::toJSON(list(
    scenes = I(vapply(views, `[[`, "", "elementId")),
    matrices = matrices,
    fps = fps
), auto_unbox = TRUE, digits = 15)

legend.tags <- function(colors, class = NULL) {
    htmltools::tags$div(class = paste("legend", class),
        Map(function(label, color) htmltools::tags$span(
            class = "legend-item",
            htmltools::tags$i(style = paste0("background:", color)),
            htmltools::tags$b(label)
        ), names(colors), unname(colors)))
}

adapter <- paste0("(function() { const config = ", config, ";
  function connect() {
    const scenes = config.scenes.map(id => document.getElementById(id)?.rglinstance);
    if (scenes.some(scene => !scene)) { setTimeout(connect, 40); return; }
    function setFrame(value) {
      const frame = ((Math.round(value) % config.matrices.length) +
        config.matrices.length) % config.matrices.length;
      scenes.forEach(scene => {
        scene.getObj(scene.scene.rootSubscene).par3d.userMatrix.load(config.matrices[frame]);
        scene.drawScene();
      });
      document.body.dataset.frame = String(frame);
    }
    window.retinalHero = {scenes, matrices: config.matrices,
      frameCount: config.matrices.length, fps: config.fps, setFrame};
    setFrame(0);
    document.body.dataset.ready = 'true';
  }
  connect();
})();")

css <- "
  * { box-sizing: border-box; }
  html, body { margin: 0; background: #ffffff; color: #202830; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    letter-spacing: 0; }
  #hero { width: 1080px; padding: 22px 24px 18px; background: #ffffff; }
  header { text-align: center; margin-bottom: 8px; }
  h1 { margin: 0; font-size: 28px; line-height: 1.2; font-weight: 680; }
  header p { margin: 5px 0 0; color: #5a6670; font-size: 15px; }
  #panels { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 20px; }
  section { min-width: 0; }
  h2 { margin: 2px 0 0; text-align: center; font-size: 18px;
    line-height: 1.2; font-weight: 620; }
  .scene { width: 100%; height: 360px; overflow: hidden; }
  .scene .html-widget, .scene .rglWebGL { width: 100% !important;
    height: 360px !important; }
  .legend { display: grid; align-items: center; gap: 5px 10px;
    margin: 1px auto 0; color: #35414a; }
  .legend-age { grid-template-columns: repeat(5, max-content); justify-content: center; }
  .legend-cell { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .legend-shared { margin-top: 4px; }
  .legend-item { display: inline-flex; align-items: center; min-width: 0;
    font-size: 12px; line-height: 1.2; white-space: nowrap; }
  .legend-item i { display: inline-block; width: 10px; height: 10px;
    flex: 0 0 10px; margin-right: 5px; border-radius: 50%; }
  .legend-item b { overflow: hidden; text-overflow: ellipsis; font-weight: 520; }
"

page.title <- if (view == "sknn") {
    "Whole-population retinal graph layout"
} else if (view == "comparison") {
    "The same retinal cells in two 3D embeddings"
} else {
    "Mouse retinal development as a 3D point cloud"
}
page.subtitle <- if (view == "sknn") {
    sprintf(
        "120,804-cell fit | %s displayed | symmetric %d-NN | weighted-GRIP + edge-KK",
        format(sample.size, big.mark = ","), retinal$k.selection$selected
    )
} else if (view == "comparison") {
    sprintf(
        "120,804-cell fitting population | %s displayed | vertices only",
        format(sample.size, big.mark = ",")
    )
} else {
    sprintf(
        "%s-cell sample | published 3D UMAP coordinates",
        format(sample.size, big.mark = ",")
    )
}

panel.legends <- if (view == "comparison") {
    list(NULL, NULL)
} else {
    list(legend.tags(age.colors, "legend-age"),
         legend.tags(cell.colors, "legend-cell"))
}
sections <- Map(function(title, widget, legend) {
    htmltools::tags$section(
        htmltools::tags$h2(title),
        htmltools::tags$div(class = "scene", widget),
        legend
    )
}, panel.titles, views, panel.legends)
shared.legend <- if (view == "comparison") {
    legend.tags(age.colors, "legend-age legend-shared")
} else {
    NULL
}

page <- htmltools::tags$html(
    htmltools::tags$head(
        htmltools::tags$title(page.title),
        htmltools::tags$meta(charset = "utf-8"),
        htmltools::tags$style(htmltools::HTML(css))
    ),
    htmltools::tags$body(
        htmltools::tags$main(id = "hero",
            htmltools::tags$header(
                htmltools::tags$h1(page.title),
                htmltools::tags$p(page.subtitle)
            ),
            htmltools::tags$div(id = "panels", htmltools::tagList(sections)),
            shared.legend
        ),
        htmltools::tags$script(htmltools::HTML(adapter))
    )
)

html.file <- file.path(out, paste0("retinal-", view, ".html"))
htmltools::save_html(page, html.file, libdir = "retinal-libs")
view.provenance <- if (view == "sknn") c(
    "Input: first 20 PCs of log10(CPT + 1) for the published 3,290 high-variance genes",
    "Graph: Euclidean symmetric kNN via dgraphs; topology is not computed from UMAP coordinates",
    paste("k selection:", retinal$k.selection$rule),
    paste("Selected k:", retinal$k.selection$selected),
    paste("Graph edges:", nrow(retinal$graph$edge.matrix)),
    paste("Full fitting graph edges:", retinal$fitting.graph$edges),
    "Rendering: vertices only; layout fitted before display subsampling",
    paste("Layout:", retinal$layout$method),
    paste("Zero-length edges floored for layout:", retinal$layout$zero.edge.count)
) else if (view == "comparison") c(
    "Left input: published three-dimensional UMAP coordinates (Canberra distance)",
    "Right input: weighted-GRIP plus edge-KK coordinates for the Euclidean symmetric kNN graph",
    paste("Source metadata:", normalizePath(metadata.file)),
    "Rendering: matched ivue point clouds; no graph edges"
) else c(
    "Input: published three-dimensional UMAP coordinates",
    paste("Source metadata:", normalizePath(metadata.file)),
    "Rendering: ivue point cloud; no graph edges"
)
writeLines(c(
    paste("View:", view),
    view.provenance,
    paste("Generated by: Rscript tools/render-retinal-readme.R --view=", view,
          sep = ""),
    paste("Prepared graph:", normalizePath(layout.file)),
    paste("PCA fitting rows:", retinal$input$cells),
    paste("Retained retinal rows:", retinal$input$retained.cells),
    paste("Sample rows:", sample.size),
    "Sampling: age-by-cell-type strata; minimum 20 cells per nonempty stratum; seed 20190619",
    paste("ivue:", as.character(utils::packageVersion("ivue"))),
    paste("rgl:", as.character(utils::packageVersion("rgl"))),
    sprintf("Animation: %d frames; %d fps; %.1f seconds; synchronized orthographic cameras",
            frame.count, fps, frame.count / fps)
), file.path(out, paste0("provenance-", view, ".txt")))
message("Wrote ", html.file)
