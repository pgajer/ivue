# Display-only orientation; never feed rotated coordinates back into a fit.
orient.retinal.stage <- function(X, age, camera, stage = "P14") {
    if (!is.matrix(X) || ncol(X) != 3L || any(!is.finite(X)) ||
        length(age) != nrow(X) || anyNA(age)) {
        stop("Supply finite 3D coordinates and one stage label per point.")
    }
    selected <- age == stage
    if (!any(selected) || all(selected)) {
        stop("The reference stage and other stages must both be present.")
    }
    centered <- sweep(X, 2L, colMeans(X), "-")
    direction <- colMeans(centered[selected, , drop = FALSE])
    radius <- max(sqrt(rowSums(centered^2)))
    length <- sqrt(sum(direction^2))
    if (length <= 1e-10 * radius) {
        stop("The reference-stage centroid has no stable viewing direction.")
    }
    from <- direction / length
    # Positive camera z points toward the viewer in the orthographic rgl scene.
    target <- as.vector(t(camera$userMatrix[1:3, 1:3]) %*% c(0, 0, 1))
    target <- target / sqrt(sum(target^2))
    axis <- c(from[2] * target[3] - from[3] * target[2],
              from[3] * target[1] - from[1] * target[3],
              from[1] * target[2] - from[2] * target[1])
    sine <- sqrt(sum(axis^2))
    cosine <- max(-1, min(1, sum(from * target)))
    rotation <- diag(3)
    if (sine > 1e-12) {
        axis <- axis / sine
        rotation <- rgl::rotationMatrix(atan2(sine, cosine),
                                        axis[1], axis[2], axis[3])[1:3, 1:3]
    } else if (cosine < 0) {
        axis <- diag(3)[, which.min(abs(from))]
        axis <- axis - sum(axis * from) * from
        axis <- axis / sqrt(sum(axis^2))
        rotation <- rgl::rotationMatrix(pi, axis[1], axis[2], axis[3])[1:3, 1:3]
    }
    oriented <- centered %*% t(rotation)
    camera.offset <- as.vector(camera$userMatrix[1:3, 1:3] %*%
        colMeans(oriented[selected, , drop = FALSE]))
    stopifnot(max(abs(crossprod(rotation) - diag(3))) < 1e-10,
              abs(det(rotation) - 1) < 1e-10,
              max(abs(camera.offset[1:2])) < 1e-9 * length,
              camera.offset[3] > 0)
    list(coordinates = oriented, rotation = rotation,
         stage = stage, stage.count = sum(selected),
         camera.offset = camera.offset)
}
