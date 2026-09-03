#' Reusable Color Scales
#'
#' Construct a scale once to keep colors comparable across scenes. Scale
#' construction and mapping do not load rgl or create a graphics device.
#'
#' @param values Numeric reference values. Missing values are allowed; infinity
#'   is rejected. Automatic limits are fitted to these reference values only.
#' @param mode Continuous interpolation (default) or explicit bins.
#' @param palette R colors or a function of the requested number of colors.
#'   NULL uses the Viridis HCL palette.
#' @param color.map Optional function of numeric values returning R colors.
#'   Mutually exclusive with palette.
#' @param limits Two finite, nondecreasing numeric limits. Equal limits are
#'   permitted for constant data.
#' @param center Optional reference value for a continuous diverging scale. Supply an
#'   appropriate diverging palette explicitly. Automatic limits are symmetric
#'   about center; explicit limits must contain it strictly.
#' @param breaks Strictly increasing numerical bin boundaries, or NULL.
#' @param n.bins Positive number of requested bins.
#' @param method Uniform or quantile bin boundaries.
#' @param winsor.p Explicit tail probability used when fitting uniform bins.
#'   Zero (default) disables winsorization; must be less than 0.5.
#' @param oob Out-of-bounds handling: squish to limits, use missing color, or error.
#' @param na.color Color for missing values and censored out-of-bounds values.
#' @param digits Significant digits for legend labels, not bin calculations.
#' @return A scale of class `ivue_color_scale`. `map.colors()` returns a list
#'   containing row-aligned `colors`, a `legend` data frame (label, color,
#'   count), and the scale. Continuous legend ticks have NA counts; binned and
#'   group counts describe the mapped input. A Missing entry is added as needed.
#' @export
#' @examples
#' sc <- color.scale.cont(c(-1, 0, 1))
#' map.colors(c(-1, 0.5, NA), sc)
#' groups <- factor(c("low", "high", "low"), levels = c("low", "high"))
#' group.scale <- color.scale.groups(groups, c(low = "blue", high = "red"))
#' map.colors(groups, group.scale)
color.scale.cont <- function(values, mode = c("continuous", "binned"),
                             palette = NULL, color.map = NULL, limits = NULL,
                             center = NULL, breaks = NULL, n.bins = 10L,
                             method = c("uniform", "quantile"), winsor.p = 0,
                             oob = c("squish", "censor", "error"),
                             na.color = "gray80", digits = 3L) {
    .values(values)
    mode <- match.arg(mode)
    method <- match.arg(method)
    oob <- match.arg(oob)
    .scalar(n.bins, "n.bins", 1, 10000, TRUE)
    .scalar(digits, "digits", 1, 15, TRUE)
    .scalar(winsor.p, "winsor.p", 0, 0.5)
    if (winsor.p >= 0.5) .stop("winsor.p must be less than 0.5.")
    if (winsor.p > 0 && (mode != "binned" || method != "uniform"))
        .stop("winsor.p requires uniform binned mode.")
    .colors(na.color, 1, "na.color")
    if (!is.null(palette) && !is.null(color.map))
        .stop("Supply palette or color.map, not both.")
    if (!is.null(color.map) && !is.function(color.map)) .stop("color.map must be a function.")
    ref <- values[!is.na(values)]
    if (winsor.p > 0 && length(ref)) {
        q <- stats::quantile(ref, c(winsor.p, 1 - winsor.p), names = FALSE)
        ref <- pmin(pmax(ref, q[1]), q[2])
    }
    automatic <- is.null(limits)
    if (automatic) limits <- if (length(ref)) range(ref) else c(0, 1)
    if (!is.numeric(limits) || length(limits) != 2L || any(!is.finite(limits)) ||
        limits[1] > limits[2]) .stop("limits must be two finite nondecreasing numbers.")
    if (!is.null(center)) {
        if (mode != "continuous") .stop("center requires continuous mode; use explicit bin colors for binned scales.")
        .scalar(center, "center")
        if (is.null(palette) && is.null(color.map))
            .stop("Supply a diverging palette or color.map when using center.")
        if (automatic) {
            d <- max(abs(limits - center))
            if (d == 0) d <- max(1, abs(center)) * 1e-8
            limits <- center + c(-d, d)
        }
        if (center <= limits[1] || center >= limits[2])
            .stop("center must be strictly inside limits.")
    }
    if (!is.null(breaks) && mode != "binned") .stop("breaks require binned mode.")
    if (mode == "binned") {
        if (is.null(breaks)) {
            breaks <- if (method == "quantile" && length(ref)) {
                unique(as.numeric(stats::quantile(pmin(pmax(ref, limits[1]), limits[2]),
                       seq(0, 1, length.out = n.bins + 1L))))
            } else seq(limits[1], limits[2], length.out = n.bins + 1L)
            breaks <- unique(c(limits[1], breaks, limits[2]))
            if (length(breaks) == 1L) {
                eps <- max(1, abs(breaks)) * 1e-8
                breaks <- breaks + c(-eps, eps)
            }
        }
        if (!is.numeric(breaks) || length(breaks) < 2L || any(!is.finite(breaks)) ||
            any(diff(breaks) <= 0)) .stop("breaks must be finite and strictly increasing.")
        if (!automatic && diff(limits) != 0 && !isTRUE(all.equal(range(breaks), limits)))
            .stop("Explicit limits must agree with the outer breaks.")
        limits <- range(breaks)
    }
    n <- if (mode == "binned") length(breaks) - 1L else 256L
    colors <- if (is.null(color.map)) .palette(palette, n) else NULL
    structure(list(type = "continuous", mode = mode, limits = limits,
                   center = center, breaks = breaks, colors = colors,
                   color.map = color.map, oob = oob, na.color = na.color,
                   digits = digits), class = "ivue_color_scale")
}

#' @rdname color.scale.cont
#' @param groups Reference group labels or a factor. Factors retain level order;
#'   other inputs use first-occurrence order. Missing labels remain missing.
#' @param colors Optional named group colors, covering all reference levels.
#' @param unknown Whether unseen groups raise an error or use the missing color.
#' @export
color.scale.groups <- function(groups, colors = NULL, na.color = "gray80",
                               unknown = c("error", "missing")) {
    .groups(groups)
    unknown <- match.arg(unknown)
    .colors(na.color, 1, "na.color")
    levels <- if (is.factor(groups)) levels(groups) else unique(as.character(groups[!is.na(groups)]))
    if (is.null(colors)) colors <- stats::setNames(grDevices::hcl.colors(length(levels), "Dark 3"), levels)
    if (length(colors) && (is.null(names(colors)) || anyNA(names(colors)) ||
        anyDuplicated(names(colors)) || any(!nzchar(names(colors)))))
        .stop("Group colors must have unique nonempty names.")
    if (any(!levels %in% names(colors))) .stop("Named colors must cover every group level.")
    .colors(unname(colors), length(colors))
    structure(list(type = "groups", levels = levels, colors = colors[levels],
                   na.color = na.color, unknown = unknown), class = "ivue_color_scale")
}

#' @rdname color.scale.cont
#' @param x Values or groups to map, according to the scale type.
#' @param scale A scale constructed by `color.scale.cont()` or `color.scale.groups()`.
#' @export
map.colors <- function(x, scale) {
    if (!inherits(scale, "ivue_color_scale")) .stop("scale must be an ivue color scale.")
    if (scale$type == "groups") {
        .groups(x)
        labels <- as.character(x)
        index <- match(labels, scale$levels)
        if (scale$unknown == "error" && any(!is.na(x) & is.na(index)))
            .stop("Unknown groups are not present in the reference scale.")
        colors <- unname(scale$colors[index])
        missing <- is.na(index)
        legend <- data.frame(label = scale$levels, color = unname(scale$colors),
                             count = tabulate(index, length(scale$levels)))
    } else {
        .values(x)
        outside <- !is.na(x) & (x < scale$limits[1] | x > scale$limits[2])
        if (scale$oob == "error" && any(outside)) .stop("Values outside scale limits.")
        if (scale$oob == "censor") x[outside] <- NA_real_
        x <- pmin(pmax(x, scale$limits[1]), scale$limits[2])
        missing <- is.na(x)
        if (scale$mode == "binned") {
            index <- as.integer(cut(x, scale$breaks, include.lowest = TRUE, labels = FALSE))
            mid <- utils::head(scale$breaks, -1L) / 2 + utils::tail(scale$breaks, -1L) / 2
            bin.colors <- if (is.null(scale$color.map)) scale$colors else
                .mapped.colors(scale$color.map, mid)
            colors <- bin.colors[index]
            b <- format(signif(scale$breaks, scale$digits), trim = TRUE)
            labs <- paste0("(", utils::head(b, -1L), ", ", utils::tail(b, -1L), "]")
            labs[1] <- sub("(", "[", labs[1], fixed = TRUE)
            legend <- data.frame(label = labs, color = bin.colors,
                                 count = tabulate(index, length(mid)))
        } else {
            colors <- rep(scale$na.color, length(x))
            colors[!missing] <- .continuous.colors(x[!missing], scale)
            ticks <- unique(seq(scale$limits[1], scale$limits[2], length.out = 5L))
            legend <- data.frame(label = format(signif(ticks, scale$digits), trim = TRUE),
                                 color = .continuous.colors(ticks, scale), count = NA_integer_)
        }
    }
    colors[missing] <- scale$na.color
    if (any(missing)) legend <- rbind(legend, data.frame(label = "Missing",
                                        color = scale$na.color, count = sum(missing)))
    list(colors = unname(colors), legend = legend, scale = scale)
}

.values <- function(x) {
    if (!is.numeric(x) || is.complex(x) || !is.null(dim(x)) || any(is.infinite(x)))
        .stop("values must be a numeric vector without infinity.")
}

.groups <- function(x) {
    if ((!is.atomic(x) && !is.factor(x)) || !is.null(dim(x)))
        .stop("groups must be an atomic vector or factor.")
}

.palette <- function(palette, n) {
    if (is.null(palette)) return(grDevices::hcl.colors(n, "Viridis"))
    if (is.function(palette)) {
        cols <- palette(n)
        if (length(cols) != n) .stop("palette(n) must return n colors.")
        return(.colors(cols, n))
    }
    .colors(palette)
    if (!length(palette)) .stop("palette must not be empty.")
    if (length(palette) == n) return(palette)
    if (length(palette) == 1L) return(rep(palette, n))
    grDevices::colorRampPalette(palette, alpha = TRUE)(n)
}

.mapped.colors <- function(fun, x) {
    if (!length(x)) return(character())
    cols <- fun(x)
    if (length(cols) != length(x)) .stop("color.map(values) must return one color per value.")
    .colors(cols, length(x))
}

.continuous.colors <- function(x, scale) {
    if (!length(x)) return(character())
    if (!is.null(scale$color.map)) return(.mapped.colors(scale$color.map, x))
    span <- diff(scale$limits)
    t <- if (span == 0) rep(0.5, length(x)) else (x - scale$limits[1]) / span
    if (!is.null(scale$center)) {
        left <- x <= scale$center
        t[left] <- 0.5 * (x[left] - scale$limits[1]) / (scale$center - scale$limits[1])
        t[!left] <- 0.5 + 0.5 * (x[!left] - scale$center) / (scale$limits[2] - scale$center)
    }
    scale$colors[1L + pmin(255L, pmax(0L, floor(t * 255)))]
}
