#' Interactive 3D Point Clouds
#'
#' These functions always return a browser widget. They use a private null
#' device and restore caller graphics options and the previous device. Loading
#' ivue does not load rgl. No XQuartz or native display is required.
#'
#' @param X Numeric matrix or all-numeric data frame with exactly three columns
#'   and at least one row. Coordinates must be finite; rows are never dropped.
#'   Explicit row names are unique, nonempty, nonmissing observation IDs.
#'   Automatic data-frame row numbers are not IDs. Point plots keep row order.
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
#'   Downloaded recipes also include observer (three finite eye coordinates,
#'   positive depth), which is tied to that scene's framing. Omit observer to
#'   fit the eye distance automatically when transferring an orientation.
#'   With no orientation supplied, defaults to [camera.zup()]: z upward,
#'   elevation 20 degrees, turn -135 degrees, orthographic projection, and
#'   zoom 0.8. A list containing only fov or zoom retains this orientation.
#'   Explicit theta, phi, or userMatrix selects an rgl camera instead; omitted
#'   controls then retain the previous defaults theta = 35, phi = 20,
#'   fov = 30, and zoom = 0.8. Use [camera.zup()] to customize a z-up view.
#' @param width,height Widget dimensions in pixels; NULL width fills its container.
#' @param background.color Canvas background color.
#' @param layers List of layer3D specifications, evaluated before widget capture.
#' @param limits Optional finite 3-by-2 matrix: rows x, y, z; columns lower,
#'   upper. Nondecreasing ranges must contain all point coordinates. These
#'   fix framing, not clipping planes: spheres and layers cannot expand the
#'   range and may extend outside the visible viewport. NULL fits automatically.
#'   Equal endpoints are accepted for constant axes. Use the same limits,
#'   camera, aspect, and widget dimensions for spatial comparisons. Equal
#'   aspect preserves data-unit distances; normalized aspect stretches axes
#'   according to these ranges. Limits never add observations or change IDs.
#' @param description Optional plain-text scene description for readers who
#'   cannot see or manipulate the canvas. NULL describes the point count.
#'   Also shown below the widget, including when scripts or WebGL are unavailable.
#' @param controls Show keyboard-operable view controls: rotate, zoom, reset,
#'   and download current view settings as an R recipe. The recipe contains
#'   camera, bounds, and aspect; use `source("ivue-view.R")`, then pass
#'   `view$camera`, `view$limits`, and `view$aspect` to a new plot. Browser
#'   interaction never changes the original R object. Match widget dimensions
#'   as well as settings for equal screen scale. Reset restores the initial view.
#' @param shiny.brush Optional rgl brush configuration passed as shinyBrush.
#' @return An rglwidget/htmlwidget. `attr(widget, "ivue")` contains coordinates,
#'   row.ids (integer row positions), observation.ids (explicit coordinate row
#'   names, or NULL), mapped colors, highlight, draw.ids (row, object, index), camera,
#'   aspect, captured scene, and (for colored plots) mapping data. Object IDs
#'   describe the captured scene, not an open device. Save separately with
#'   `htmlwidgets::saveWidget()`.
#'   Mapped colors describe the base scale before highlight and opacity
#'   overrides. Legends reflect the scale and global alpha, not highlight styles.
#' @details Named `values`, `groups`, per-point `col`, logical `highlight`, and
#'   style color vectors are matched to `rownames(X)`, using the same exact-ID
#'   rule as [plot3D.graph()]. Their names must cover every observation exactly
#'   once. Missing, empty, duplicate, partial, or extra names cause errors, as
#'   do named annotations without explicit coordinate row names. Only unnamed
#'   scalar colors are recycled. Unnamed vectors follow coordinate row order;
#'   use `unname()` explicitly if annotation names are not observation IDs.
#'   Numeric highlight indices and indexed layers always use coordinate row
#'   positions, regardless of names attached to those indices. Plotting never
#'   reorders point coordinates or infers IDs from an annotation vector.
#'
#'   Without a supplied categorical scale, factor levels set the color order;
#'   otherwise groups use first occurrence in the supplied annotation vector,
#'   before ID alignment. The same named vector therefore gives matching group
#'   colors in point and graph views even if their coordinate orders differ.
#'   Reuse a scale to keep colors fixed when annotation order or membership changes.
#' @seealso [color.scale.cont()], [map.colors()], [plot3D.graph()], [ivue-package],
#'   \href{../doc/function-guide.html}{Finding your way around ivue},
#'   \href{../doc/example-data.html}{Example data and recipes}.
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
#'   positions <- rbind(a = c(0, 0, 0), b = c(1, 1, 1), c = c(2, 0, 0))
#'   annotation <- c(c = 10, a = 0, b = 5)
#'   by.id <- plot3D.cont(positions, annotation) # a gets 0, b gets 5, c gets 10
#' }
plot3D.plain <- function(X, col = "gray55", point.type = c("point", "sphere"),
                         point.size = 3, sphere.radius = NULL, alpha = 1,
                         highlight = NULL, highlight.style = list(),
                         non.highlight.style = list(col = "gray80", alpha = 0.4),
                         axes = FALSE, xlab = "", ylab = "", zlab = "",
                         aspect = c("equal", "normalized"), camera = list(),
                         width = NULL, height = 600L, background.color = "white",
                         layers = list(), shiny.brush = NULL, limits = NULL,
                         description = NULL, controls = TRUE) {
    X <- .point.coordinates(X)
    col <- .align.point.data(col, X, "col")
    if (is.logical(highlight)) highlight <- .align.point.data(highlight, X, "highlight")
    if (is.list(highlight.style)) highlight.style$col <-
        .align.point.data(highlight.style$col, X, "highlight.style$col")
    if (is.list(non.highlight.style)) non.highlight.style$col <-
        .align.point.data(non.highlight.style$col, X, "non.highlight.style$col")
    .scene(X, col, match.arg(point.type), point.size, sphere.radius, alpha,
           highlight, highlight.style, non.highlight.style, axes, xlab, ylab,
           zlab, match.arg(aspect), camera, width, height, background.color, layers, shiny.brush,
           limits = limits, description = description, controls = controls)
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
    X <- .point.coordinates(X)
    .values(values)
    values <- .align.point.data(values, X, "values")
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
    X <- .point.coordinates(X)
    .groups(groups)
    reference.groups <- groups
    groups <- .align.point.data(groups, X, "groups")
    if (length(groups) != nrow(X)) .stop("groups must have one entry per row of X.")
    if (is.null(scale)) scale <- color.scale.groups(reference.groups)
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
