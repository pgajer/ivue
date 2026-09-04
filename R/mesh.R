#' A Triangular Surface Layer
#'
#' Draw supplied triangular faces using the plotting coordinates. This layer
#' does not construct a triangulation or change a graph used for analysis.
#'
#' @param triangles Numeric matrix with three columns of one-based vertex
#'   indices, one face per row. Indices refer to the plot's X, after vertex-ID
#'   alignment for graph plots. Empty matrices are allowed. Repeated vertices
#'   within a face and duplicate faces (including reversed faces) are rejected.
#' @param col Face colors, length one or one per triangle. Colors are constant
#'   within each face; they do not inherit the point color scale.
#' @param alpha Face opacity multiplier, length one or one per triangle, in
#'   `[0, 1]`. Multiplies any alpha already present in col. Zero hides the faces.
#' @param edges Draw mesh edges. Each undirected edge is drawn once, even when
#'   shared by two faces.
#' @param edge.col Single mesh-edge color.
#' @param edge.alpha Mesh-edge opacity multiplier in `[0, 1]`, independent of
#'   face opacity and multiplied by the alpha in edge.col.
#' @param edge.width Positive mesh-edge width in screen units.
#' @param lit Apply rgl lighting to faces. FALSE keeps face colors independent
#'   of orientation. Both sides are drawn; consistent face winding is advisable
#'   when enabling lighting.
#' @return An ivue_layer specification for the layers argument.
#' @details The same layer can be reused with different coordinates as long as
#'   vertex identities and row order are preserved. Connectivity is never
#'   recomputed after embedding. Geometrically collapsed or collinear triangles
#'   are retained: the layer does not repair folds, degeneracies, intersections,
#'   or inconsistent orientation. It does not require a manifold mesh.
#'
#'   Faces are planar interpolations between vertices, not an exact smooth
#'   surface or a new shortest-path graph. Rendering requires rgl; constructing
#'   the layer does not. A polygon offset reduces interference between faces
#'   and their edge overlay. Transparency is handled by the renderer and can
#'   have ordering artifacts for intersecting surfaces.
#' @seealso [layer3D.surface()], [layer3D.edges()], [layer3D.axes()], [plot3D.cont()]
#' @export
#' @examples
#' triangles <- rbind(c(1, 2, 3), c(1, 3, 4))
#' surface <- layer3D.mesh(triangles, alpha = 0.2)
#' if (nzchar(system.file(package = "rgl"))) {
#'   X <- rbind(c(-1, -1, 0), c(1, -1, 0), c(1, 1, 1), c(-1, 1, 0))
#'   w <- plot3D.plain(X, layers = list(surface, layer3D.axes()),
#'                     camera = camera.zup())
#' }
layer3D.mesh <- function(triangles, col = "gray75", alpha = 0.2, edges = TRUE,
                         edge.col = "gray45", edge.alpha = 0.35,
                         edge.width = 1, lit = FALSE) {
    if (!is.matrix(triangles) || !is.numeric(triangles) || is.complex(triangles) ||
        ncol(triangles) != 3L || any(!is.finite(triangles)) ||
        any(triangles < 1 | triangles != floor(triangles)))
        .stop("triangles must be a three-column matrix of positive whole-number indices.")
    if (any(triangles[, 1] == triangles[, 2] | triangles[, 1] == triangles[, 3] |
            triangles[, 2] == triangles[, 3]))
        .stop("Each triangle must contain three distinct vertex indices.")
    n <- nrow(triangles)
    if (n && anyDuplicated(t(apply(triangles, 1, sort))))
        .stop("Duplicate triangles are not supported, including reversed faces.")
    col <- .fixed.colors(col, n)
    if (!is.numeric(alpha) || is.complex(alpha) || !(length(alpha) %in% c(1L, n)) ||
        any(!is.finite(alpha)) || any(alpha < 0 | alpha > 1))
        .stop("alpha must have length one or one per triangle, with values in [0, 1].")
    .flag(edges, "edges")
    edge.col <- .fixed.colors(edge.col, 1L)
    .scalar(edge.alpha, "edge.alpha", 0, 1)
    .scalar(edge.width, "edge.width", .Machine$double.eps)
    .flag(lit, "lit")
    pairs <- rbind(triangles[, c(1, 2), drop = FALSE],
                   triangles[, c(2, 3), drop = FALSE],
                   triangles[, c(3, 1), drop = FALSE])
    pairs <- unique(cbind(pmin(pairs[, 1], pairs[, 2]), pmax(pairs[, 1], pairs[, 2])))
    structure(list(type = "mesh", triangles = triangles, col = col,
        alpha = rep(alpha, length.out = n), edges = edges, edge.matrix = pairs,
        edge.col = edge.col, edge.alpha = edge.alpha, edge.width = edge.width,
        lit = lit), class = "ivue_layer")
}

.draw.mesh.layer <- function(layer, context) {
    X <- context$X
    .indices(as.vector(layer$triangles), nrow(X), "triangle vertices")
    if (!nrow(layer$triangles)) return(invisible(NULL))
    face <- .material.colors(layer$col, layer$alpha)
    keep <- which(face$alpha > 0)
    if (length(keep)) {
        rows <- as.vector(t(layer$triangles[keep, , drop = FALSE]))
        rgl::triangles3d(X[rows, , drop = FALSE],
            col = rep(face$col[keep], each = 3L),
            alpha = rep(face$alpha[keep], each = 3L), lit = layer$lit,
            front = "filled", back = "filled", polygon_offset = c(1, 1))
    }
    edge <- .material.colors(layer$edge.col, layer$edge.alpha)
    if (layer$edges && edge$alpha > 0) {
        rows <- as.vector(t(layer$edge.matrix))
        rgl::segments3d(X[rows, , drop = FALSE], col = edge$col, alpha = edge$alpha,
                        lwd = layer$edge.width, lit = FALSE)
    }
    invisible(NULL)
}
