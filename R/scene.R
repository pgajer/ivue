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
                   background.color, layers, shiny.brush, limits = NULL,
                   description = NULL, controls = TRUE) {
    X <- .coordinates(X)
    n <- nrow(X)
    limits <- .view.limits(limits, X)
    .flag(controls, "controls")
    if (is.null(description)) description <- paste("Interactive 3D view of", n, "observations.")
    .text(description, "description")
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
    .named.list(camera, c("theta", "phi", "fov", "zoom", "userMatrix", "observer"), "camera")
    for (nm in setdiff(names(camera), c("userMatrix", "observer"))) .scalar(camera[[nm]], paste0("camera$", nm))
    if (!is.null(camera$fov)) .scalar(camera$fov, "camera$fov", 0, 179)
    if (!is.null(camera$zoom)) .scalar(camera$zoom, "camera$zoom", .Machine$double.eps)
    if (!is.null(camera$userMatrix) && (!is.matrix(camera$userMatrix) ||
        !identical(dim(camera$userMatrix), c(4L, 4L)) || !is.numeric(camera$userMatrix) ||
        any(!is.finite(camera$userMatrix)))) .stop("camera$userMatrix must be a finite 4 x 4 matrix.")

    if (!is.null(camera$observer) && (!is.numeric(camera$observer) ||
        is.complex(camera$observer) || length(camera$observer) != 3L ||
        any(!is.finite(camera$observer)) || camera$observer[3] <= 0))
        .stop("camera$observer must contain three finite coordinates with positive depth.")

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
    bounds <- if (is.null(limits)) list() else
        list(xlim = limits[1, ], ylim = limits[2, ], zlim = limits[3, ])
    do.call(rgl::plot3d, c(list(x = X, type = "n", axes = axes,
                             xlab = xlab, ylab = ylab, zlab = zlab), bounds))
    # Fixed ranges are established above; subsequent geometry does not enlarge them.
    if (!is.null(limits)) rgl::par3d(ignoreExtent = TRUE)
    if (aspect == "equal") rgl::aspect3d("iso") else rgl::aspect3d(1, 1, 1)
    # Do not let a default userMatrix override explicitly supplied rgl angles.
    camera.defaults <- if (any(c("theta", "phi", "userMatrix") %in% names(camera)))
        list(theta = 35, phi = 20, fov = 30, zoom = 0.8) else camera.zup()
    camera <- utils::modifyList(camera.defaults, camera)
    observer <- camera$observer
    camera$observer <- NULL
    do.call(rgl::view3d, camera)
    if (!is.null(observer)) rgl::observer3d(observer)
    ids <- rbind(.draw.points(X, which(!highlight), colors, other.style),
                 .draw.points(X, which(highlight), colors, selected.style))
    ids <- ids[order(ids$row), , drop = FALSE]
    rownames(ids) <- NULL
    context <- list(X = X, row.ids = seq_len(n), observation.ids = rownames(X),
                    colors = colors, highlight = highlight, draw.ids = ids)
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
    w <- .view.controls(w, description, controls, aspect, X)
    captured.camera <- list(userMatrix = rgl::par3d("userMatrix"),
                            zoom = rgl::par3d("zoom"), fov = rgl::par3d("FOV"),
                            observer = rgl::par3d("observer"))
    attr(w, "ivue") <- c(context, list(camera = captured.camera,
                                    aspect = aspect, limits = limits,
                                    description = description, scene = scene))
    w
}

.view.limits <- function(limits, X) {
    if (is.null(limits)) return(NULL)
    if (!is.matrix(limits) || !is.numeric(limits) || is.complex(limits) ||
        !identical(dim(limits), c(3L, 2L)) || any(!is.finite(limits)) ||
        any(limits[, 1] > limits[, 2]) || any(!is.finite(limits[, 2]-limits[, 1])))
        .stop("limits must be a finite 3-by-2 matrix of nondecreasing ranges.")
    if (any(sweep(X, 2, limits[, 1], "<")) || any(sweep(X, 2, limits[, 2], ">")))
        .stop("limits must contain every point coordinate.")
    unname(limits)
}
