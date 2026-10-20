# Validate the scientific checkpoint before making any display transformations.
read.retinal.sgd <- function(file, display.ids, pc.file, require.complete = FALSE) {
    if (!nzchar(file) || !file.exists(file)) {
        stop("Set IVUE_RETINAL_SGD to a verified scientific-coordinate checkpoint.")
    }
    sgd <- readRDS(file)
    protocol <- readRDS(file.path(dirname(dirname(file)), "protocol.rds"))
    pc <- readRDS(pc.file)
    stopifnot(identical(sgd$cache.key, protocol$cache.key),
              protocol$identity$inputs[["pc20"]] ==
                  digest::digest(file = pc.file, algo = "sha256"),
              identical(sgd$settings, protocol$settings),
              identical(sgd$cells, pc$cells),
              identical(sgd$display.ids, display.ids),
              identical(sgd$cells[sgd$display.indices], display.ids),
              sgd$settings$backend == "sgd", sgd$settings$pivots == 2000L,
              sgd$settings$dimension == 3L,
              sgd$settings$target == "euclidean_pc20",
              identical(sgd$fit.metadata$data_preparation$target_metric, "euclidean"),
              is.matrix(sgd$coordinates),
              identical(dim(sgd$coordinates), c(120804L, 3L)),
              all(is.finite(sgd$coordinates)),
              sgd$fit.metadata$stopping$epochs_completed == sgd$epoch,
              !isTRUE(sgd$converged))
    if (require.complete && sgd$epoch != sgd$settings$schedule.epochs) {
        stop("The published vignette requires the completed 500-epoch checkpoint.")
    }
    sgd
}
