scene.alpha <- function(widget, type, red.only = FALSE) {
    objects <- Filter(function(x) x$type == type, attr(widget, "ivue")$scene$objects)
    if (red.only) objects <- Filter(function(x) all(x$colors[, 1] == 1 &
        x$colors[, 2] == 0 & x$colors[, 3] == 0), objects)
    unlist(lapply(objects, function(x) x$colors[, 4]), use.names = FALSE)
}

test_that("actual point and sphere materials carry opacity in every family", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- rbind(c(-1, 0, 0), c(1, 0, 0), c(0, 1, 0))
    for (type in c("point", "sphere")) {
        object.type <- if (type == "point") "points" else "spheres"
        plain <- plot3D.plain(X, col = "#FF000080", alpha = 0.5, point.type = type)
        expect_equal(scene.alpha(plain, object.type), rep(128/255 * 0.5, 3), tolerance = 1e-7)
        cont <- plot3D.cont(X, c(0, 1, NA), alpha = 0, point.type = type)
        expect_equal(scene.alpha(cont, object.type), rep(0, 3))
        groups <- plot3D.groups(X, c("a", "b", NA), alpha = 0, point.type = type)
        expect_equal(scene.alpha(groups, object.type), rep(0, 3))
        graph <- list(vertices = letters[1:3],
                      edges = data.frame(from = "a", to = "b", weight = 1))
        w <- plot3D.graph(graph, X = X, values = c(0, 1, NA), alpha = 0, point.type = type)
        expect_equal(scene.alpha(w, object.type), rep(0, 3))
    }
    sc <- color.scale.cont(0:1, palette = "#FF000080", na.color = "transparent")
    expect_equal(scene.alpha(plot3D.cont(X, c(0, 1, NA), scale = sc), "points"),
                 c(128/255, 128/255, 0), tolerance = 1e-7)
    sc <- color.scale.groups(c("a", "b"), colors = c(a = "#FF000080", b = "blue"),
                             na.color = "transparent")
    expect_equal(scene.alpha(plot3D.groups(X, c("a", "b", NA), scale = sc), "points"),
                 c(128/255, 1, 0), tolerance = 1e-7)
})

test_that("highlight style overrides retain their defined precedence", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- matrix(1:9, 3)
    w <- plot3D.plain(X, highlight = 1)
    expect_equal(scene.alpha(w, "points"), c(0.4, 0.4, 1))
    w <- plot3D.plain(X, alpha = 0.8, highlight = 1,
        highlight.style = list(col = "#FF000080", alpha = 0.5),
        non.highlight.style = list(col = "blue", alpha = 0.2))
    expect_equal(scene.alpha(w, "points"), c(0.2, 0.2, 128/255 * 0.5), tolerance = 1e-7)
})

test_that("edge endpoint and label materials retain per-item alpha", {
    skip_if(!nzchar(system.file(package = "rgl")), "Rendering tests require rgl")
    X <- matrix(1:12, 4)
    cols <- c("#FF000000", "#FF000080", "#FF0000FF")
    w <- plot3D.plain(X, layers = list(
        layer3D.edges(cbind(1:3, 2:4), col = cols, width = c(1, 2, 1)),
        layer3D.labels(1:3, letters[1:3], col = cols)))
    expect_equal(sort(scene.alpha(w, "lines", TRUE)), sort(rep(c(0, 128/255, 1), each = 2)),
                 tolerance = 1e-7)
    expect_equal(scene.alpha(w, "text", TRUE), c(0, 128/255, 1), tolerance = 1e-7)
    w <- plot3D.plain(X, layers = list(layer3D.path(1:4, col = cols)))
    expect_equal(scene.alpha(w, "lines", TRUE), rep(c(0, 128/255, 1), each = 2), tolerance = 1e-7)
})

test_that("fitted numeric colors and missing colors do not follow palette changes", {
    old <- grDevices::palette()
    on.exit(grDevices::palette(old))
    grDevices::palette(c("black", "red", "green", "blue"))
    scales <- list(
        color.scale.groups(c("a", "b"), c(a = 2, b = 4), na.color = 3),
        color.scale.cont(0:1, palette = 2, na.color = 3),
        color.scale.cont(0:1, palette = c(2, 4), na.color = 3),
        color.scale.cont(0:1, palette = function(n) rep(2:4, length.out = n), na.color = 3),
        color.scale.cont(0:1, mode = "binned", palette = 2, na.color = 3))
    inputs <- list(c("a", "b", NA), c(0, 1, NA), c(0, 1, NA), c(0, 1, NA), c(0, 1, NA))
    before <- Map(map.colors, inputs, scales)
    grDevices::palette(c("black", "yellow", "pink", "cyan"))
    expect_identical(Map(map.colors, inputs, scales), before)
    expect_identical(names(scales[[1]]$colors), c("a", "b"))
    expect_identical(unname(scales[[1]]$colors), c("#FF0000FF", "#0000FFFF"))
})

test_that("empty labels and explicit NA factor levels preserve group identity", {
    g <- factor(c("a", NA, "NA"), levels = c("a", NA, "NA"), exclude = NULL)
    sc <- color.scale.groups(g)
    expect_identical(sc$levels, c("a", "NA"))
    m <- map.colors(g, sc)
    expect_identical(m$colors[2], "gray80")
    expect_equal(m$legend$count, c(1L, 1L, 1L))
    expect_identical(m$legend$label, c("a", "NA", "Missing"))
    expect_length(map.colors(factor("a", levels = c("a", NA), exclude = NULL), sc)$colors, 1)
    g <- c("", "a", "NA", "Missing", NA)
    cols <- stats::setNames(c("red", "blue", "green", "black"), g[1:4])
    sc <- color.scale.groups(g, cols)
    m <- map.colors(g, sc)
    expect_identical(m$colors, c("red", "blue", "green", "black", "gray80"))
    expect_identical(m$legend$label, c('\"\"', '\"a\"', '\"NA\"', '\"Missing\"', "Missing"))
    expect_false(anyDuplicated(m$legend$label) > 0L)
    expect_length(map.colors(c("", "a"), color.scale.groups(c("", "a")))$colors, 2)
})

test_that("automatic precision separates nearby boundaries while manual digits warn", {
    v <- seq(1, 1.0001, length.out = 20)
    for (mode in c("continuous", "binned")) {
        m <- map.colors(v, color.scale.cont(v, mode = mode))
        expect_false(anyDuplicated(m$legend$label) > 0L)
        expect_false(any(grepl("[1, 1]", m$legend$label, fixed = TRUE)))
        expect_warning(map.colors(v, color.scale.cont(v, mode = mode, digits = 3)),
                       "indistinguishable")
    }
    expect_error(color.scale.cont(v, digits = 0), "digits")
    expect_silent(map.colors(1, color.scale.cont(1)))
})

test_that("finite extreme scales normalize without overflow", {
    v <- c(-1e308, 0, 1e308)
    for (sc in list(color.scale.cont(v),
                   color.scale.cont(v, center = 0, palette = c("blue", "white", "red")),
                   color.scale.cont(v, mode = "binned"))) {
        m <- map.colors(v, sc)
        expect_false(anyNA(m$colors))
        expect_equal(length(unique(m$colors)), 3)
        expect_false(anyNA(m$legend$color))
    }
    for (value in c(-.Machine$double.xmax, .Machine$double.xmax, 1e-300, 0)) {
        for (method in c("uniform", "quantile")) {
            sc <- color.scale.cont(value, mode = "binned", method = method)
            expect_true(all(is.finite(sc$breaks)))
            expect_true(all(diff(sc$breaks) > 0))
            expect_false(anyNA(map.colors(value, sc)$colors))
        }
    }
    expect_error(color.scale.cont(c(-1e308, 1e308), center = 1e308,
                                  palette = c("blue", "red")), "finite numeric range")
    expect_error(color.scale.cont(.Machine$double.xmax, center = .Machine$double.xmax,
                                  palette = c("blue", "red")), "finite numeric range")
})

test_that("explicit breaks cannot replace incompatible constant limits", {
    expect_error(color.scale.cont(100, mode = "binned", limits = c(100, 100), breaks = 0:1),
                 "agree")
    expect_error(color.scale.cont(100, mode = "binned", limits = c(100, 100), breaks = c(99, 101)),
                 "agree")
    sc <- color.scale.cont(100, mode = "binned", limits = c(100, 100))
    expect_equal(sum(map.colors(100, sc)$legend$count), 1)
    expect_equal(color.scale.cont(100, mode = "binned", breaks = 0:1)$limits, c(0, 1))
})
