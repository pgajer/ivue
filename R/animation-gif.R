#' Export Recorded Frames to GIF
#'
#' Render the retained frames of an [animate.frames()] widget to an animated
#' GIF. Export uses a separate orthographic raster renderer and requires the
#' optional magick package; it does not launch a browser or native 3D window.
#'
#' @param animation A widget returned by [animate.frames()].
#' @param file Destination ending in .gif. Its parent directory must exist.
#' @param fps Frames per second, from 0.1 to 100; NULL uses the widget's initial speed.
#' @param width,height GIF dimensions in pixels.
#' @param final.hold Additional seconds to hold the last frame, from zero to 600.
#' @param loop Repeat the GIF indefinitely; FALSE plays once.
#' @param labels Draw the retained frame labels above the image.
#' @param overwrite Allow replacing an existing destination.
#' @param annotations Include the animation's mapping legend and plain-text
#'   caption. FALSE preserves the unannotated layout. TRUE reserves space beside
#'   and below the scene within width and height; enlarge these dimensions if
#'   the text does not fit. No annotation is drawn over observations.
#' @return The normalized output path, invisibly.
#' @details GIF export uses the widget's retained coordinates, visibility masks,
#'   colors, edge widths, and initial camera orientation. Camera rotations or
#'   speed changes made later in the browser are not returned to R. Download
#'   view settings and supply their camera when constructing a new animation
#'   to reuse its orientation and zoom. With annotations = TRUE, a raster legend
#'   and caption are drawn from the retained mapping and caption, including
#'   category counts and missing values. Arbitrary HTML is not rasterized. Create a
#'   widget with an explicit camera to export that view. Perspective cameras
#'   (fov greater than zero) are rejected; use camera.zup(fov = 0).
#'
#'   The raster renderer projects points and straight edges orthographically,
#'   with fixed bounds and equal coordinate scales across all frames. Zoom has
#'   the rgl convention: smaller values enlarge the scene. The observer position
#'   and bounds determine its orthographic scale. Annotations reduce the available
#'   scene area; compare exports using the same dimensions and annotation layout.
#'   Text wraps at a fixed readable size; layouts that cannot fit are rejected. Edges
#'   are painted before points, ordered within each group from back to front.
#'   This is a diagram renderer, not a pixel-identical WebGL screenshot or a
#'   depth-buffered rendering of intersecting 3D geometry. Point sizes can
#'   differ slightly between browser and raster output. No alignment,
#'   recentering of individual frames, or interpolation is performed.
#'
#'   GIF delays are rounded to centiseconds, with a minimum of one centisecond.
#'   The additional final hold is applied once per loop. Export works from an
#'   R widget object, not from a saved HTML file. Temporary images and graphics
#'   devices are cleaned up on success and failure.
#' @seealso [animate.frames()]
#' @export
#' @examples
#' if (nzchar(system.file(package = "rgl")) &&
#'     requireNamespace("magick", quietly = TRUE)) {
#'   X <- rbind(c(0, 0), c(1, 0), c(0, 1))
#'   w <- animate.frames(list(X, X * 1.5), fps = 2)
#'   path <- tempfile(fileext = ".gif")
#'   write.animation.gif(w, path, width = 240, height = 240)
#'   unlink(path)
#' }
write.animation.gif <- function(animation, file, fps = NULL,
                                 width = 600L, height = 600L, final.hold = 2,
                                 loop = TRUE, labels = TRUE, overwrite = FALSE,
                                 annotations = FALSE) {
    info <- attr(animation, "ivue.animation")
    if (is.null(info) || !inherits(animation, "htmlwidget"))
        .stop("animation must be a widget returned by animate.frames().")
    .text(file, "file")
    if (!grepl("\\.gif$", file, ignore.case = TRUE)) .stop("file must end in .gif.")
    .flag(overwrite, "overwrite")
    if (file.exists(file) && !overwrite) .stop("file already exists; use overwrite = TRUE to replace it.")
    if (dir.exists(file)) .stop("file must not name a directory.")
    if (!dir.exists(dirname(file))) .stop("The parent directory of file must exist.")
    if (is.null(fps)) fps <- info$fps
    .scalar(fps, "fps", 0.1, 100)
    .scalar(width, "width", 64, 8192, TRUE)
    .scalar(height, "height", 64, 8192, TRUE)
    .scalar(final.hold, "final.hold", 0, 600)
    .flag(loop, "loop")
    .flag(labels, "labels")
    .flag(annotations, "annotations")
    if (info$camera$fov != 0) .stop("GIF export requires an orthographic camera (fov = 0).")
    if (!requireNamespace("magick", quietly = TRUE))
        .stop("GIF export requires magick. Install it with install.packages('magick').")
    projection <- .animation.projection(info)
    paths <- character(length(info$frames))
    frame.dir <- tempfile("ivue-frames-")
    dir.create(frame.dir)
    on.exit(unlink(frame.dir, recursive = TRUE), add = TRUE)
    for (i in seq_along(paths)) {
        paths[i] <- file.path(frame.dir, sprintf("frame-%05d.png", i))
        .animation.png(info, projection, i, paths[i], width, height, labels, annotations)
    }
    delays <- rep(max(1, round(100 / fps)), length(paths))
    delays[length(delays)] <- delays[length(delays)] + round(100 * final.hold)
    gif <- magick::image_animate(magick::image_read(paths), delay = delays,
                                  loop = if (loop) 0 else 1, optimize = TRUE)
    staged <- tempfile(".ivue-", tmpdir = dirname(file), fileext = ".gif")
    on.exit(unlink(staged), add = TRUE)
    magick::image_write(gif, staged, format = "gif")
    if (!file.copy(staged, file, overwrite = overwrite)) .stop("Could not write GIF to ", file, ".")
    invisible(normalizePath(file, mustWork = TRUE))
}

.animation.projection <- function(info) {
    # Match rgl's orthographic frustum (projection.src.js). The saved scene
    # bounds include rgl's float rounding; older widget objects use R bounds.
    bounds <- if (is.null(info$scene.limits)) info$limits else info$scene.limits
    center <- rowMeans(bounds)
    radius <- sqrt(sum(((bounds[, 2] - bounds[, 1]) / 2)^2)) * 1.1
    if (radius <= 0) radius <- 1
    observer <- info$camera$observer
    if (is.null(observer)) observer <- c(0, 0, radius / sin(pi / 8))
    near <- observer[3] - radius
    far <- observer[3] + radius
    if (far < 0) far <- 1
    near <- max(near, far / 100)
    half <- near * info$camera$zoom
    project <- function(X) {
        Y <- cbind(sweep(X, 2, center, "-"), 1) %*% t(info$camera$userMatrix)
        sweep(Y[, 1:3, drop = FALSE] / Y[, 4], 2, observer, "-")
    }
    list(frames = lapply(info$frames, project),
         limits = rbind(c(-half, half), c(-half, half)))
}

.animation.png <- function(info, projection, i, path, width, height, labels, annotations = FALSE) {
    grDevices::png(path, width = width, height = height, res = 96,
                   bg = info$background.color)
    device <- grDevices::dev.cur()
    on.exit(grDevices::dev.off(device), add = TRUE)
    old.par <- graphics::par(c("family", "ps", "fig", "mar", "new", "xaxs", "yaxs",
                               "usr", "xaxp", "yaxp"))
    on.exit(graphics::par(old.par), add = TRUE, after = FALSE)
    # Restore before closing; derived dimensions such as pin can be negative
    # on small devices with default margins, so do not save/reapply them.
    graphics::par(family = "sans", ps = 10)
    layout <- .animation.layout(info, width, height, labels, annotations)
    .animation.annotations(info, layout, width, height)
    graphics::par(fig = layout$scene, mar = c(0, 0, 0, 0),
                  new = TRUE, xaxs = "i", yaxs = "i")
    graphics::plot(NA_real_, xlim = projection$limits[1, ], ylim = projection$limits[2, ],
                    asp = 1, axes = FALSE, xlab = "", ylab = "")
    X <- projection$frames[[i]]
    active <- info$active[[i]]
    edges <- info$edges
    keep <- which(active[edges[, 1]] & active[edges[, 2]])
    if (length(keep)) {
        keep <- keep[order((X[edges[keep, 1], 3] + X[edges[keep, 2], 3]) / 2)]
        graphics::segments(X[edges[keep, 1], 1], X[edges[keep, 1], 2],
                            X[edges[keep, 2], 1], X[edges[keep, 2], 2],
                            col = info$edge.col[keep], lwd = info$edge.width)
    }
    rows <- which(active)
    rows <- rows[order(X[rows, 3])]
    if (length(rows)) graphics::points(X[rows, 1], X[rows, 2], pch = 16,
        col = info$col[rows], cex = info$point.size / 6)
    if (labels) {
        graphics::par(fig = c(0, 1, 0, 1), mar = rep(0, 4), new = TRUE)
        graphics::plot.new(); graphics::plot.window(c(0, width), c(0, height), xaxs="i", yaxs="i")
        graphics::text(layout$scene[2] * width / 2, height - 8,
                       paste(layout$labels[[i]], collapse="\n"), adj=c(.5, 1))
    }
    invisible(path)
}
