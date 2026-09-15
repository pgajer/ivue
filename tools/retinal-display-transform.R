# Display-only transforms. Inputs and fitted diagnostics retain their original units.
retinal.display.transform <- function(X, rescale = FALSE) {
    stopifnot(is.matrix(X), ncol(X) == 3L, nrow(X) > 0L, all(is.finite(X)))
    center <- colMeans(X)
    centered <- sweep(X, 2L, center, "-")
    scale.factor <- if (rescale) max(sqrt(rowSums(centered^2))) else 1
    stopifnot(is.finite(scale.factor), scale.factor > 0)
    list(coordinates = centered / scale.factor,
         transform = list(
             formula = "display = (input - center) / scale.factor",
             center = unname(center), scale.factor = scale.factor,
             center.population = paste(nrow(X), "selected display cells"),
             scale.rule = if (rescale) "maximum Euclidean radius after centering" else "none",
             parameter.status = "recorded from input coordinates",
             orientation = "not stored; figure-specific rigid rotations are applied only during rendering"))
}
