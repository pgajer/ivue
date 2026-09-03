test_that("continuous scales are comparable, explicit, and NA safe", {
    sc <- color.scale.cont(c(0, 1))
    a <- map.colors(c(0, 0.5, 1, NA), sc)
    expect_length(unique(a$colors[1:3]), 3)
    expect_equal(a$colors[2], map.colors(0.5, sc)$colors)
    expect_equal(tail(a$legend$count, 1), 1)
    expect_equal(map.colors(c(-1, 2), sc)$colors, a$colors[c(1, 3)])
    expect_equal(map.colors(-1, color.scale.cont(0:1, oob = "censor"))$colors, "gray80")
    expect_error(map.colors(3, color.scale.cont(0:1, oob = "error")), "outside")
    expect_equal(length(unique(map.colors(rep(2, 3), color.scale.cont(rep(2, 3)))$colors)), 1)
    expect_equal(map.colors(c(NA_real_, NA_real_), color.scale.cont(NA_real_))$legend$count[6], 2)
    expect_error(color.scale.cont(c(1, Inf)), "infinity")
    expect_error(color.scale.cont(1:5, winsor.p = 0.1), "binned")
    expect_error(color.scale.cont(1:5, center = 2), "diverging")
    sc <- color.scale.cont(-3:2, center = 0, palette = c("blue", "white", "red"))
    expect_equal(sc$limits, c(-3, 3))
})

test_that("bins handle constants, ties, missing values, and label precision", {
    for (method in c("uniform", "quantile")) {
        sc <- color.scale.cont(rep(2, 4), mode = "binned", method = method)
        expect_true(all(diff(sc$breaks) > 0))
        expect_equal(sum(map.colors(rep(2, 4), sc)$legend$count), 4)
        empty <- color.scale.cont(NA_real_, mode = "binned", method = method)
        expect_equal(tail(map.colors(NA_real_, empty)$legend$count, 1), 1)
    }
    sc <- color.scale.cont(c(1, 1, 2, 2, 3), mode = "binned", method = "quantile", digits = 1)
    expect_warning(mapped <- map.colors(c(1, 1, 2, 2, 3), sc), "indistinguishable")
    expect_equal(sum(mapped$legend$count), 5)
    expect_error(color.scale.cont(1:3, mode = "binned", breaks = c(1, 1, 3)), "increasing")
    expect_error(color.scale.cont(1:3, mode = "binned", n.bins = NA), "n.bins")
    expect_error(color.scale.cont(1:3, mode = "binned", winsor.p = 0.5), "less")
    expect_equal(sum(map.colors(rep(2, 4), color.scale.cont(rep(2, 4),
        mode = "binned", limits = c(2, 2)))$legend$count), 4)
})

test_that("palette generators and value maps have distinct contracts", {
    expect_error(color.scale.cont(1:3, palette = function(n) "red"), "n colors")
    expect_error(color.scale.cont(1:3, palette = "red", color.map = function(x) "blue"), "not both")
    sc <- color.scale.cont(0:2, color.map = function(x) ifelse(x < 1, "red", "blue"))
    expect_equal(map.colors(c(0, 1), sc)$colors, c("red", "blue"))
    expect_error(map.colors(1:2, color.scale.cont(1:2, color.map = function(x) "red")), "one color")
})

test_that("group colors are deterministic, retain factor order and opacity", {
    groups <- factor(c("c", "a", NA), levels = c("b", "a", "c"))
    sc <- color.scale.groups(groups, colors = c(a = "#FF000080", b = "blue", c = "green"))
    m <- map.colors(groups, sc)
    expect_equal(m$legend$label, c("b", "a", "c", "Missing"))
    expect_equal(m$legend$count, c(0L, 1L, 1L, 1L))
    expect_equal(m$colors[2], "#FF000080")
    expect_error(map.colors("new", sc), "Unknown")
    expect_error(color.scale.groups(c("a", "b"), colors = c(a = "red")), "cover")
    expect_equal(map.colors(NA_character_, color.scale.groups(NA_character_))$colors, "gray80")
    set.seed(42)
    old <- .Random.seed
    a <- color.scale.groups(letters)
    expect_identical(.Random.seed, old)
    expect_identical(a, color.scale.groups(letters))
})

test_that("explicit binned settings reproduce the source saddle colors", {
    old <- readRDS(test_path("fixtures", "gflow-baseline.rds"))
    sc <- color.scale.cont(old$X[, 3], mode = "binned", n.bins = 10,
                           palette = function(n) grDevices::rainbow(n, start = 1/6, end = 0))
    expect_equal(map.colors(old$X[, 3], sc)$colors, old$continuous.colors)
    groups <- color.scale.groups(old$groups, old$group.colors)
    expect_equal(map.colors(old$groups, groups)$colors, unname(old$group.colors[old$groups]))
})
