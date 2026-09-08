options(rgl.useNULL = TRUE)
source("tools/retinal-view-orientation.R")
pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
camera <- ivue::camera.zup(elevation = 18, turn = -28, fov = 0)
set.seed(20260908)
X <- matrix(rnorm(60), ncol = 3)
age <- rep(c("P14", "P8"), each = 10)
check <- function(X, camera) {
    result <- orient.retinal.stage(X, age, camera)
    stopifnot(max(abs(as.matrix(dist(X)) -
        as.matrix(dist(result$coordinates)))) < 1e-10,
        result$camera.offset[3] > 0,
        max(abs(result$camera.offset[1:2])) < 1e-10)
    result
}
invisible(check(X, camera))
# Exact parallel and antiparallel directions exercise both zero-cross-product cases.
axis.X <- cbind(ifelse(age == "P14", 1, -1), rep(0, 20), rep(0, 20))
for (sign in c(1, -1)) {
    target <- as.vector(t(camera$userMatrix[1:3, 1:3]) %*% c(0, 0, 1))
    invisible(check(sign * axis.X[, 1] %o% target, camera))
}
stopifnot(inherits(try(orient.retinal.stage(X, rep("P8", 20), camera),
                      silent = TRUE), "try-error"))
cat("PASS: P14 faces the viewer; proper rotations preserve all pairwise distances.\n")
