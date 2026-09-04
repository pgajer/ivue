test_that("surface grids have explicit coordinate and cell ordering", {
    x <- c(-2, 0, 3); y <- c(-1, 4)
    z <- outer(x, y, function(x, y) x + 2*y)
    s <- layer3D.surface(x, y, z, col = c("red", "blue"), alpha = c(.2, .4))
    expect_s3_class(s, "ivue_layer")
    expect_equal(s$coordinates, cbind(x = rep(x, 2), y = rep(y, each = 3), z = as.vector(z)))
    expect_equal(unname(s$triangles), rbind(c(1, 2, 5), c(2, 3, 6), c(1, 5, 4), c(2, 6, 5)))
    expect_equal(s$col, rep(c("red", "blue"), 2))
    expect_equal(s$alpha, rep(c(.2, .4), 2))
    expect_equal(nrow(s$edge.matrix), 7L)
    expect_false(any(apply(s$edge.matrix, 1, function(e) identical(as.integer(e), c(1L, 5L)))))
    expect_equal(nrow(layer3D.surface(1:2, 1:2, matrix(0, 2, 2))$triangles), 2L)
    for (xx in list(x, rev(x))) for (yy in list(y, rev(y))) {
        a <- layer3D.surface(xx, yy, outer(xx, yy, "+"))
        p <- a$coordinates[a$triangles[1, ], ]
        u <- p[2, ] - p[1, ]; v <- p[3, ] - p[1, ]
        expect_gt(u[1]*v[2] - u[2]*v[1], 0)
    }
})

test_that("surface rejects ambiguous grids and invalid styling", {
    for (bad in list(1, c(1, 1), c(1, 3, 2), c(NA, 2), c(1, Inf),
                    c(1, 2i), matrix(1:2, 2), c("a", "b"))) {
        expect_error(layer3D.surface(bad, 1:2, matrix(0, 2, 2)), "strictly monotone")
        expect_error(layer3D.surface(1:2, bad, matrix(0, 2, 2)), "strictly monotone")
    }
    for (bad in list(1:4, matrix(0, 3, 2), matrix(NA, 2, 2), matrix(Inf, 2, 2),
                    matrix(1i, 2, 2), matrix("a", 2, 2)))
        expect_error(layer3D.surface(1:2, 1:2, bad), "finite numeric matrix")
    for (args in list(list(col = "bad-color"), list(col = c("red", "blue")),
        list(alpha = c(.1, .2)), list(alpha = NA), list(alpha = 1i), list(alpha = 2),
        list(edges = NA), list(lit = 1), list(edge.width = 0), list(edge.alpha = -1)))
        expect_error(do.call(layer3D.surface, c(list(x = 1:2, y = 1:2, z = matrix(0, 2, 2)), args)))
})

test_that("surface capture is independent of plot coordinates across families", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    x <- c(-2, 0, 2); y <- c(-1, 1)
    s <- layer3D.surface(x, y, outer(x, y, "+"), col = "#0088FF80", alpha = .5,
                         edges = TRUE, edge.alpha = .3, lit = TRUE)
    objects <- function(w, type) unname(Filter(function(o) identical(o$type, type),
                                                attr(w, "ivue")$scene$objects))
    X <- rbind(c(0, 0, 0), c(.1, .2, .1))
    graph <- data.frame(from = "a", to = "b", weight = 1)
    named <- X; rownames(named) <- c("a", "b")
    widgets <- list(plot3D.plain(X, layers = list(s)),
        plot3D.cont(X + 5, 1:2, layers = list(s)),
        plot3D.groups(X, c("a", "b"), layers = list(s)),
        plot3D.graph(graph, vertices = c("a", "b"), X = named[2:1, ], layers = list(s)))
    for (w in widgets) {
        face <- objects(w, "triangles")
        expect_length(face, 1)
        expect_equal(unname(face[[1]]$vertices),
                     unname(s$coordinates[as.vector(t(s$triangles)), ]), tolerance = 1e-6)
        expect_true(all(abs(face[[1]]$material$alpha - 64/255) < 1/255))
        # rgl omits material properties equal to the scene default.
        lighting <- face[[1]]$material$lit
        if (is.null(lighting)) lighting <- attr(w, "ivue")$scene$material$lit
        expect_true(lighting)
        lines <- Filter(function(o) nrow(o$vertices) == 14L, objects(w, "lines"))
        expect_length(lines, 1)
        expect_equal(unname(lines[[1]]$vertices),
                     unname(s$coordinates[as.vector(t(s$edge.matrix)), ]), tolerance = 1e-6)
    }
    expect_equal(attr(widgets[[1]], "ivue")$X, X)
    wire <- plot3D.plain(X, layers = list(layer3D.surface(x, y, outer(x, y), alpha = 0, edges = TRUE)))
    expect_length(objects(wire, "triangles"), 0)
    expect_length(Filter(function(o) nrow(o$vertices) == 14L, objects(wire, "lines")), 1)
    fill <- plot3D.plain(X, layers = list(layer3D.surface(x, y, outer(x, y))))
    expect_length(Filter(function(o) nrow(o$vertices) == 14L, objects(fill, "lines")), 0)
})

test_that("surface rendering preserves the caller device and options", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    old <- options(rgl.useNULL = TRUE); on.exit(options(old))
    dev <- rgl::open3d(useNULL = TRUE, silent = TRUE)
    on.exit(rgl::close3d(dev), add = TRUE)
    rgl::points3d(1, 2, 3)
    before <- rgl::scene3d(minimal = FALSE)
    devices <- rgl::rgl.dev.list()
    s <- layer3D.surface(1:2, 1:2, matrix(0, 2, 2))
    expect_s3_class(plot3D.plain(matrix(1:9, 3), layers = list(s)), "htmlwidget")
    broken <- s; broken$triangles[1, 1] <- 100
    expect_error(plot3D.plain(matrix(1:9, 3), layers = list(broken)), "between 1 and 4")
    expect_identical(rgl::rgl.dev.list(), devices)
    expect_equal(rgl::cur3d(), dev)
    expect_equal(rgl::scene3d(minimal = FALSE), before)
    expect_true(getOption("rgl.useNULL"))
})
