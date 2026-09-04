test_that("mesh construction validates faces and deduplicates shared edges", {
    faces <- rbind(c(1, 2, 3), c(1, 3, 4))
    mesh <- layer3D.mesh(faces)
    expect_s3_class(mesh, "ivue_layer")
    expect_equal(mesh$triangles, faces)
    expect_equal(nrow(mesh$edge.matrix), 5L)
    expect_true(all(mesh$edge.matrix[, 1] < mesh$edge.matrix[, 2]))
    expect_equal(sum(mesh$edge.matrix[, 1] == 1 & mesh$edge.matrix[, 2] == 3), 1)
    expect_equal(mesh$alpha, c(.2, .2))
    empty <- layer3D.mesh(matrix(numeric(), 0, 3))
    expect_equal(dim(empty$edge.matrix), c(0L, 2L))
    expect_length(empty$alpha, 0)
    for (bad in list(1:3, matrix(1:4, 2), matrix(c(1, 1, 2), 1),
                    matrix(c(0, 1, 2), 1), matrix(c(1, 2, 3.5), 1),
                    matrix(c(1, 2, NA), 1), matrix(c(1, 2, Inf), 1),
                    matrix(c(1, 2, 3i), 1), rbind(faces, c(3, 2, 1))))
        expect_error(layer3D.mesh(bad))
    for (args in list(list(alpha = -1), list(alpha = 1.1), list(alpha = NA),
                     list(alpha = 1i), list(alpha = 1:3), list(col = "bad-color"),
                     list(edge.col = c("red", "blue")), list(edge.alpha = 2),
                     list(edge.width = 0), list(edges = 1), list(lit = NA)))
        expect_error(do.call(layer3D.mesh, c(list(triangles = faces), args)))
})

test_that("mesh coordinates, face colors and opacity survive capture", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- rbind(c(0, 0, 0), c(1, 0, 0), c(1, 1, 1), c(0, 1, 0))
    f <- rbind(c(1, 2, 3), c(1, 3, 4))
    mesh <- layer3D.mesh(f, col = c("#FF000080", "blue"), alpha = c(.5, .25),
                         edge.col = "#00000080", edge.alpha = .5)
    objects <- function(w, type) unname(Filter(function(o) identical(o$type, type),
                                                attr(w, "ivue")$scene$objects))
    w <- plot3D.plain(X, layers = list(mesh))
    face <- objects(w, "triangles")
    expect_length(face, 1)
    expect_equal(unname(face[[1]]$vertices), X[as.vector(t(f)), ], tolerance = 1e-6)
    expect_lte(max(abs(face[[1]]$material$alpha - rep(c(64/255, .25), each = 3))),
                1/255)
    expect_equal(face[[1]]$material$color, rep(c("#FF0000", "#0000FF"), each = 3))
    edge <- objects(w, "lines")
    # rgl can include other line objects; identify the mesh by its ten endpoints.
    edge <- Filter(function(o) nrow(o$vertices) == 10, edge)
    expect_length(edge, 1)
    expect_equal(edge[[1]]$material$alpha, 64/255, tolerance = 1/255)
    expect_equal(unname(edge[[1]]$vertices), X[as.vector(t(mesh$edge.matrix)), ],
                 tolerance = 1e-6)
    Z <- X; Z[3, ] <- c(-.5, .25, -.7)
    moved <- plot3D.cont(Z, seq_len(4), layers = list(mesh), camera = camera.zup())
    expect_equal(unname(objects(moved, "triangles")[[1]]$vertices),
                 Z[as.vector(t(f)), ], tolerance = 1e-6)
    expect_s3_class(plot3D.groups(X, c("a", "b", "a", "b"), layers = list(mesh)),
                    "htmlwidget")
    graph <- data.frame(from = 1:3, to = 2:4, weight = 1)
    named <- X; rownames(named) <- as.character(1:4)
    gw <- plot3D.graph(graph, vertices = 1:4, X = named[4:1, ], layers = list(mesh))
    expect_equal(unname(objects(gw, "triangles")[[1]]$vertices), X[as.vector(t(f)), ],
                 tolerance = 1e-6)
    wire <- plot3D.plain(X, layers = list(layer3D.mesh(f, alpha = 0)))
    expect_length(objects(wire, "triangles"), 0)
    filled <- plot3D.plain(X, layers = list(layer3D.mesh(f, edges = FALSE)))
    expect_length(objects(filled, "triangles"), 1)
    expect_s3_class(plot3D.plain(X, layers = list(layer3D.mesh(matrix(numeric(), 0, 3)))),
                    "htmlwidget")
    expect_s3_class(plot3D.plain(X * 0, layers = list(mesh)), "htmlwidget")
})

test_that("mesh rendering restores the caller device on success and failure", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    old <- options(rgl.useNULL = TRUE); on.exit(options(old))
    dev <- rgl::open3d(useNULL = TRUE, silent = TRUE)
    on.exit(rgl::close3d(dev), add = TRUE)
    rgl::points3d(1, 2, 3)
    before <- rgl::scene3d(minimal = FALSE)
    devices <- rgl::rgl.dev.list()
    X <- matrix(1:9, 3)
    expect_s3_class(plot3D.plain(X, layers = list(layer3D.mesh(matrix(1:3, 1)))),
                    "htmlwidget")
    expect_error(plot3D.plain(X, layers = list(layer3D.mesh(matrix(c(1, 2, 4), 1)))),
                 "between 1 and 3")
    expect_identical(rgl::rgl.dev.list(), devices)
    expect_equal(rgl::cur3d(), dev)
    expect_equal(rgl::scene3d(minimal = FALSE), before)
})
