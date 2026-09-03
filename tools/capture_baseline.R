args <- commandArgs(trailingOnly = TRUE)
source.root <- if (length(args)) path.expand(args[1L]) else path.expand("~/current_projects/gflow")
options(rgl.useNULL = TRUE)
functions <- c("plot3D.plain.widget", "plot3D.cont.widget", "plot3D.cltrs.widget",
               ".run_plot3d_html_layers", "label.end.pts", "quantize.cont.var")
source.commit <- "86faf94b7a7e5cf462382a18dc8f35491647acdc"
env <- new.env(parent = globalenv())
for (file in c("R/plot_utils.R", "R/stats_utils.R")) {
    source <- system2("git", c("-C", shQuote(source.root), "show",
                               paste0(source.commit, ":", file)), stdout = TRUE)
    for (expr in parse(text = source)) {
        if (is.call(expr) && identical(expr[[1L]], as.name("<-")) &&
            is.symbol(expr[[2L]]) && as.character(expr[[2L]]) %in% functions) eval(expr, env)
    }
}
stopifnot(all(vapply(functions, exists, logical(1), envir = env, inherits = FALSE)))
set.seed(1)
xs <- runif(250, -1, 1)
ys <- runif(250, -1, 1)
X <- cbind(x = xs, y = ys, z = 1.2 * (xs^2 - ys^2))
plain <- env$plot3D.plain.widget(X, post.layers = function(ctx) env$plain.context <- ctx)
cont <- env$plot3D.cont.widget(X, X[, 3], quantize.wins.p = 0,
                              post.layers = function(ctx) env$cont.context <- ctx)
groups <- ifelse(X[, 3] >= 0, "positive", "negative")
group.colors <- c(positive = "red", negative = "blue")
cltrs <- env$plot3D.cltrs.widget(X, groups, cltr.col.tbl = group.colors,
                                show.cltr.labels = FALSE,
                                post.layers = function(ctx) env$group.context <- ctx)
out <- list(source.commit = source.commit,
            X = X, groups = groups, group.colors = group.colors,
            plain.context.names = names(env$plain.context),
            continuous.colors = attr(cont, "y.cols"),
            continuous.table = attr(cont, "y.col.tbl"),
            continuous.counts = as.integer(table(env$cont.context$y.cols)),
            group.table = attr(cltrs, "cltr.col.tbl"),
            group.context.names = names(env$group.context))
dir.create("tests/testthat/fixtures", recursive = TRUE, showWarnings = FALSE)
saveRDS(out, "tests/testthat/fixtures/gflow-baseline.rds", version = 2)
cat("Captured source baseline for", nrow(X), "saddle points.\n")
