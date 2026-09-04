#' A Z-Up Initial Camera
#'
#' Construct a camera without opening a graphics device or loading rgl.
#'
#' @param elevation Viewing elevation in degrees above the xy plane, from -90
#'   to 90. At either pole the z axis points along the viewing direction.
#' @param turn Rotation about the data's z axis, in degrees. Zero puts positive
#'   x to the right and positive y away from the viewer. The default -135 puts
#'   positive x down-left and positive y down-right at positive elevation.
#' @param fov Field of view in degrees, from 0 to 179. Zero gives orthographic
#'   projection without perspective foreshortening.
#' @param zoom Positive magnification factor.
#' @return A list with userMatrix, fov, and zoom, accepted by the camera argument
#'   of every plot3D function.
#' @details This sets the initial view, not an interactive rotation constraint.
#'   Away from the poles, positive z projects upward. Interactive dragging can
#'   subsequently tilt it. The rotation is Rx(elevation - 90) times Rz(turn).
#' @seealso [layer3D.axes()], [plot3D.plain()]
#' @export
#' @examples
#' camera.zup()
#' camera.zup(elevation = 30, turn = 0)
camera.zup <- function(elevation = 20, turn = -135, fov = 0, zoom = 0.8) {
    .scalar(elevation, "elevation", -90, 90)
    .scalar(turn, "turn")
    .scalar(fov, "fov", 0, 179)
    .scalar(zoom, "zoom", .Machine$double.eps)
    a <- (elevation - 90) * pi / 180
    b <- (turn %% 360) * pi / 180
    rx <- rz <- diag(4)
    rx[2:3, 2:3] <- matrix(c(cos(a), sin(a), -sin(a), cos(a)), 2)
    rz[1:2, 1:2] <- matrix(c(cos(b), sin(b), -sin(b), cos(b)), 2)
    list(userMatrix = rx %*% rz, fov = fov, zoom = zoom)
}

#' Coordinate Axes Through an Origin
#'
#' Add three coordinate axes with positive-end arrowheads, rather than a
#' bounding box. Use axes = FALSE in the plotting call to suppress its ordinary
#' axes. This layer never changes the camera; [camera.zup()] supplies a
#' complementary initial view.
#'
#' @param origin Three finite coordinates at which the axes intersect.
#' @param limits NULL for automatic limits, or a finite numeric 3-by-2 matrix
#'   with rows x, y, z and columns lower, upper. Each row must strictly contain
#'   the corresponding origin coordinate. Row and column names are optional.
#' @param padding Nonnegative fraction added to automatic half-lengths.
#'   Ignored when limits are supplied.
#' @param labels Three axis labels. Empty strings suppress individual labels.
#' @param col Axis colors, length one or three, also used for heads and labels.
#' @param width Positive shaft line widths, length one or three, in screen units.
#' @param head.length Arrowhead length as a fraction of each full axis span,
#'   from 0 to 0.25. Zero omits heads. Length is capped at 80 percent of the
#'   positive arm to keep the head beyond the origin.
#' @param head.angle Cone half-angle in radians, strictly between 0 and pi/2.
#' @param cex Positive label size multiplier.
#' @param label.offset Nonnegative gap beyond each positive tip, as a fraction
#'   of that axis's full span.
#' @return An ivue_layer specification for the layers argument.
#' @details Automatic limits are symmetric about origin and enclose all rows
#'   of X. A coordinate with no extent uses the largest other half-length, or
#'   one data unit if all points coincide with origin. Arrowheads are solid
#'   cones in data coordinates, not screen-facing decorations, so they rotate
#'   with the scene. Their proportions assume aspect = "equal"; independently
#'   normalizing coordinate axes can distort them. Limits specify axis endpoints,
#'   not clipping bounds for the data. There are no tick marks.
#' @seealso [camera.zup()], [layer3D.edges()], [plot3D.cont()]
#' @export
#' @examples
#' axes <- layer3D.axes(head.length = 0.04)
#' if (nzchar(system.file(package = "rgl"))) {
#'   X <- rbind(c(-1, -1, 0), c(1, 0, 1), c(0, 1, -1))
#'   w <- plot3D.plain(X, axes = FALSE, layers = list(axes),
#'                     camera = camera.zup())
#' }
layer3D.axes <- function(origin = c(0, 0, 0), limits = NULL, padding = 0.2,
                         labels = c("x", "y", "z"), col = "black", width = 2,
                         head.length = 0.04, head.angle = pi/8, cex = 1.2,
                         label.offset = 0.04) {
    if (!is.numeric(origin) || is.complex(origin) || length(origin) != 3L ||
        any(!is.finite(origin))) .stop("origin must contain three finite coordinates.")
    if (!is.null(limits) && (!is.matrix(limits) || !is.numeric(limits) ||
        is.complex(limits) || !identical(dim(limits), c(3L, 2L)) ||
        any(!is.finite(limits)) || any(limits[, 1] >= origin) ||
        any(limits[, 2] <= origin)))
        .stop("limits must be a finite 3-by-2 matrix strictly containing origin.")
    .scalar(padding, "padding", 0)
    if (!is.character(labels) || length(labels) != 3L || anyNA(labels))
        .stop("labels must contain three nonmissing strings.")
    col <- .fixed.colors(col, 3L)
    width <- .widths(width, 3L)
    .scalar(head.length, "head.length", 0, 0.25)
    .scalar(head.angle, "head.angle", 0, pi/2)
    if (head.angle == 0 || head.angle == pi/2)
        .stop("head.angle must be strictly between 0 and pi/2.")
    .scalar(cex, "cex", .Machine$double.eps)
    .scalar(label.offset, "label.offset", 0)
    structure(list(type = "axes", origin = origin, limits = limits,
        padding = padding, labels = labels, col = col, width = width,
        head.length = head.length, head.angle = head.angle, cex = cex,
        label.offset = label.offset), class = "ivue_layer")
}

.axes.geometry <- function(layer, X) {
    origin <- layer$origin
    limits <- layer$limits
    if (is.null(limits)) {
        extent <- apply(abs(sweep(X, 2, origin, "-")), 2, max)
        fallback <- max(extent)
        if (fallback == 0) fallback <- 1
        extent[extent == 0] <- fallback
        extent <- extent * (1 + layer$padding)
        limits <- cbind(origin - extent, origin + extent)
    }
    span <- limits[, 2] - limits[, 1]
    if (any(!is.finite(c(limits, span))) || any(span <= 0))
        .stop("Axis extents overflow or collapse; rescale coordinates or supply limits.")
    lapply(seq_len(3), function(j) {
        start <- tip <- label <- origin
        start[j] <- limits[j, 1]
        tip[j] <- limits[j, 2]
        label[j] <- tip[j] + layer$label.offset * span[j]
        h <- min(layer$head.length * span[j], 0.8 * (tip[j] - origin[j]))
        base <- tip
        base[j] <- base[j] - h
        triangles <- matrix(numeric(), 0, 3)
        if (h > 0) {
            # A closed cone with 24 sides: every vertex is in data coordinates.
            angle <- seq(0, 2 * pi, length.out = 25)
            ring <- matrix(rep(base, each = 25), ncol = 3)
            other <- setdiff(seq_len(3), j)
            ring[, other] <- ring[, other] + h * tan(layer$head.angle) *
                cbind(cos(angle), sin(angle))
            triangles <- do.call(rbind, lapply(seq_len(24), function(i)
                rbind(tip, ring[i, ], ring[i + 1L, ],
                      base, ring[i + 1L, ], ring[i, ])))
        }
        if (any(!is.finite(c(label, triangles))))
            .stop("Axis heads or labels overflow; reduce their sizes or rescale coordinates.")
        list(shaft = rbind(start, base), head = triangles, tip = tip, label = label)
    })
}

.draw.axes.layer <- function(layer, context) {
    geometry <- .axes.geometry(layer, context$X)
    material <- .material.colors(layer$col)
    for (j in seq_len(3)) {
        g <- geometry[[j]]
        rgl::segments3d(g$shaft, col = material$col[j], alpha = material$alpha[j],
                        lwd = layer$width[j], lit = FALSE)
        if (nrow(g$head)) rgl::triangles3d(g$head, col = material$col[j],
            alpha = material$alpha[j], lit = FALSE, front = "filled", back = "filled")
        if (nzchar(layer$labels[j])) rgl::text3d(matrix(g$label, nrow = 1),
            texts = layer$labels[j], col = material$col[j], alpha = material$alpha[j],
            cex = layer$cex, adj = c(0.5, 0.5))
    }
    invisible(NULL)
}
