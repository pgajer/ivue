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
#' @return The normalized output path, invisibly.
#' @details GIF export uses the widget's retained coordinates, visibility masks,
#'   colors, edge widths, and initial camera orientation. Camera rotations or
#'   speed changes made later in the browser are not returned to R. Create a
#'   widget with an explicit camera to export that view. Perspective cameras
#'   (fov greater than zero) are rejected; use camera.zup(fov = 0).
#'
#'   The raster renderer projects points and straight edges orthographically,
#'   with fixed bounds and equal coordinate scales across all frames. Edges
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
                                 loop = TRUE, labels = TRUE, overwrite = FALSE) {
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
        .animation.png(info, projection, i, paths[i], width, height, labels)
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
    center <- rowMeans(info$limits)
    project <- function(X) {
        Y <- cbind(sweep(X, 2, center, "-"), 1) %*% t(info$camera$userMatrix)
        Y[, 1:3, drop = FALSE] / Y[, 4]
    }
    corners <- as.matrix(expand.grid(info$limits[1, ], info$limits[2, ], info$limits[3, ]))
    box <- project(corners)
    if (any(!is.finite(box))) .stop("Camera projection must produce finite coordinates.")
    limits <- t(apply(box[, 1:2, drop = FALSE], 2, range))
    midpoint <- rowMeans(limits)
    half <- pmax((limits[, 2] - limits[, 1]) / 2, 1e-8) * 0.8 / info$camera$zoom
    list(frames = lapply(info$frames, project),
         limits = cbind(midpoint - half, midpoint + half))
}

.animation.png <- function(info, projection, i, path, width, height, labels) {
    grDevices::png(path, width = width, height = height, res = 96,
                   bg = info$background.color)
    device <- grDevices::dev.cur()
    on.exit(grDevices::dev.off(device), add = TRUE)
    graphics::par(mar = c(0, 0, if (labels) 2 else 0, 0), xaxs = "i", yaxs = "i")
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
    if (labels) graphics::title(main = info$labels[i], cex.main = 0.8, font.main = 1)
    invisible(path)
}
