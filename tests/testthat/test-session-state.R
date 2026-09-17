test_that("annotation drawing restores graphical parameters on success and error", {
    grDevices::pdf(NULL, width = 7, height = 7)
    device <- grDevices::dev.cur()
    on.exit(grDevices::dev.off(device), add = TRUE)
    graphics::par(mar = c(2, 3, 4, 1), xaxs = "r", yaxs = "r")
    info <- list(caption = "A fixed caption", mapping = NULL)
    layout <- .animation.layout(info, 640, 640, FALSE, TRUE)
    before <- graphics::par(no.readonly = TRUE)
    expect_silent(.animation.annotations(info, layout, 640, 640))
    expect_equal(graphics::par(no.readonly = TRUE), before)

    layout$side <- 160
    layout$rows <- list("Group")
    info$mapping <- list(legend = data.frame(color = "not-a-color"))
    expect_error(.animation.annotations(info, layout, 640, 640), "color")
    expect_equal(graphics::par(no.readonly = TRUE), before)
})

test_that("GIF export restores the active device and session state on success and error", {
    skip_if(!nzchar(system.file(package = "rgl")))
    skip_if_not_installed("magick")
    X <- rbind(c(0, 0), c(1, 0), c(0, 1))
    w <- animate.frames(list(X, X * 2), caption = "Example caption")
    path <- tempfile(fileext = ".gif")
    on.exit(unlink(path), add = TRUE)
    grDevices::pdf(NULL)
    first <- grDevices::dev.cur()
    on.exit(grDevices::dev.off(first), add = TRUE)
    graphics::par(mar = c(2, 3, 4, 1), col = "blue", las = 2)
    first.par <- graphics::par(no.readonly = TRUE)
    grDevices::pdf(NULL)
    second <- grDevices::dev.cur()
    on.exit(grDevices::dev.off(second), add = TRUE)
    second.par <- graphics::par(no.readonly = TRUE)
    grDevices::dev.set(first)
    devices <- grDevices::dev.list()
    opts <- options()
    wd <- getwd()
    for (fail in c(FALSE, TRUE)) {
        if (fail) {
            expect_error(write.animation.gif(w, path, width = 64, height = 64,
                annotations = TRUE, overwrite = TRUE), "fit")
        } else {
            expect_silent(write.animation.gif(w, path, width = 240, height = 240,
                annotations = TRUE))
        }
        expect_identical(grDevices::dev.list(), devices)
        expect_identical(grDevices::dev.cur(), first)
        grDevices::dev.set(first)
        expect_equal(graphics::par(no.readonly = TRUE), first.par)
        grDevices::dev.set(second)
        expect_equal(graphics::par(no.readonly = TRUE), second.par)
        grDevices::dev.set(first)
        expect_identical(options(), opts)
        expect_identical(getwd(), wd)
    }
})

test_that("widget rendering restores a false or absent null-device option after errors", {
    skip_if(!nzchar(system.file(package = "rgl")))
    old <- options("rgl.useNULL")
    on.exit(options(old), add = TRUE)
    X <- matrix(seq_len(9), ncol = 3)
    for (value in list(FALSE, NULL)) {
        options(rgl.useNULL = value)
        wd <- getwd()
        expect_s3_class(plot3D.plain(X), "htmlwidget")
        expect_identical(getOption("rgl.useNULL"), value)
        devices <- rgl::rgl.dev.list()
        expect_error(plot3D.plain(X, layers = list(layer3D.callback(function(ctx) {
            stop("drawing failed")
        }))), "drawing failed")
        expect_identical(getOption("rgl.useNULL"), value)
        expect_identical(rgl::rgl.dev.list(), devices)
        expect_identical(getwd(), wd)
    }
})
