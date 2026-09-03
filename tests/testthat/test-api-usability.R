test_that("categorical plots have one discoverable canonical name", {
    exports <- getNamespaceExports("ivue")
    expect_true("plot3D.groups" %in% exports)
    expect_false("plot3D.cltrs" %in% exports)
})

test_that("prepared graphs expose stable edge order and revalidate on reuse", {
    edges <- data.frame(from = c("b", "a"), to = c("c", "b"),
                        weight = c(4, 2), note = c("first", "second"))
    g <- prepare.graph(edges, vertices = c("a", "b", "c", "isolate"), weight.type = "strength")
    expect_s3_class(g, "ivue_graph")
    expect_equal(g$edges$from, c(2L, 1L))
    expect_equal(g$edges$to, c(3L, 2L))
    expect_identical(g$edges$note, c("first", "second"))
    expect_identical(prepare.graph(g), g)
    bad <- g; bad$edges$from[1] <- 99
    expect_error(prepare.graph(bad), "between")
    bad <- g; bad$vertices$id[2] <- "a"
    expect_error(prepare.graph(bad), "unique")
    bad <- g; bad$edges$weight[1] <- NA
    expect_error(prepare.graph(bad), "finite")
    bad <- g; bad$directed <- NA
    expect_error(prepare.graph(bad), "TRUE or FALSE")
    expect_error(prepare.graph(g, vertices = letters[1:4]), "override")
    directed <- prepare.graph(edges, vertices = letters[1:3], directed = TRUE)
    expect_true(directed$directed)
})

test_that("graph preparation works in a fresh session without graphics backends", {
    skip_if_not_installed("callr")
    root <- normalizePath(test_path("../.."))
    source <- file.exists(file.path(root, "DESCRIPTION")) && dir.exists(file.path(root, "R"))
    result <- callr::r(function(root, source) {
        if (source) pkgload::load_all(root, quiet = TRUE) else library(ivue)
        g <- ivue::prepare.graph(data.frame(from = "a", to = "b"),
            vertices = c("a", "b", "isolate"), weight.type = "unweighted")
        list(vertices = g$vertices$id, weight = g$edges$weight,
             backends = intersect(c("rgl", "igraph"), loadedNamespaces()))
    }, list(root, source))
    expect_identical(result$vertices, c("a", "b", "isolate"))
    expect_equal(result$weight, 1)
    expect_length(result$backends, 0)
})

test_that("named graph annotations and styles align by exact ID", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    g <- prepare.graph(data.frame(from = "a", to = "b", weight = 2),
                       vertices = c("b", "a", "isolate"))
    X <- rbind(isolate = c(0, 1, 0), b = c(1, 0, 0), a = c(-1, 0, 0))
    values <- c(a = 10, isolate = 30, b = 20)
    sc <- color.scale.cont(values)
    w <- plot3D.graph(g, X = X, values = values, scale = sc)
    expect_identical(attr(w, "ivue")$X, X[c("b", "a", "isolate"), ])
    expect_identical(attr(w, "ivue")$mapping$colors, map.colors(c(20, 10, 30), sc)$colors)
    positional <- plot3D.graph(g, X = X, values = c(20, 10, 30), scale = sc)
    expect_identical(attr(positional, "ivue")$mapping, attr(w, "ivue")$mapping)
    groups <- stats::setNames(factor(c("low", "high", "mid"), levels = c("high", "mid", "low")),
                              c("a", "isolate", "b"))
    sc <- color.scale.groups(groups)
    w <- plot3D.graph(g, X = X, groups = groups, scale = sc)
    expect_identical(attr(w, "ivue")$mapping$colors, map.colors(c("mid", "low", "high"), sc)$colors)
    colors <- c(isolate = "green", a = "red", b = "blue")
    w <- plot3D.graph(g, X = X, col = colors,
        highlight = c(isolate = FALSE, a = TRUE, b = TRUE),
        highlight.style = list(col = colors))
    info <- attr(w, "ivue")
    expect_identical(unname(info$colors), c("blue", "red", "green"))
    expect_identical(unname(info$highlight), c(TRUE, TRUE, FALSE))
    selected <- info$scene$objects[[as.character(info$draw.ids$object[1])]]$colors
    expect_equal(unname(selected[, 1:3]), rbind(c(0, 0, 1), c(1, 0, 0)))
    for (keys in list(c("a", "a", "b"), c("a", "b", "extra"),
                      c("a", "b", ""), c("a", "b", NA), c("a", "b"))) {
        v <- stats::setNames(seq_along(keys), keys)
        expect_error(plot3D.graph(g, X = X, values = v), "match vertex IDs exactly")
        expect_error(plot3D.graph(g, X = X, groups = v), "match vertex IDs exactly")
        expect_error(plot3D.graph(g, X = X, col = stats::setNames(rep("red", length(keys)), keys)),
                     "match vertex IDs exactly")
    }
})

test_that("unweighted igraph input prepares without inventing a weight meaning", {
    skip_if_not_installed("igraph")
    ig <- igraph::make_ring(4)
    g <- prepare.graph(ig, weight.type = "unweighted")
    expect_equal(g$edges$weight, rep(1, 4))
    expect_error(prepare.graph(ig), "weight")
})
