animation.fixture <- function() {
    X <- rbind(a = c(0, 0), b = c(2, 0), c = c(0, 2))
    first <- X; first[3, ] <- NA
    last <- X; last[1, ] <- NA
    list(frames = list(first, X, last), edges = rbind(c(1, 2), c(2, 3)))
}

test_that("frame normalization preserves identity, missingness and original bounds", {
    d <- animation.fixture()
    info <- .animation.frames(d$frames, d$edges, NULL, NULL, NULL)
    expect_equal(info$frames[[1]][, 1:2], d$frames[[1]])
    expect_equal(info$frames[[1]][, 3], c(0, 0, NA), ignore_attr = TRUE)
    expect_equal(info$active, list(c(TRUE, TRUE, FALSE), rep(TRUE, 3), c(FALSE, TRUE, TRUE)))
    frames <- list(d$frames[[1]], d$frames[[2]] * 10, d$frames[[3]])
    expect_message(short <- .animation.frames(frames, d$edges, c("a", "b", "c"), NULL, 2),
                   "Retaining 2 of 3")
    expect_identical(short$frame.index, c(1L, 3L))
    expect_equal(short$labels, c("a", "c"))
    expect_gt(short$limits[1, 2], 20)
    expect_identical(.animation.frames(frames, NULL, NULL, c(1, 2), 2)$frame.index, c(1L, 2L))
})

test_that("malformed coordinates and ambiguous row orders are rejected", {
    d <- animation.fixture(); X <- d$frames[[2]]
    expect_error(.animation.frames(list(X), NULL, NULL, NULL, 100), "at least two")
    for (bad in list(Inf, NaN, NA_real_)) {
        Y <- X; Y[1, 1] <- bad
        expect_error(.animation.frames(list(X, Y), NULL, NULL, NULL, 100), "entirely")
    }
    Y <- X; rownames(Y) <- rev(rownames(Y))
    expect_error(.animation.frames(list(X, Y), NULL, NULL, NULL, 100), "same row names")
    Z <- X; Z[,] <- NaN
    expect_false(any(.animation.frames(list(Z, X), NULL, NULL, NULL, 100)$active[[1]]))
    Y <- X; Y[,] <- NA_real_
    expect_error(.animation.frames(list(Y, Y), NULL, NULL, NULL, 100), "finite point")
    expect_error(.animation.frames(list(X, X), rbind(c(1, 4)), NULL, NULL, 100), "indices")
    expect_error(.animation.frames(list(X, X), NULL, NULL, c(2, 1), 100), "increasing")
    expect_error(.animation.frames(list(X, X), NULL, "one", NULL, 100), "per original frame")
    expect_error(.animation.frames(list(X, X), NULL, NULL, NULL, 1), "max.frames")
    expect_error(.animation.frames(list(X, X[, 1, drop = FALSE]), NULL, NULL, NULL, 100), "identical")
})

test_that("controls preserve recorded positions and hide inactive points and incident edges", {
    skip_if(!nzchar(system.file(package = "rgl")))
    d <- animation.fixture()
    w <- animate.frames(d$frames, d$edges, col = c("red", "blue", "#00FF0080"),
                         labels = c("<script>bad</script>", "middle", "end"))
    info <- attr(w, "ivue.animation")
    player <- w$append[[1]]
    points <- player$x$actions[[1]]
    edges <- player$x$actions[[2]]
    # vertexControl pads its values with the first and last rows.
    expect_equal(points$values[3, 1:9], as.vector(info$frames[[2]]), ignore_attr = TRUE)
    expect_equal(points$values[2, 10:12], c(1, 1, 0), ignore_attr = TRUE)
    expect_equal(points$values[4, 10:12], c(0, 1, 128/255), ignore_attr = TRUE)
    expect_equal(edges$values[2, 13:16], c(1, 1, 0, 0), ignore_attr = TRUE)
    expect_equal(edges$values[4, 13:16], c(0, 0, 1, 1), ignore_attr = TRUE)
    expect_false(points$interp)
    expect_match(player$x$labels[1], "&lt;script&gt;")
    expect_equal(player$x$sceneId, w$elementId)
    expect_equal(w$x$players, player$elementId)
    expect_equal(info$camera$fov, 0)
    expect_error(plot3D.plain(info$frames[[1]]), "finite")
})

test_that("animation creation restores device state and supports empty frames and no edges", {
    skip_if(!nzchar(system.file(package = "rgl")))
    opts <- options(rgl.useNULL = TRUE); on.exit(options(opts))
    dev <- rgl::open3d(useNULL = TRUE); on.exit(rgl::close3d(dev), add = TRUE)
    sub <- rgl::newSubscene3d()
    devices <- rgl::rgl.dev.list()
    X <- matrix(NA_real_, 1, 3)
    w <- animate.frames(list(X, matrix(c(0, 1, 2), 1)))
    expect_length(w$append[[1]]$x$actions, 1)
    expect_equal(rgl::rgl.dev.list(), devices)
    expect_equal(rgl::currentSubscene3d(), sub)
    expect_equal(rgl::cur3d(), dev)
    expect_error(animate.frames(list(X, matrix(c(0, 1, 2), 1)), camera = list(bad = 1)), "camera")
    expect_equal(rgl::rgl.dev.list(), devices)
    path <- tempfile(fileext = ".html")
    on.exit(unlink(c(path, sub(".html$", "_files", path)), recursive = TRUE), add = TRUE)
    htmlwidgets::saveWidget(w, path, selfcontained = FALSE)
    expect_match(paste(readLines(path, warn = FALSE), collapse = "\n"), "rglPlayer")
})

test_that("GIF export writes moving frames, honors overwrite and restores devices", {
    skip_if(!nzchar(system.file(package = "rgl")))
    skip_if_not_installed("magick")
    d <- animation.fixture(); w <- animate.frames(d$frames, d$edges, fps = 4)
    path <- tempfile(fileext = ".gif"); on.exit(unlink(path))
    devices <- grDevices::dev.list()
    expect_equal(write.animation.gif(w, path, width = 180, height = 160, final.hold = 1),
                 normalizePath(path))
    expect_identical(grDevices::dev.list(), devices)
    images <- magick::image_read(path)
    expect_gte(length(images), 3)
    expect_true(all(magick::image_info(images)$width == 180))
    expect_true(all(magick::image_info(images)$height == 160))
    difference <- magick::image_compare(images[1], images[length(images)], metric = "AE")
    expect_gt(attr(difference, "distortion"), 0)
    before <- readBin(path, "raw", n = file.info(path)$size)
    expect_error(write.animation.gif(w, path), "already exists")
    expect_identical(readBin(path, "raw", n = file.info(path)$size), before)
    expect_error(write.animation.gif(w, path, overwrite = TRUE, width = 0), "width")
    expect_error(write.animation.gif(w, path, overwrite = TRUE, fps = 0.001), "fps")
    expect_error(write.animation.gif(w, path, overwrite = TRUE, final.hold = 1000), "final.hold")
    expect_identical(readBin(path, "raw", n = file.info(path)$size), before)
    expect_error(write.animation.gif(w, tempfile(fileext = ".png")), "end in .gif")
    p <- animate.frames(d$frames, camera = list(fov = 30))
    expect_error(write.animation.gif(p, tempfile(fileext = ".gif")), "orthographic")
    expect_silent(write.animation.gif(w, path, width = 180, height = 160, overwrite = TRUE,
                                     loop = FALSE, labels = FALSE))
})

test_that("GIF projection preserves relative motion and uses a single camera", {
    skip_if(!nzchar(system.file(package = "rgl")))
    X <- rbind(c(0, 0, 0), c(1, 0, 0))
    Y <- X; Y[, 3] <- 2
    w <- animate.frames(list(X, Y), camera = camera.zup(elevation = 0, turn = 0))
    info <- attr(w, "ivue.animation")
    p <- .animation.projection(info)
    expect_equal(p$frames[[2]][, 2] - p$frames[[1]][, 2], rep(2, 2))
    expect_equal(p$frames[[2]][, 1] - p$frames[[1]][, 1], rep(0, 2))
})
