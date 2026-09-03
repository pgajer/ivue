.stop <- function(...) stop(..., call. = FALSE)

.scalar <- function(x, name, lower = -Inf, upper = Inf, integer = FALSE) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
        x < lower || x > upper || (integer && x != floor(x))) {
        .stop(name, " must be a finite numeric scalar in [", lower, ", ", upper,
              "]", if (integer) " and a whole number" else "", ".")
    }
    x
}

.flag <- function(x, name) {
    if (!is.logical(x) || length(x) != 1L || is.na(x))
        .stop(name, " must be TRUE or FALSE.")
    x
}

.text <- function(x, name) {
    if (!is.character(x) || length(x) != 1L || is.na(x))
        .stop(name, " must be one string.")
    x
}

.coordinates <- function(X) {
    if (is.data.frame(X) && !all(vapply(X, is.numeric, logical(1))))
        .stop("Every column of X must be numeric.")
    if ((!is.matrix(X) && !is.data.frame(X)) || ncol(X) != 3L)
        .stop("X must be a numeric matrix or data frame with exactly 3 columns.")
    X <- as.matrix(X)
    if (!is.numeric(X) || nrow(X) < 1L || any(!is.finite(X)))
        .stop("X must contain at least one row of finite numeric coordinates.")
    storage.mode(X) <- "double"
    X
}

.indices <- function(x, n, name) {
    if (!is.numeric(x) || any(!is.finite(x)) || any(x != floor(x)) ||
        any(x < 1 | x > n))
        .stop(name, " must contain whole-number row indices between 1 and ", n, ".")
    as.integer(x)
}

.colors <- function(x, n = length(x), name = "colors") {
    if (!is.character(x) && !is.numeric(x)) .stop(name, " must contain R colors.")
    if (anyNA(x) || !(length(x) %in% c(1L, n)))
        .stop(name, " must have length 1 or ", n, " without missing entries.")
    tryCatch(grDevices::col2rgb(x, alpha = TRUE),
             error = function(e) .stop("Invalid ", name, ": ", conditionMessage(e)))
    rep(x, length.out = n)
}

.named.list <- function(x, allowed, name) {
    if (!is.list(x) || (length(x) && (is.null(names(x)) ||
        any(!nzchar(names(x))) || anyDuplicated(names(x)) ||
        any(!names(x) %in% allowed))))
        .stop(name, " must be a named list with unique keys from: ",
              paste(allowed, collapse = ", "), ".")
    x
}

.with.alpha <- function(col, alpha) {
    rgba <- grDevices::col2rgb(col, alpha = TRUE) / 255
    grDevices::rgb(rgba[1, ], rgba[2, ], rgba[3, ], rgba[4, ] * alpha)
}
