#' An Independently Positioned Gridded Surface
#'
#' Add a reference surface with its own coordinates to any plot3D scene.
#' Unlike [layer3D.mesh()], the surface does not use the plotted observations
#' as its vertices and stays fixed when reused with another configuration.
#'
#' @param x,y Finite numeric coordinate vectors, each of length at least two,
#'   strictly increasing or strictly decreasing.
#' @param z Finite numeric matrix with length(x) rows and length(y) columns.
#'   Entry `z[i, j]` is the height at `(x[i], y[j])`; use `outer(x, y, fun)` to
#'   evaluate a height function on the grid. Missing values are not supported.
#' @param col Face color, length one or one per grid cell. Cell order has the
#'   x index varying fastest, then the y index. Both triangles in a cell have
#'   the same color; colors do not inherit the plot's point color scale.
#' @param alpha Face opacity multiplier, length one or one per grid cell,
#'   in `[0, 1]`. Multiplies any opacity in col. Zero hides the faces.
#' @param edges Draw grid lines, without the triangulation diagonals.
#' @param edge.col Single grid-line color.
#' @param edge.alpha Grid-line opacity multiplier in `[0, 1]`.
#' @param edge.width Positive grid-line width in screen units.
#' @param lit Apply lighting to faces. FALSE keeps colors independent of
#'   orientation; TRUE helps reveal surface shape. Both sides are drawn.
#' @return An ivue_layer specification for the layers argument.
#' @details Each rectangular parameter cell is split along the diagonal from
#'   (i, j) to (i+1, j+1). The result is a piecewise-planar approximation, not
#'   an exact smooth surface. A finer grid improves the approximation.
#'   The surface contributes to the scene bounds, but automatic layer3D.axes
#'   limits are based on the plotted observations; supply explicit axis limits
#'   if needed. No alignment or rescaling of either set of coordinates is done.
#'   Align an embedding to the reference coordinates before interpreting their
#'   spatial agreement. Transparent intersecting surfaces can have rendering
#'   order artifacts. Construction requires neither rgl nor geometry;
#'   rendering uses rgl on the plot's private device.
#' @seealso [layer3D.mesh()], [layer3D.axes()], [plot3D.cont()]
#' @export
#' @examples
#' x <- y <- seq(-1, 1, length.out = 31)
#' z <- outer(x, y, function(x, y) 0.8 * (x^2 - y^2))
#' reference <- layer3D.surface(x, y, z, col = "lightblue", alpha = 0.3)
#' if (nzchar(system.file(package = "rgl"))) {
#'   X <- rbind(c(-0.5, 0, 0.2), c(0, 0.5, -0.2), c(0.5, 0.5, 0))
#'   w <- plot3D.plain(X, point.type = "sphere", sphere.radius = 0.03,
#'       layers = list(reference, layer3D.axes()), camera = camera.zup())
#' }
layer3D.surface <- function(x, y, z, col = "gray75", alpha = 0.2,
                            edges = FALSE, edge.col = "gray45",
                            edge.alpha = 0.35, edge.width = 1, lit = FALSE) {
    valid.axis <- function(a) {
        is.numeric(a) && !is.complex(a) && is.null(dim(a)) &&
            length(a) >= 2L && all(is.finite(a)) &&
            (all(diff(a) > 0) || all(diff(a) < 0))
    }
    if (!valid.axis(x) || !valid.axis(y))
        .stop("x and y must be finite, strictly monotone numeric vectors of length at least two.")
    if (!is.matrix(z) || !is.numeric(z) || is.complex(z) ||
        !identical(dim(z), c(length(x), length(y))) || any(!is.finite(z)))
        .stop("z must be a finite numeric matrix with length(x) rows and length(y) columns.")
    nx <- length(x); ny <- length(y)
    ids <- matrix(seq_len(nx * ny), nx, ny)
    a <- as.vector(ids[-nx, -ny, drop = FALSE])
    b <- as.vector(ids[-1L, -ny, drop = FALSE])
    c <- as.vector(ids[-1L, -1L, drop = FALSE])
    d <- as.vector(ids[-nx, -1L, drop = FALSE])
    triangles <- rbind(cbind(a, b, c), cbind(a, c, d))
    # Keep upward face winding even when exactly one grid axis is reversed.
    if (xor(x[2] < x[1], y[2] < y[1])) triangles <- triangles[, c(1, 3, 2)]
    nc <- length(a)
    col <- .fixed.colors(col, nc)
    if (!is.numeric(alpha) || is.complex(alpha) ||
        !(length(alpha) %in% c(1L, nc)) || any(!is.finite(alpha)) ||
        any(alpha < 0 | alpha > 1))
        .stop("alpha must have length one or one per grid cell, with values in [0, 1].")
    out <- layer3D.mesh(triangles, col = rep(col, 2L),
        alpha = rep(rep(alpha, length.out = nc), 2L), edges = edges,
        edge.col = edge.col, edge.alpha = edge.alpha, edge.width = edge.width,
        lit = lit)
    out$type <- "surface"
    out$coordinates <- cbind(x = rep(x, ny), y = rep(y, each = nx), z = as.vector(z))
    out$edge.matrix <- rbind(
        cbind(as.vector(ids[-nx, , drop = FALSE]), as.vector(ids[-1L, , drop = FALSE])),
        cbind(as.vector(ids[, -ny, drop = FALSE]), as.vector(ids[, -1L, drop = FALSE])))
    out
}
