test_that("point and graph views give named annotations the same colors by ID", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- rbind(a = c(0, 0, 0), b = c(1, 1, 1), c = c(2, 0, 0))
    graph <- prepare.graph(data.frame(from = "a", to = "b", weight = 1),
                           vertices = c("b", "c", "a"))
    by.id <- function(w) {
        info <- attr(w, "ivue")
        stats::setNames(info$colors, info$observation.ids)[rownames(X)]
    }
    values <- c(c = 10, b = 5, a = 0)
    for (scale in list(NULL, color.scale.cont(c(0, 10)))) {
        point <- plot3D.cont(X, values, scale = scale)
        network <- plot3D.graph(graph, X = X, values = values, scale = scale)
        expect_identical(by.id(point), by.id(network))
        expect_identical(unname(by.id(point)), map.colors(c(0, 5, 10),
            if (is.null(scale)) color.scale.cont(values) else scale)$colors)
    }
    # Three distinct groups expose accidental palette fitting in coordinate order.
    groups <- c(c = "high", a = "low", b = "middle")
    factor.groups <- factor(groups, levels = c("middle", "high", "low", "unused"))
    names(factor.groups) <- names(groups)
    for (annotation in list(groups, factor.groups, c(c = "high", a = NA, b = "low"))) {
        for (scale in list(NULL, color.scale.groups(annotation))) {
            point <- plot3D.groups(X, annotation, scale = scale)
            network <- plot3D.graph(graph, X = X, groups = annotation, scale = scale)
            expect_identical(by.id(point), by.id(network))
            expect_identical(attr(point, "ivue")$mapping$legend,
                             attr(network, "ivue")$mapping$legend)
        }
    }
    plain <- c(c = "red", a = "blue", b = "green")
    expect_identical(by.id(plot3D.plain(X, col = plain)),
                     by.id(plot3D.graph(graph, X = X, col = plain)))
    expect_identical(unname(by.id(plot3D.plain(X, col = plain))), c("blue", "green", "red"))
})

test_that("point styles align by ID while coordinates and indexed layers keep their order", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- rbind(a = c(0, 0, 0), b = c(1, 1, 1), c = c(2, 0, 0))
    captured <- NULL
    w <- plot3D.cont(X, c(c = 10, a = 0, b = 5),
        highlight = c(c = TRUE, a = TRUE, b = FALSE),
        highlight.style = list(col = c(c = "red", a = "blue", b = "black")),
        non.highlight.style = list(col = c(c = "black", a = "black", b = "green")),
        layers = list(layer3D.path(c(1, 3)), layer3D.labels(2, "b"),
                      layer3D.callback(function(ctx) captured <<- ctx)))
    info <- attr(w, "ivue")
    expect_identical(info$X, X)
    expect_identical(info$row.ids, 1:3)
    expect_identical(info$observation.ids, c("a", "b", "c"))
    expect_identical(unname(info$highlight), c(TRUE, FALSE, TRUE))
    expect_identical(captured$observation.ids, info$observation.ids)
    expect_identical(captured$X[c(1, 3), ], X[c(1, 3), ])
    rgb <- t(vapply(seq_len(nrow(X)), function(i) {
        draw <- info$draw.ids[i, ]
        info$scene$objects[[as.character(draw$object)]]$colors[draw$index, 1:3]
    }, numeric(3)))
    expect_equal(unname(rgb), rbind(c(0, 0, 1), c(0, 1, 0), c(1, 0, 0)))
    # Numeric highlight indices remain positional even if the vector has names.
    indexed <- plot3D.plain(X, highlight = c(c = 1L))
    expect_identical(attr(indexed, "ivue")$highlight, c(TRUE, FALSE, FALSE))
})

test_that("ambiguous point IDs and named annotations fail before rendering", {
    X <- rbind(a = c(0, 0, 0), b = c(1, 1, 1), c = c(2, 0, 0))
    for (keys in list(c("a", "a", "c"), c("a", "b", "extra"),
                      c("a", "b", ""), c("a", "b", NA), c("a", "b"),
                      c("a", "b", "c", "extra"), "a")) {
        numeric <- stats::setNames(seq_along(keys), keys)
        colors <- stats::setNames(rep("red", length(keys)), keys)
        mask <- stats::setNames(rep(TRUE, length(keys)), keys)
        expect_error(plot3D.cont(X, numeric), "match observation IDs exactly")
        expect_error(plot3D.groups(X, colors), "match observation IDs exactly")
        expect_error(plot3D.plain(X, col = colors), "match observation IDs exactly")
        expect_error(plot3D.plain(X, highlight = mask), "match observation IDs exactly")
        expect_error(plot3D.plain(X, highlight.style = list(col = colors)),
                     "match observation IDs exactly")
        expect_error(plot3D.plain(X, non.highlight.style = list(col = colors)),
                     "match observation IDs exactly")
    }
    for (keys in list(c("a", "a", "c"), c("a", "", "c"), c("a", NA, "c"))) {
        bad <- X; rownames(bad) <- keys
        expect_error(plot3D.plain(bad), "unique, nonempty, nonmissing observation IDs")
    }
    unnamed <- unname(X)
    automatic <- as.data.frame(unnamed)
    for (coords in list(unnamed, automatic)) {
        expect_error(plot3D.cont(coords, c(a = 1, b = 2, c = 3)), "explicit observation IDs")
        expect_error(plot3D.groups(coords, c(a = "x", b = "y", c = "z")), "explicit observation IDs")
        expect_error(plot3D.plain(coords, col = c(a = "red", b = "blue", c = "green")),
                     "explicit observation IDs")
    }
})

test_that("unnamed annotations stay positional and explicit data-frame IDs are respected", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- rbind(a = c(0, 0, 0), b = c(1, 1, 1), c = c(2, 0, 0))
    values <- c(c = 10, b = 5, a = NA)
    sc <- color.scale.cont(values)
    positional <- plot3D.cont(X, unname(values), scale = sc)
    expect_identical(attr(positional, "ivue")$colors, map.colors(unname(values), sc)$colors)
    expect_identical(attr(plot3D.cont(as.data.frame(X), values), "ivue")$colors,
                     attr(plot3D.cont(X, values), "ivue")$colors)
    automatic <- plot3D.plain(as.data.frame(unname(X)), col = "red", highlight = 2)
    expect_null(attr(automatic, "ivue")$observation.ids)
    expect_identical(attr(automatic, "ivue")$row.ids, 1:3)
    expect_identical(attr(automatic, "ivue")$highlight, c(FALSE, TRUE, FALSE))
    one <- X["a", , drop = FALSE]
    expect_identical(unname(attr(plot3D.plain(one, col = c(a = "red")), "ivue")$colors), "red")
})
