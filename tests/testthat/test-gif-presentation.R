test_that("GIF zoom follows rgl and retains observer translation", {
    skip_if(!nzchar(system.file(package="rgl")))
    X <- rbind(c(-1, 0, 0), c(1, 0, 0))
    result <- lapply(c(.4, .8), function(z) {
        w <- animate.frames(list(X, X*2), camera=camera.zup(90, 0, zoom=z))
        info <- attr(w, "ivue.animation")
        p <- .animation.projection(info)
        # A fixed segment occupies half the fraction at twice the zoom.
        diff(p$frames[[1]][, 1]) / diff(p$limits[1, ])
    })
    expect_equal(result[[1]] / result[[2]], 2)
    w <- animate.frames(list(X, X), camera=list(userMatrix=diag(4), fov=0,
        zoom=.8, observer=c(.2, -.3, 4)))
    info <- attr(w, "ivue.animation"); p <- .animation.projection(info)
    expect_equal(colMeans(p$frames[[1]])[1:2], c(-.2, .3), tolerance=1e-6)
    radius <- sqrt(sum((diff(t(info$scene.limits))/2)^2))*1.1
    expect_equal(p$limits[1, 2], (4-radius)*.8)
})

test_that("GIF annotations support every mapping and reject unreadable layouts", {
    skip_if(!nzchar(system.file(package="rgl")))
    skip_if_not_installed("magick")
    d <- readRDS(system.file("extdata", "retinal-development.rds", package="ivue"))
    groups <- sort(unique(as.character(d$annotations$cell.type)))
    # Use the bundled eleven-category vocabulary, plus a missing observation.
    expect_length(groups, 11)
    X <- cbind(seq_len(12), sin(seq_len(12)), 0)
    values <- c(seq(-1, 1, length.out=11), NA)
    mappings <- list(map.colors(values, color.scale.cont(values, limits=c(-1, 1))),
        map.colors(values, color.scale.cont(values, limits=c(-1, 1), mode="binned", n.bins=3)),
        map.colors(c(groups, NA), color.scale.groups(groups,
            colors=stats::setNames(rep(c("#FF000080", "#0000FF80"), length.out=length(groups)), groups))))
    paths <- tempfile(fileext=".gif"); on.exit(unlink(paths))
    for (mapping in mappings) {
        w <- animate.frames(list(X, X*.8, X), mapping=mapping,
            caption=paste(rep("Color is fixed; positions follow the current frame.", 3), collapse=" "),
            legend.title="Fixed annotation")
        info <- attr(w, "ivue.animation")
        expect_equal(info$legend.title, "Fixed annotation")
        expect_silent(write.animation.gif(w, paths, width=640, height=640,
            annotations=TRUE, overwrite=TRUE))
        gif <- magick::image_coalesce(magick::image_read(paths))
        expect_true(all(magick::image_info(gif)$width == 640))
        # The fixed legend/caption is identical while the middle geometry moves.
        strip <- magick::image_crop(gif, "260x640+380+0", repage=TRUE)
        expect_identical(magick::image_data(strip[1]), magick::image_data(strip[2]))
        expect_error(write.animation.gif(w, paths, width=100, height=100,
            annotations=TRUE, overwrite=TRUE), "fit")
        expect_error(write.animation.gif(w, paths, annotations=NA, overwrite=TRUE), "annotations")
    }
})
