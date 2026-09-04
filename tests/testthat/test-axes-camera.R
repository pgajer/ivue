test_that("z-up cameras are proper rotations with documented directions", {
    for (e in c(-90, -20, 0, 20, 90)) for (t in c(-135, 0, 45, 360)) {
        u <- camera.zup(e, t)$userMatrix
        expect_equal(crossprod(u), diag(4), tolerance = 1e-14)
        expect_equal(det(u), 1, tolerance = 1e-14)
        expect_equal(u[4, ], c(0, 0, 0, 1))
        expect_equal(u[1, 3], 0)
        expect_gte(u[2, 3], -1e-14)
    }
    u <- camera.zup()$userMatrix
    expect_lt(u[1, 1], 0) # x left, y right, both below origin
    expect_gt(u[1, 2], 0)
    expect_true(all(u[2, 1:2] < 0))
    u <- camera.zup(turn = 0)$userMatrix
    expect_equal(u[1:3, 1], c(1, 0, 0))
    expect_lt(u[3, 2], 0) # positive y points away from the eye
    expect_equal(camera.zup(turn = -135), camera.zup(turn = 225))
    for (a in list(list(elevation = 91), list(turn = Inf), list(fov = 180),
                   list(zoom = 0), list(elevation = 1i)))
        expect_error(do.call(camera.zup, a), "finite numeric")
})

test_that("axis geometry has correct endpoints, solid heads, and label gaps", {
    x <- rbind(c(-1, -2, -3), c(1, 2, 3))
    a <- layer3D.axes(padding = 0.2)
    g <- .axes.geometry(a, x)
    for (j in 1:3) {
        extent <- 1.2 * j
        expect_equal(g[[j]]$tip[j], extent)
        expect_equal(unname(g[[j]]$shaft[1, j]), -extent)
        expect_equal(unname(g[[j]]$shaft[2, j]), extent - .04 * 2 * extent)
        expect_equal(g[[j]]$label[j], extent + .04 * 2 * extent)
        expect_equal(g[[j]]$tip[-j], c(0, 0))
        expect_equal(dim(g[[j]]$head), c(144L, 3L))
        expect_true(all(is.finite(g[[j]]$head)))
        expect_equal(max(g[[j]]$head[, j]), extent)
    }
    origin <- c(10, 20, 30)
    shifted <- .axes.geometry(layer3D.axes(origin = origin), sweep(x, 2, origin, "+"))
    for (j in 1:3) expect_equal(shifted[[j]]$head, sweep(g[[j]]$head, 2, origin, "+"))
    limits <- rbind(c(-2, .01), c(-3, 4), c(-1, 1))
    fixed <- .axes.geometry(layer3D.axes(limits = limits), x * 100)
    expect_equal(fixed[[1]]$tip, c(.01, 0, 0))
    expect_gt(fixed[[1]]$shaft[2, 1], 0) # short positive arm retains origin
    no.head <- .axes.geometry(layer3D.axes(head.length = 0), x)
    expect_equal(nrow(no.head[[1]]$head), 0)
    expect_equal(no.head[[1]]$shaft[2, ], no.head[[1]]$tip)
    for (xx in list(matrix(0, 1, 3), cbind(-1:1, 0, 0))) {
        gg <- .axes.geometry(a, xx)
        expect_true(all(vapply(gg, function(z) all(is.finite(z$head)), logical(1))))
        expect_true(all(vapply(gg, function(z) sum(z$tip^2) > 0, logical(1))))
    }
    expect_error(.axes.geometry(a, rbind(rep(-1e308, 3), rep(1e308, 3))), "overflow")
})

test_that("axis controls reject malformed and ambiguous inputs", {
    for (args in list(list(origin = c(0, 1)), list(origin = c(0, NA, 1)),
        list(origin = c(0, 1, 1i)), list(limits = matrix(1:6, 2)),
        list(limits = cbind(rep(0, 3), rep(1, 3))), list(padding = -1),
        list(labels = c("x", "y")), list(labels = c("x", "y", NA)),
        list(col = "bad-color"), list(width = c(1, 2)), list(width = 0),
        list(head.length = .3), list(head.angle = 0), list(head.angle = pi/2),
        list(cex = 0), list(label.offset = -1))) {
        expect_error(do.call(layer3D.axes, args))
    }
    expect_s3_class(layer3D.axes(labels = rep("", 3)), "ivue_layer")
})

test_that("axes work with every plotting family and preserve scene state", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    old <- options(rgl.useNULL = TRUE)
    on.exit(options(old))
    device <- rgl::open3d(useNULL = TRUE, silent = TRUE)
    on.exit(rgl::close3d(device), add = TRUE)
    rgl::points3d(1, 2, 3)
    before <- rgl::scene3d(minimal = FALSE)
    x <- rbind(c(-1, -1, 0), c(1, 0, 1), c(0, 1, -1))
    a <- layer3D.axes(col = c("#FF000080", "green", "blue"))
    camera <- camera.zup()
    widgets <- list(
        plot3D.plain(x, layers = list(a), camera = camera),
        plot3D.cont(x, x[, 3], layers = list(a), camera = camera),
        plot3D.groups(x, c("a", "a", "b"), layers = list(a), camera = camera),
        plot3D.graph(data.frame(from = 1:2, to = 2:3, weight = 1),
            vertices = 1:3, X = x, layers = list(a), camera = camera))
    heads <- function(w) Filter(function(o) identical(o$type, "triangles"),
                                attr(w, "ivue")$scene$objects)
    for (w in widgets) {
        expect_s3_class(w, "htmlwidget")
        expect_equal(unname(attr(w, "ivue")$X), x)
        expect_equal(attr(w, "ivue")$camera[names(camera)], camera, tolerance = 1e-7)
        expect_length(heads(w), 3)
        expect_equal(heads(w)[[1]]$material$alpha, 128/255, tolerance = 1/255)
    }
    turned <- plot3D.plain(x, layers = list(a), camera = camera.zup(35, 40))
    expect_equal(unname(lapply(heads(turned), function(o) o$vertices)),
                 unname(lapply(heads(widgets[[1]]), function(o) o$vertices)))
    expect_equal(rgl::cur3d(), device)
    expect_equal(rgl::scene3d(minimal = FALSE), before)
    expect_error(plot3D.plain(x, layers = list(layer3D.axes(padding = 1e308))),
                 "overflow")
    expect_equal(rgl::cur3d(), device)
    expect_equal(rgl::scene3d(minimal = FALSE), before)
})

test_that("camera and axes constructors do not load the optional renderer", {
    skip_if_not_installed("callr")
    root <- normalizePath(test_path("../.."))
    source <- dir.exists(file.path(root, "R"))
    result <- callr::r(function(root, source) {
        if (source) pkgload::load_all(root, quiet = TRUE) else library(ivue)
        cam <- ivue::camera.zup()
        axes <- ivue::layer3D.axes()
        list(loaded = "rgl" %in% loadedNamespaces(), matrix = dim(cam$userMatrix),
             layer = inherits(axes, "ivue_layer"))
    }, list(root, source))
    expect_false(result$loaded)
    expect_identical(result$matrix, c(4L, 4L))
    expect_true(result$layer)
})
