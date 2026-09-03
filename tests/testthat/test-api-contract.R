test_that("graph attributes and ID order survive normalization", {
    v <- data.frame(id = c("third", "first", "isolate"), note = c("a", "b", "c"))
    e <- data.frame(from = "first", to = "third", weight = 2, label = "edge")
    g <- .normalize.graph(list(vertices = v, edges = e))
    expect_identical(g$vertices, v)
    expect_equal(g$edges$from, 2L)
    expect_equal(g$edges$to, 1L)
    expect_identical(g$edges$label, "edge")
    bad <- v; names(bad)[2] <- "id"
    expect_error(.normalize.graph(e, vertices = bad), "unique")
    bad <- e; names(bad)[4] <- "weight"
    expect_error(.normalize.graph(bad, vertices = v), "unique")
    a <- list(adj.list = list(third = 2L, first = 1L, isolate = integer()),
              weight.list = list(third = 2, first = 2, isolate = numeric()))
    expect_equal(.normalize.graph(a)$vertices$id, v$id)
    names(a$weight.list) <- rev(names(a$weight.list))
    expect_error(.normalize.graph(a), "Named weight")
})

test_that("igraph's own ID attribute is not overwritten", {
    skip_if_not_installed("igraph")
    ig <- igraph::graph_from_data_frame(data.frame(from = "a", to = "b", weight = 2),
      directed = FALSE, vertices = data.frame(name = c("b", "a", "c"),
                                             id = c(12L, 11L, 13L), label = c("B", "A", "C")))
    g <- .normalize.graph(ig)
    expect_identical(g$vertices$id, c("b", "a", "c"))
    expect_equal(g$vertices$.igraph.id, c(12L, 11L, 13L))
    expect_identical(g$vertices$label, c("B", "A", "C"))
    ig <- igraph::set_vertex_attr(ig, ".igraph.id", value = 1:3)
    expect_error(.normalize.graph(ig), "conflicting")
})

test_that("dense and sparse graph conversions preserve all isolates and weights", {
    skip_if_not_installed("Matrix")
    for (n in c(1L, 4L, 20L)) {
        A <- matrix(0, n, n, dimnames = list(paste0("v", seq_len(n)), paste0("v", seq_len(n))))
        if (n > 1L) A[1, 2] <- A[2, 1] <- -2
        dense <- .normalize.graph(A)
        sparse <- .normalize.graph(Matrix::Matrix(A, sparse = TRUE))
        expect_equal(sparse, dense)
        expect_equal(nrow(sparse$vertices), n)
    }
    A <- matrix(c(0, 2, 2, 0), 2, dimnames = list(c("a", "b"), c("a", "b")))
    expect_equal(.normalize.graph(A[, 2:1]), .normalize.graph(A))
})

test_that("invalid numeric and callback controls fail without implicit coercion", {
    expect_error(color.scale.cont(1 + 1i), "numeric vector")
    expect_error(color.scale.cont(1:4, mode = "binned", center = 2, palette = c("blue", "red")),
                 "continuous mode")
    expect_error(plot3D.plain(matrix(1 + 1i, 2, 3)), "finite numeric")
    expect_error(plot3D.plain(matrix(1:9, 3), point.size = 1 + 1i), "numeric scalar")
    expect_error(layer3D.callback(identity, stats::setNames(list(1), NA_character_)), "unique")
    expect_error(plot3D.plain(matrix(1:9, 3), highlight = 1 + 1i), "whole-number")
    expect_error(plot3D.plain(matrix(1:9, 3), highlight.style = list(col = "not-a-color"),
                             highlight = integer()), "Invalid")
})

test_that("legends preserve global opacity and escape user labels", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- matrix(1:9, 3)
    w <- plot3D.groups(X, rep("<script>alert(1)</script>", 3), alpha = 0.5,
      scale = color.scale.groups("<script>alert(1)</script>",
        colors = stats::setNames("#FF000080", "<script>alert(1)</script>")))
    html <- w$jsHooks$render[[2]]$data$legend
    expect_match(html, "rgba(255,0,0,0.2510)", fixed = TRUE)
    expect_match(html, "&lt;script&gt;", fixed = TRUE)
    expect_false(grepl("<script>", html, fixed = TRUE))
    sc <- color.scale.cont(1:3, palette = c("red", "blue"))
    w <- plot3D.cont(X, 1:3, scale = sc, alpha = 0.5)
    expect_match(w$jsHooks$render[[2]]$data$legend, "0.5020", fixed = TRUE)
    expect_identical(attr(w, "ivue")$mapping$colors, map.colors(1:3, sc)$colors)
})

test_that("layout failures and missing initial random seeds restore state", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    old <- if (exists(".Random.seed", .GlobalEnv)) .Random.seed else NULL
    on.exit(if (is.null(old)) {
      if (exists(".Random.seed", .GlobalEnv)) rm(".Random.seed", envir = .GlobalEnv)
    } else assign(".Random.seed", old, .GlobalEnv), add = TRUE)
    if (exists(".Random.seed", .GlobalEnv)) rm(".Random.seed", envir = .GlobalEnv)
    g <- list(edges = data.frame(from = "a", to = "b", weight = 1), vertices = c("a", "b"))
    expect_error(plot3D.graph(g, layout = function(g) { runif(5); stop("layout failure") }), "layout failure")
    expect_false(exists(".Random.seed", .GlobalEnv))
    w <- plot3D.graph(g, layout = function(g) matrix(runif(6), 2, 3))
    expect_s3_class(w, "htmlwidget")
    expect_false(exists(".Random.seed", .GlobalEnv))
})
