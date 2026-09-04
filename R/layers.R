#' Geometric Layers for a 3D Scene
#'
#' Layers are evaluated on the scene's private device before widget capture.
#' They never open devices themselves. Row indices refer to the original X.
#'
#' @param edges Two-column matrix of one-based endpoint indices. Empty edges
#'   are allowed. Self-loops are rejected; duplicate edges retain their order.
#' @param col Color, scalar or one per edge/path segment/label.
#' @param width Positive line width, scalar or one per edge/path segment.
#' @param path Ordered vector of row indices. Fewer than two indices draws nothing.
#' @param rows Row indices for labels.
#' @param labels Text for each selected row.
#' @param cex Positive text size multiplier.
#' @param adj Two finite label-adjustment values.
#' @param offset Three finite offsets added to label positions in data units.
#' @return An `ivue_layer` specification for the `layers` argument.
#' @export
#' @examples
#' edges <- matrix(c(1, 2, 2, 3), ncol = 2, byrow = TRUE)
#' layer3D.edges(edges)
#' layer3D.path(c(1, 3, 2), col = "red", width = 2)
#' layer3D.labels(c(1, 2), c("Start", "End"))
layer3D.edges <- function(edges, col = "gray65", width = 1) {
    if (!is.matrix(edges) || !is.numeric(edges) || ncol(edges) != 2L ||
        any(!is.finite(edges)) || any(edges < 1 | edges != floor(edges)))
        .stop("edges must be a two-column matrix of positive whole-number indices.")
    if (any(edges[, 1] == edges[, 2])) .stop("Self-loops are not supported by the edge layer.")
    .colors(col, nrow(edges), "col")
    .widths(width, nrow(edges))
    structure(list(type = "edges", edges = edges, col = col, width = width), class = "ivue_layer")
}

#' @rdname layer3D.edges
#' @export
layer3D.path <- function(path, col = "red3", width = 2) {
    if (!is.numeric(path) || any(!is.finite(path)) || any(path < 1 | path != floor(path)))
        .stop("path must contain positive whole-number row indices.")
    edges <- if (length(path) < 2L) matrix(integer(), 0, 2) else
        cbind(utils::head(path, -1L), utils::tail(path, -1L))
    out <- layer3D.edges(edges, col, width)
    out$path <- path
    out
}

#' @rdname layer3D.edges
#' @export
layer3D.labels <- function(rows, labels, col = "black", cex = 1,
                           adj = c(0.5, 0.5), offset = c(0, 0, 0)) {
    if (!is.numeric(rows) || any(!is.finite(rows)) || any(rows < 1 | rows != floor(rows)))
        .stop("rows must contain positive whole-number indices.")
    if (length(labels) != length(rows) || anyNA(labels))
        .stop("labels must have one nonmissing entry per row.")
    .scalar(cex, "cex", .Machine$double.eps)
    .colors(col, length(rows), "col")
    if (!is.numeric(adj) || length(adj) != 2L || any(!is.finite(adj)))
        .stop("adj must contain two finite numbers.")
    if (!is.numeric(offset) || length(offset) != 3L || any(!is.finite(offset)))
        .stop("offset must contain three finite numbers.")
    structure(list(type = "labels", rows = rows, labels = as.character(labels),
                   col = col, cex = cex, adj = adj, offset = offset), class = "ivue_layer")
}

#' Callback Layers
#'
#' An advanced escape hatch for drawing with rgl. The callback must not open,
#' close, or switch devices. Its context contains X, row.ids, colors, highlight,
#' and draw.ids (row, object, index). Captured object IDs are not live devices.
#'
#' @param fun Function called with context as its first argument.
#' @param args Named list of additional arguments to fun.
#' @return An `ivue_layer` specification.
#' @export
#' @examples
#' labels <- layer3D.callback(function(ctx) {
#'   rgl::text3d(ctx$X[1, , drop = FALSE], texts = "First point")
#' })
#' if (nzchar(system.file(package = "rgl"))) {
#'   w <- plot3D.plain(matrix(1:9, ncol = 3), layers = list(labels))
#' }
layer3D.callback <- function(fun, args = list()) {
    if (!is.function(fun)) .stop("fun must be a function.")
    if (!is.list(args) || (length(args) && (is.null(names(args)) ||
        anyNA(names(args)) || any(!nzchar(names(args))) || anyDuplicated(names(args)))))
        .stop("args must be a named list with unique argument names.")
    structure(list(type = "callback", fun = fun, args = args), class = "ivue_layer")
}

.widths <- function(width, n) {
    if (!is.numeric(width) || !(length(width) %in% c(1L, n)) ||
        any(!is.finite(width)) || any(width <= 0))
        .stop("width must be positive and have length 1 or the number of segments.")
    rep(width, length.out = n)
}

.draw.layer <- function(layer, context) {
    if (!inherits(layer, "ivue_layer"))
        .stop("Every layer must be constructed by a layer3D function.")
    X <- context$X
    if (layer$type == "callback") {
        do.call(layer$fun, c(list(context), layer$args))
    } else if (layer$type == "axes") {
        .draw.axes.layer(layer, context)
    } else if (layer$type == "edges") {
        .indices(as.vector(layer$edges), nrow(X), "edges")
        if (!is.null(layer$path)) .indices(layer$path, nrow(X), "path")
        n <- nrow(layer$edges)
        if (!n) return(invisible(NULL))
        material <- .material.colors(.colors(layer$col, n))
        widths <- .widths(layer$width, n)
        for (w in unique(widths)) {
            keep <- which(widths == w)
            xyz <- X[as.vector(t(layer$edges[keep, , drop = FALSE])), , drop = FALSE]
            rgl::segments3d(xyz, col = rep(material$col[keep], each = 2L),
                            alpha = rep(material$alpha[keep], each = 2L), lwd = w, lit = FALSE)
        }
    } else if (layer$type == "labels") {
        rows <- .indices(layer$rows, nrow(X), "label rows")
        if (length(rows)) {
            material <- .material.colors(.colors(layer$col, length(rows)))
            rgl::text3d(sweep(X[rows, , drop = FALSE], 2, layer$offset, "+"),
                texts = layer$labels, col = material$col, alpha = material$alpha,
                cex = layer$cex, adj = layer$adj)
        }
    } else .stop("Unknown layer type.")
    invisible(NULL)
}
