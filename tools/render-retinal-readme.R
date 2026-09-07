#!/usr/bin/env Rscript

# Build the synchronized ivue scenes used by the retinal-development README
# animation. Run from the ivue repository root.
options(rgl.useNULL = TRUE)

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

default.data <- path.expand(paste0(
    "~/current_projects/retinal_development/data/",
    "10x_Mouse_retina_pData_umap2_CellType_annot_w_horiz.csv"
))
data.file <- Sys.getenv("IVUE_RETINAL_DATA", default.data)
if (!file.exists(data.file)) {
    stop("Retinal metadata not found. Set IVUE_RETINAL_DATA to the source CSV path.")
}

out <- file.path("artifacts", "retinal-readme")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("man", "figures"), recursive = TRUE, showWarnings = FALSE)

retina <- utils::read.csv(data.file, check.names = FALSE,
                          stringsAsFactors = FALSE)
needed <- c("age", "umap_coord1", "umap_coord2", "umap_coord3",
            "umap2_CellType")
if (!all(needed %in% names(retina))) {
    stop("The retinal metadata is missing one or more required columns: ",
         paste(setdiff(needed, names(retina)), collapse = ", "))
}
retina <- retina[, needed]
names(retina) <- c("age", "x", "y", "z", "cell.type")
if (any(!stats::complete.cases(retina))) {
    stop("The README source data must have complete coordinates and labels.")
}

age.levels <- c("E11", "E12", "E14", "E16", "E18",
                "P0", "P2", "P5", "P8", "P14")
cell.levels <- c(
    "Early RPCs", "Late RPCs", "Neurogenic Cells",
    "Retinal Ganglion Cells", "Amacrine Cells", "Horizontal Cells",
    "Photoreceptor Precursors", "Cones", "Rods", "Bipolar Cells",
    "Muller Glia"
)
if (!setequal(unique(retina$age), age.levels)) {
    stop("Developmental-stage labels differ from the expected source data.")
}
if (!setequal(unique(retina$cell.type), cell.levels)) {
    stop("Cell-type labels differ from the expected source data.")
}
retina$age <- factor(retina$age, levels = age.levels)
retina$cell.type <- factor(retina$cell.type, levels = cell.levels)

allocate.stratified <- function(groups, target, minimum = 20L) {
    members <- split(seq_along(groups), groups, drop = TRUE)
    sizes <- vapply(members, length, integer(1L))
    if (target >= sum(sizes)) return(sizes)

    allocation <- pmin(sizes, minimum)
    remaining <- target - sum(allocation)
    if (remaining < 0L) {
        stop("Sampling target is too small for the requested stratum minimum.")
    }
    capacity <- sizes - allocation
    if (remaining > 0L) {
        ideal <- remaining * capacity / sum(capacity)
        extra <- pmin(capacity, floor(ideal))
        allocation <- allocation + extra
        left <- target - sum(allocation)
        if (left > 0L) {
            eligible <- which(allocation < sizes)
            order.remainder <- eligible[order(ideal[eligible] - extra[eligible],
                                               decreasing = TRUE)]
            allocation[utils::head(order.remainder, left)] <-
                allocation[utils::head(order.remainder, left)] + 1L
        }
    }
    allocation
}

sample.size <- 12000L
strata <- interaction(retina$age, retina$cell.type, drop = TRUE,
                      lex.order = TRUE)
members <- split(seq_len(nrow(retina)), strata, drop = TRUE)
allocation <- allocate.stratified(strata, sample.size)
set.seed(20190619)
selected <- unlist(Map(function(rows, n) sample(rows, n), members, allocation),
                   use.names = FALSE)
sampled <- retina[selected, , drop = FALSE]
sampled <- sampled[sample(seq_len(nrow(sampled))), , drop = FALSE]
stopifnot(nrow(sampled) == sample.size)

X <- as.matrix(sampled[, c("x", "y", "z")])
X <- sweep(X, 2L, colMeans(X), "-")

age.colors <- stats::setNames(c(
    "#512A84", "#4148A4", "#2E68B4", "#1686B7", "#009FA8",
    "#28B58B", "#67C36B", "#A4C84F", "#D2B943", "#E2873C"
), age.levels)
cell.colors <- stats::setNames(c(
    "#3B6C8E", "#7A5195", "#D45087", "#E45756", "#F58518",
    "#9C755F", "#54A24B", "#72B7B2", "#4C78A8", "#B279A2",
    "#8F9D44"
), cell.levels)

camera <- camera.zup(elevation = 18, turn = -28, fov = 0, zoom = 0.57)
common <- list(point.size = 2.2, alpha = 0.78, axes = FALSE,
               aspect = "equal", camera = camera, width = 520L,
               height = 360L, background.color = "white")
age.scale <- color.scale.groups(sampled$age, colors = age.colors)
cell.scale <- color.scale.groups(sampled$cell.type, colors = cell.colors)
views <- list(
    do.call(plot3D.groups, c(list(X = X, groups = sampled$age,
                                 scale = age.scale, legend.show = FALSE), common)),
    do.call(plot3D.groups, c(list(X = X, groups = sampled$cell.type,
                                 scale = cell.scale, legend.show = FALSE), common))
)
views[[1]]$elementId <- "retina-age"
views[[2]]$elementId <- "retina-cell-type"

frame.count <- 72L
fps <- 10L
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
  .legend-item { display: inline-flex; align-items: center; min-width: 0;
    font-size: 12px; line-height: 1.2; white-space: nowrap; }
  .legend-item i { display: inline-block; width: 10px; height: 10px;
    flex: 0 0 10px; margin-right: 5px; border-radius: 50%; }
  .legend-item b { overflow: hidden; text-overflow: ellipsis; font-weight: 520; }
"

page <- htmltools::tags$html(
    htmltools::tags$head(
        htmltools::tags$title("Mouse retinal development in 3D"),
        htmltools::tags$meta(charset = "utf-8"),
        htmltools::tags$style(htmltools::HTML(css))
    ),
    htmltools::tags$body(
        htmltools::tags$main(id = "hero",
            htmltools::tags$header(
                htmltools::tags$h1("Mouse retinal development in 3D"),
                htmltools::tags$p(sprintf(
                    "%s-cell stratified sample from %s single-cell transcriptomes",
                    format(sample.size, big.mark = ","),
                    format(nrow(retina), big.mark = ",")
                ))
            ),
            htmltools::tags$div(id = "panels",
                htmltools::tags$section(
                    htmltools::tags$h2("Developmental stage"),
                    htmltools::tags$div(class = "scene", views[[1]]),
                    legend.tags(age.colors, "legend-age")
                ),
                htmltools::tags$section(
                    htmltools::tags$h2("Annotated cell type"),
                    htmltools::tags$div(class = "scene", views[[2]]),
                    legend.tags(cell.colors, "legend-cell")
                )
            )
        ),
        htmltools::tags$script(htmltools::HTML(adapter))
    )
)

html.file <- file.path(out, "retinal-development.html")
htmltools::save_html(page, html.file, libdir = "retinal-libs")
writeLines(c(
    "Generated by: Rscript tools/render-retinal-readme.R",
    paste("Source:", normalizePath(data.file)),
    paste("Source MD5:", unname(tools::md5sum(data.file))),
    paste("Source rows:", nrow(retina)),
    paste("Sample rows:", sample.size),
    "Sampling: age-by-cell-type strata; minimum 20 cells per nonempty stratum; seed 20190619",
    paste("ivue:", as.character(utils::packageVersion("ivue"))),
    paste("rgl:", as.character(utils::packageVersion("rgl"))),
    sprintf("Animation: %d frames; %d fps; %.1f seconds; synchronized orthographic cameras",
            frame.count, fps, frame.count / fps)
), file.path(out, "provenance.txt"))
message("Wrote ", html.file)
