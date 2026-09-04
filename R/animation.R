#' Play Recorded Coordinate Frames
#'
#' Display a sequence of point clouds or embedded graphs with browser playback
#' controls. No layout algorithm, coordinate alignment, or interpolation is
#' applied. The camera can be rotated while playback is paused or running.
#'
#' @param frames List of at least two numeric n-by-2 or n-by-3 matrices with
#'   identical dimensions. A row is one vertex throughout the sequence. Each
#'   row must be entirely finite or entirely missing (NA or NaN, an inactive vertex). If row
#'   names are supplied, every frame must have the same unique names in the
#'   same order. Two-dimensional coordinates are embedded in the z=0 plane.
#' @param edges Optional two-column matrix of one-based vertex indices, shared
#'   across frames. An edge is visible only when both endpoints are active.
#' @param labels Optional character labels, one per original frame.
#' @param frame.index Optional strictly increasing original frame indices to
#'   retain. Selection is explicit and takes precedence over max.frames.
#' @param max.frames Maximum frames retained by evenly spaced subsampling,
#'   including the first and last. NULL keeps all frames. Subsampling reports
#'   a message; original indices remain in the timeline and returned metadata.
#' @param fps Frames per second at the initial playback speed, from 0.1 to 100.
#' @param loop Repeat browser playback.
#' @param col Point colors, length one or n. Alpha components are preserved.
#' @param point.size Point diameter in screen pixels.
#' @param edge.col Edge colors, length one or the number of edges.
#' @param edge.width Positive edge width in screen units.
#' @param camera Initial camera specification, as in [plot3D.plain()]. The
#'   default is orthographic: face-on for 2D and [camera.zup()] for 3D.
#' @param width,height Widget dimensions, as in [plot3D.plain()].
#' @param background.color Canvas background color.
#' @return An rglwidget/htmlwidget with an attached player. Save interactive
#'   output using `htmlwidgets::saveWidget()`. `attr(widget, "ivue.animation")`
#'   contains the retained frames, original frame indices, labels, active masks,
#'   edges, fixed bounds, styles, fps, and initial camera for GIF export.
#' @details Playback starts paused and steps between recorded frames. All
#'   frames have equal duration, even after subsampling; the timeline does not
#'   represent solver wall time. Bounds are fitted once to all original frames,
#'   including omitted frames. Inactive rows may appear or disappear at any
#'   step; missing positions are never interpolated. Supplied colors retain
#'   their association with vertex rows and edge rows.
#'
#'   Large traces increase widget size approximately with the product of frame
#'   count and the number of vertices plus edge endpoints. Use max.frames or
#'   frame.index to limit output size. A frame can be empty, but the full
#'   sequence must contain at least one finite point.
#'
#'   Only points and optional straight edges are animated. Use col with
#'   [map.colors()] to reuse numerical or categorical color scales. Ordinary
#'   static plotting and validation retain their stricter finite-coordinate
#'   requirements. rgl is loaded only when a widget is constructed.
#' @seealso [write.animation.gif()]
#' @export
#' @examples
#' X <- rbind(c(0, 0), c(1, 0), c(0, 1))
#' first <- X; first[3, ] <- NA
#' frames <- list(first, X, X * 1.5)
#' edges <- rbind(c(1, 2), c(2, 3), c(3, 1))
#' if (nzchar(system.file(package = "rgl"))) {
#'   w <- animate.frames(frames, edges, fps = 2)
#' }
animate.frames <- function(frames, edges = NULL, labels = NULL,
                            frame.index = NULL, max.frames = 100L,
                            fps = 6, loop = TRUE, col = "#197A68",
                            point.size = 5, edge.col = "gray65", edge.width = 1,
                            camera = NULL, width = NULL, height = 600L,
                            background.color = "white") {
    info <- .animation.frames(frames, edges, labels, frame.index, max.frames)
    .scalar(fps, "fps", 0.1, 100)
    .flag(loop, "loop")
    .scalar(point.size, "point.size", .Machine$double.eps)
    .scalar(edge.width, "edge.width", .Machine$double.eps)
    info$col <- .colors(col, nrow(info$frames[[1]]), "col")
    info$edge.col <- .colors(edge.col, nrow(info$edges), "edge.col")
    if (is.null(camera)) camera <- if (info$dimension == 2L)
        camera.zup(elevation = 90, turn = 0) else camera.zup()
    first <- .animation.positions(info$frames[[1]], info$limits)
    edge.id <- NULL
    edge.rows <- as.vector(t(info$edges))
    layer <- layer3D.callback(function(ctx) {
        if (length(edge.rows)) {
            material <- .material.colors(rep(info$edge.col, each = 2L))
            edge.id <<- as.integer(rgl::segments3d(first[edge.rows, , drop = FALSE],
                col = material$col, alpha = rep(0, length(edge.rows)),
                lwd = edge.width, lit = FALSE))
        }
    })
    w <- .scene(first, info$col, "point", point.size, NULL, 0, NULL,
                list(), list(), FALSE, "", "", "", "equal", camera,
                width, height, background.color, list(layer), NULL,
                limits = info$limits)
    ids <- attr(w, "ivue")$draw.ids
    controls <- list(.animation.control(info, ids$object[1], seq_len(nrow(first)),
                                        info$col, edges = FALSE))
    if (length(edge.rows)) controls[[2]] <- .animation.control(
        info, edge.id, edge.rows, rep(info$edge.col, each = 2L), edges = TRUE)
    player <- rgl::playwidget(w$elementId, controls, start = 0,
        stop = length(info$frames) - 1L, interval = 1 / fps, rate = fps,
        step = 1, loop = loop, labels = htmltools::htmlEscape(info$labels),
        components = c("Play", "Reverse", "Slower", "Faster", "Reset", "Slider", "Label"))
    # Register the player so rgl reapplies its current frame after scene resize.
    w$x$players <- c(w$x$players, player$elementId)
    w <- htmlwidgets::appendContent(w, player)
    info$point.size <- point.size
    info$edge.width <- edge.width
    info$background.color <- background.color
    info$fps <- fps
    info$camera <- attr(w, "ivue")$camera
    attr(w, "ivue.animation") <- info
    w
}

.animation.frames <- function(frames, edges, labels, frame.index, max.frames) {
    if (!is.list(frames) || length(frames) < 2L)
        .stop("frames must be a list of at least two coordinate matrices.")
    dims <- dim(frames[[1]])
    if (length(dims) != 2L || dims[1] < 1L || !(dims[2] %in% c(2L, 3L)))
        .stop("Each frame must be an n-by-2 or n-by-3 numeric matrix.")
    ids <- rownames(frames[[1]])
    if (!is.null(ids) && (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)))
        .stop("Frame row names must be unique and nonmissing.")
    limits <- cbind(rep(Inf, 3), rep(-Inf, 3))
    for (i in seq_along(frames)) {
        X <- frames[[i]]
        if (!is.matrix(X) || !is.numeric(X) || is.complex(X) || !identical(dim(X), dims))
            .stop("All frames must be numeric matrices with identical dimensions.")
        if (!identical(rownames(X), ids))
            .stop("All frames must have the same row names in the same order.")
        inactive <- rowSums(is.na(X)) == dims[2]
        active <- rowSums(is.finite(X)) == dims[2]
        if (any(!inactive & !active))
            .stop("Frame ", i, ": each row must be entirely finite or entirely missing (NA or NaN).")
        if (dims[2] == 2L) X <- cbind(X, ifelse(active, 0, NA_real_))
        storage.mode(X) <- "double"
        frames[[i]] <- X
        if (any(active)) {
            ranges <- t(apply(X[active, , drop = FALSE], 2, range))
            limits[, 1] <- pmin(limits[, 1], ranges[, 1])
            limits[, 2] <- pmax(limits[, 2], ranges[, 2])
        }
    }
    if (any(!is.finite(limits))) .stop("The sequence must contain at least one finite point.")
    span <- max(limits[, 2] - limits[, 1])
    if (!is.finite(span)) .stop("Coordinate ranges are too large to render.")
    pad <- max(span * 0.04, 1e-8)
    limits <- limits + matrix(rep(c(-pad, pad), each = 3), 3)
    if (is.null(edges)) edges <- matrix(integer(), 0, 2)
    edges <- layer3D.edges(edges)$edges
    .indices(as.vector(edges), dims[1], "edges")
    count <- length(frames)
    if (is.null(labels)) labels <- paste("Frame", seq_len(count))
    if (!is.character(labels) || length(labels) != count || anyNA(labels))
        .stop("labels must contain one nonmissing string per original frame.")
    if (!is.null(max.frames)) .scalar(max.frames, "max.frames", 2, Inf, TRUE)
    index <- seq_len(count)
    if (!is.null(frame.index)) {
        index <- .indices(frame.index, count, "frame.index")
        if (length(index) < 2L || any(diff(index) <= 0))
            .stop("frame.index must contain at least two strictly increasing indices.")
    } else if (!is.null(max.frames) && count > max.frames) {
        index <- unique(as.integer(round(seq(1, count, length.out = max.frames))))
        message("Retaining ", length(index), " of ", count, " frames (including first and last).")
    }
    frames <- frames[index]
    list(frames = frames, frame.index = index, labels = labels[index],
         active = lapply(frames, stats::complete.cases), edges = edges,
         limits = limits, dimension = dims[2])
}

.animation.positions <- function(X, limits) {
    inactive <- !stats::complete.cases(X)
    X[inactive, ] <- rep(rowMeans(limits), each = sum(inactive))
    X
}

.animation.control <- function(info, objid, rows, colors, edges) {
    alpha <- grDevices::col2rgb(colors, alpha = TRUE)[4, ] / 255
    values <- t(vapply(seq_along(info$frames), function(i) {
        X <- .animation.positions(info$frames[[i]], info$limits)
        active <- if (edges) rep(info$active[[i]][info$edges[, 1]] &
                                      info$active[[i]][info$edges[, 2]], each = 2L) else info$active[[i]]
        as.vector(cbind(X[rows, , drop = FALSE], alpha * active))
    }, numeric(4 * length(rows))))
    rgl::vertexControl(values = values, vertices = rep(seq_along(rows), 4L),
        attributes = rep(c("x", "y", "z", "alpha"), each = length(rows)),
        objid = objid, param = seq_along(info$frames) - 1L, interp = FALSE)
}
