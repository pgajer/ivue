.point.style <- function(style, defaults) {
    .named.list(style, c("point.type", "point.size", "sphere.radius", "col", "alpha"), "style")
    out <- utils::modifyList(defaults, style)
    out$point.type <- match.arg(out$point.type, c("point", "sphere"))
    .scalar(out$point.size, "point.size", .Machine$double.eps)
    if (!is.null(out$sphere.radius)) .scalar(out$sphere.radius, "sphere.radius", .Machine$double.eps)
    .scalar(out$alpha, "alpha", 0, 1)
    out
}

.draw.points <- function(X, rows, colors, style) {
    if (!length(rows)) return(data.frame(row = integer(), object = integer(), index = integer()))
    col <- if (is.null(style$col)) colors[rows] else .colors(style$col, nrow(X))[rows]
    material <- .material.colors(col, style$alpha)
    id <- if (style$point.type == "point") {
        rgl::points3d(X[rows, , drop = FALSE], col = material$col,
                      alpha = material$alpha, size = style$point.size, lit = FALSE)
    } else {
        radius <- style$sphere.radius
        if (is.null(radius)) {
            span <- max(apply(X, 2, function(x) diff(range(x))))
            radius <- max(1e-8, span * 0.01)
        }
        rgl::spheres3d(X[rows, , drop = FALSE], col = material$col,
                       alpha = material$alpha, radius = radius)
    }
    data.frame(row = rows, object = as.integer(id), index = seq_along(rows))
}

.scene <- function(X, colors, point.type, point.size, sphere.radius, alpha,
                   highlight, highlight.style, non.highlight.style, axes,
                   xlab, ylab, zlab, aspect, camera, width, height,
                   background.color, layers, shiny.brush) {
    X <- .coordinates(X)
    n <- nrow(X)
    colors <- .colors(colors, n)
    .flag(axes, "axes")
    for (nm in c("xlab", "ylab", "zlab")) .text(get(nm), nm)
    aspect <- match.arg(aspect, c("equal", "normalized"))
    if (!is.null(width)) .scalar(width, "width", 1, Inf, TRUE)
    .scalar(height, "height", 1, Inf, TRUE)
    .colors(background.color, 1, "background.color")
    if (!is.list(layers) || inherits(layers, "ivue_layer"))
        .stop("layers must be a list of layer3D specifications.")
    if (is.null(highlight)) highlight <- rep(TRUE, n)
    else if (is.logical(highlight)) {
        if (length(highlight) != n || anyNA(highlight))
            .stop("Logical highlight must have one nonmissing entry per row.")
    } else {
        selected <- .indices(highlight, n, "highlight")
        highlight <- seq_len(n) %in% selected
    }
    defaults <- .point.style(list(), list(point.type = point.type, point.size = point.size,
                sphere.radius = sphere.radius, alpha = alpha, col = NULL))
    selected.style <- .point.style(highlight.style, defaults)
    other.style <- .point.style(non.highlight.style, defaults)
    if (!is.null(selected.style$col)) .colors(selected.style$col, n, "highlight.style$col")
    if (!is.null(other.style$col)) .colors(other.style$col, n, "non.highlight.style$col")
    .named.list(camera, c("theta", "phi", "fov", "zoom", "userMatrix"), "camera")
    for (nm in setdiff(names(camera), "userMatrix")) .scalar(camera[[nm]], paste0("camera$", nm))
    if (!is.null(camera$fov)) .scalar(camera$fov, "camera$fov", 0, 179)
    if (!is.null(camera$zoom)) .scalar(camera$zoom, "camera$zoom", .Machine$double.eps)
    if (!is.null(camera$userMatrix) && (!is.matrix(camera$userMatrix) ||
        !identical(dim(camera$userMatrix), c(4L, 4L)) || !is.numeric(camera$userMatrix) ||
        any(!is.finite(camera$userMatrix)))) .stop("camera$userMatrix must be a finite 4 x 4 matrix.")

    # This option must precede the first namespace load, not just open3d().
    old.options <- options(rgl.useNULL = TRUE)
    on.exit(options(old.options), add = TRUE)
    if (!requireNamespace("rgl", quietly = TRUE))
        .stop("Plotting requires rgl. Install it with install.packages('rgl').")
    existing.devices <- rgl::rgl.dev.list()
    previous <- rgl::cur3d()
    previous.subscene <- if (previous) rgl::currentSubscene3d() else 0L
    device <- rgl::open3d(useNULL = TRUE, silent = TRUE)
    on.exit({
        for (owned in setdiff(rgl::rgl.dev.list(), existing.devices))
            try(rgl::close3d(owned), silent = TRUE)
        if (previous %in% rgl::rgl.dev.list()) {
            rgl::set3d(previous, silent = TRUE)
            try(rgl::useSubscene3d(previous.subscene), silent = TRUE)
        }
    }, add = TRUE)
    rgl::bg3d(color = background.color)
    rgl::plot3d(X, type = "n", axes = axes, xlab = xlab, ylab = ylab, zlab = zlab)
    if (aspect == "equal") rgl::aspect3d("iso") else rgl::aspect3d(1, 1, 1)
    camera <- utils::modifyList(list(theta = 35, phi = 20, fov = 30, zoom = 0.8), camera)
    do.call(rgl::view3d, camera)
    ids <- rbind(.draw.points(X, which(!highlight), colors, other.style),
                 .draw.points(X, which(highlight), colors, selected.style))
    ids <- ids[order(ids$row), , drop = FALSE]
    rownames(ids) <- NULL
    context <- list(X = X, row.ids = seq_len(n), colors = colors, highlight = highlight, draw.ids = ids)
    for (layer in layers) {
        devices.before <- rgl::rgl.dev.list()
        .draw.layer(layer, context)
        if (rgl::cur3d() != device || !identical(rgl::rgl.dev.list(), devices.before))
            .stop("Layer callbacks must not open, close, or switch graphics devices.")
    }
    scene <- rgl::scene3d(minimal = FALSE)
    w <- rgl::rglwidget(scene, width = width, height = height, shinyBrush = shiny.brush)
    if (is.null(width)) w$width <- "100%"
    w$sizingPolicy$browser$padding <- 0
    w$sizingPolicy$viewer$padding <- 0
    w <- htmlwidgets::onRender(w, "function(el) {
      Array.from(el.children).forEach(function(child) {
        if (child.classList.contains('ivue-legend')) child.remove();
      });
    }")
    captured.camera <- list(userMatrix = rgl::par3d("userMatrix"),
                            zoom = rgl::par3d("zoom"), fov = rgl::par3d("FOV"))
    attr(w, "ivue") <- c(context, list(camera = captured.camera,
                                    aspect = aspect, scene = scene))
    w
}
