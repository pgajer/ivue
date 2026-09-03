graph.fixture <- function() list(
    adj.list = list(2L, c(1L, 3L), 2L, integer()),
    weight.list = list(2, c(2, 4), 4, numeric()))

test_that("graph formats preserve weights, vertex identity and isolates", {
    a <- .normalize.graph(graph.fixture())
    edges <- data.frame(from = c("1", "2"), to = c("2", "3"), weight = c(2, 4))
    b <- .normalize.graph(edges, vertices = 1:4)
    expect_identical(a, b)
    mat <- matrix(0, 4, 4)
    mat[1, 2] <- mat[2, 1] <- 2
    mat[2, 3] <- mat[3, 2] <- 4
    expect_equal(.normalize.graph(mat), a)
    expect_equal(.normalize.graph(mat, vertices = letters[1:4])$vertices$id, letters[1:4])
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    expect_s3_class(plot3D.graph(list(edges = data.frame(from = "a", to = "b", weight = 2),
        vertices = letters[1:4]), X = as.data.frame(matrix(1:12, ncol = 3))), "htmlwidget")
    skip_if_not_installed("Matrix")
    expect_equal(.normalize.graph(Matrix::Matrix(mat, sparse = TRUE)), a)
    skip_if_not_installed("igraph")
    ig <- igraph::graph_from_data_frame(edges, directed = FALSE, vertices = data.frame(name = 1:4))
    c <- .normalize.graph(ig)
    expect_equal(c$vertices$id, a$vertices$id)
    expect_equal(c$edges, a$edges)
})

test_that("invalid graph data are rejected rather than silently reinterpreted", {
    g <- graph.fixture()
    g$weight.list[[1]] <- 3
    expect_error(.normalize.graph(g), "equal weights")
    g <- graph.fixture(); g$adj.list[[1]] <- c(2L, 2L); g$weight.list[[1]] <- c(2, 2)
    expect_error(.normalize.graph(g), "Duplicate")
    g <- graph.fixture(); g$weight.list[[1]] <- NA_real_
    expect_error(.normalize.graph(g), "finite")
    expect_error(.normalize.graph(data.frame(from = 1, to = 2, weight = 1)), "vertex set")
    expect_error(.normalize.graph(data.frame(from = 1, to = 5, weight = 1), vertices = 1:4), "endpoints")
    expect_error(.normalize.graph(data.frame(from = 1, to = 1, weight = 1), vertices = 1:4), "Self-loops")
    expect_error(.normalize.graph(data.frame(from = c(1, 2), to = c(2, 1), weight = 1), vertices = 1:4), "Parallel")
    expect_error(.normalize.graph(graph.fixture(), weight.type = "unweighted"), "non-unit")
})

test_that("coordinates bypass igraph and align with named vertices", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    g <- graph.fixture()
    X <- matrix(1:12, ncol = 3)
    local_mocked_bindings(.compute.igraph.layout = function(...) stop("layout must not run"))
    w <- plot3D.graph(g, X = X)
    expect_equal(nrow(attr(w, "ivue")$graph$vertices), 4)
    rownames(X) <- as.character(4:1)
    w <- plot3D.graph(g, X = X)
    expect_equal(unname(attr(w, "ivue")$X), unname(X[4:1, ]))
    expect_error(plot3D.graph(g, X = X, layout = "fr"), "exactly one")
    rownames(X)[1] <- "extra"
    expect_error(plot3D.graph(g, X = X), "match vertex")
    zero <- list(adj.list = rep(list(integer()), 4), weight.list = rep(list(numeric()), 4))
    expect_s3_class(plot3D.graph(zero, X = unname(X)), "htmlwidget")
    g$weight.list <- lapply(g$weight.list, function(x) x * 0)
    expect_s3_class(plot3D.graph(g, X = unname(X)), "htmlwidget")
})

test_that("layout semantics and random state are explicit", {
    skip_if_not_installed("igraph")
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    g <- graph.fixture()
    expect_error(.compute.igraph.layout(g, "fr"), "weight.type")
    expect_error(.compute.igraph.layout(g, "fr", weight.type = "distance"), "strength")
    set.seed(51)
    old <- .Random.seed
    X <- .compute.igraph.layout(g, "kk", weight.type = "distance")
    expect_identical(.Random.seed, old)
    expect_equal(dim(X), c(4L, 3L))
    expect_true(all(is.finite(X)))
    expect_equal(X, .compute.igraph.layout(g, "kk", weight.type = "distance"))
    expect_s3_class(plot3D.graph(g, layout = "fr", weight.type = "strength"), "htmlwidget")
    g$weight.list <- lapply(g$weight.list, function(x) x * 0)
    expect_error(.compute.igraph.layout(g, "kk", weight.type = "distance"), "positive")
    expect_error(plot3D.graph(g, layout = function(g) matrix(0, 2, 2)), "3 columns")
    expect_identical(.Random.seed, old)
})
test_that("matrix vertex sets match the matrix dimensions", {
  A <- matrix(c(0, 1, 1, 0), 2L)
  expect_error(.normalize.graph(A, vertices = c("a", "b", "extra")), "vertex count")
  expect_error(.normalize.graph(A, vertices = "a"), "vertex count")
})
