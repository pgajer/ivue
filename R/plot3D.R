#' Interactive 3D Point Clouds
#'
#' These functions always return a browser widget. They use a private null
#' device and restore caller graphics options and the previous device. Loading
#' ivue does not load rgl. No XQuartz or native display is required.
#'
#' @param X Numeric matrix or all-numeric data frame with exactly three columns
#'   and at least one row. Coordinates must be finite; rows are never dropped.
#' @param col Plain point colors, length one or nrow(X).
#' @param point.type Draw screen-space points or data-space spheres.
#' @param point.size Positive point size in screen pixels.
#' @param sphere.radius Positive radius in data units. NULL uses 1 percent of
#'   the largest coordinate span, with a minimum of 1e-8. Does not choose type.
#' @param alpha Opacity multiplier in `[0, 1]`, preserving alpha in supplied colors.
#' @param highlight NULL (all), a logical mask, or one-based row indices.
#' @param highlight.style,non.highlight.style Named style overrides: point.type,
#'   point.size, sphere.radius, col, alpha. Color vectors must align to all rows.
#'   Highlighting changes styling, never the fitted color scale or row identity.
#'   A style's alpha replaces the global alpha multiplier for that subset;
#'   it still multiplies the alpha component of the selected colors.
#' @param axes Show axes.
#' @param xlab,ylab,zlab Axis labels.
#' @param aspect Equal data-unit scales (default), or normalized axis lengths.
#'   Normalization distorts relative distances when coordinate spans differ.
#' @param camera Named list of theta, phi, fov, zoom, or a 4-by-4 userMatrix.
#'   Use [camera.zup()] for an initial view with z pointing upward.
#' @param width,height Widget dimensions in pixels; NULL width fills its container.
#' @param background.color Canvas background color.
#' @param layers List of layer3D specifications, evaluated before widget capture.
#' @param shiny.brush Optional rgl brush configuration passed as shinyBrush.
#' @return An rglwidget/htmlwidget. `attr(widget, "ivue")` contains coordinates,
#'   row.ids, mapped colors, highlight, draw.ids (row, object, index), camera,
#'   aspect, captured scene, and (for colored plots) mapping data. Object IDs
#'   describe the captured scene, not an open device. Save separately with
#'   `htmlwidgets::saveWidget()`.
#'   Mapped colors describe the base scale before highlight and opacity
#'   overrides. Legends reflect the scale and global alpha, not highlight styles.
#' @export
#' @examples
#' set.seed(1)
#' xs <- runif(250, -1, 1)
#' ys <- runif(250, -1, 1)
#' X <- cbind(xs, ys, 1.2 * (xs^2 - ys^2))
#' if (nzchar(system.file(package = "rgl"))) w <- plot3D.plain(X, axes = TRUE)
#' if (nzchar(system.file(package = "rgl"))) {
#'   sc <- color.scale.cont(X[, 3])
#'   continuous <- plot3D.cont(X, X[, 3], scale = sc)
#'   grouped <- plot3D.groups(X, ifelse(X[, 3] >= 0, "positive", "negative"))
#' }
plot3D.plain <- function(X, col = "gray55", point.type = c("point", "sphere"),
                         point.size = 3, sphere.radius = NULL, alpha = 1,
                         highlight = NULL, highlight.style = list(),
                         non.highlight.style = list(col = "gray80", alpha = 0.4),
                         axes = FALSE, xlab = "", ylab = "", zlab = "",
                         aspect = c("equal", "normalized"), camera = list(),
                         width = NULL, height = 600L, background.color = "white",
                         layers = list(), shiny.brush = NULL) {
    .scene(X, col, match.arg(point.type), point.size, sphere.radius, alpha,
           highlight, highlight.style, non.highlight.style, axes, xlab, ylab,
           zlab, match.arg(aspect), camera, width, height, background.color, layers, shiny.brush)
}

#' @rdname plot3D.plain
#' @param values Numeric values, one per row. Missing values use the scale's NA color.
#' @param scale Reusable scale, or NULL to fit a default scale to all values/groups.
#' @param legend.show Show the HTML color legend.
#' @param legend.title Legend title.
#' @param legend.position Side of the scene for the legend.
#' @param legend.font.size Legend font size in pixels.
#' @param legend.width Legend maximum width in pixels, constrained by the container.
#' @param ... Named scene controls from plot3D.plain, excluding X and col.
#'   Unknown names and legacy argument spellings are rejected.
#' @export
plot3D.cont <- function(X, values, scale = NULL, legend.show = TRUE,
                        legend.title = "Value", legend.position = c("left", "right"),
                        legend.font.size = 12, legend.width = 240, ...) {
    X <- .coordinates(X)
    .values(values)
    if (length(values) != nrow(X)) .stop("values must have one entry per row of X.")
    if (is.null(scale)) scale <- color.scale.cont(values)
    if (!inherits(scale, "ivue_color_scale") || scale$type != "continuous")
        .stop("plot3D.cont requires a continuous or binned numerical scale.")
    .colored.scene(X, values, scale, legend.show, legend.title,
                   match.arg(legend.position), legend.font.size, legend.width, list(...))
}

#' @rdname plot3D.plain
#' @param groups Group labels or factor, one per row; groups need not be clusters.
#' @export
plot3D.groups <- function(X, groups, scale = NULL, legend.show = TRUE,
                         legend.title = "Group", legend.position = c("left", "right"),
                         legend.font.size = 12, legend.width = 240, ...) {
    X <- .coordinates(X)
    .groups(groups)
    if (length(groups) != nrow(X)) .stop("groups must have one entry per row of X.")
    if (is.null(scale)) scale <- color.scale.groups(groups)
    if (!inherits(scale, "ivue_color_scale") || scale$type != "groups")
        .stop("plot3D.groups requires a group scale.")
    .colored.scene(X, groups, scale, legend.show, legend.title,
                   match.arg(legend.position), legend.font.size, legend.width, list(...))
}

.colored.scene <- function(X, values, scale, show, title, position, font.size, width, dots) {
    .named.list(dots, setdiff(names(formals(plot3D.plain)), c("X", "col")), "scene controls")
    .flag(show, "legend.show")
    .text(title, "legend.title")
    .scalar(font.size, "legend.font.size", 1)
    .scalar(width, "legend.width", 1)
    mapping <- map.colors(values, scale)
    w <- do.call(plot3D.plain, c(list(X = X, col = mapping$colors), dots))
    info <- attr(w, "ivue")
    info$mapping <- mapping
    if (show) w <- .legend(w, mapping, title, position, font.size, width,
                           if (is.null(dots$alpha)) 1 else dots$alpha)
    attr(w, "ivue") <- info
    w
}
