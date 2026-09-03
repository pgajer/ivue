# Runs the real installed gflowx pipeline on synthetic data only.
options(rgl.useNULL = TRUE)
library(ivue)
stopifnot(requireNamespace("gflowx", quietly = TRUE))
set.seed(812)
X <- matrix(rnorm(80 * 3), 80, 3)
y <- X[, 1]^2 - X[, 2]^2 + rnorm(80, sd = 0.1)
out <- "artifacts/downstream-pipeline"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
elapsed <- system.time(result <- gflowx::iknn.graph.response.pipeline(
    X, y, k.min = 6L, k.max = 8L, selected.k = 8L,
    build.args = list(method = "none", trim.disconnected = FALSE),
    grip.args = list(rounds = 20L, final_rounds = 20L, num_init = 3L, num_nbrs = 15L),
    fit.args = list(max.iterations = 2L, n.eigenpairs = 15L, verbose.level = 0L),
    cont.plot.args = list(point.type = "point", point.size = 5),
    out.dir = out, timestamp = "fixture", save.rds = FALSE, verbose = FALSE))["elapsed"]
stopifnot(length(result$html.objects) > 0L,
          all(vapply(result$html.objects, inherits, logical(1), "htmlwidget")),
          any(vapply(result$components, function(x) !is.null(x$fit), logical(1))))
html <- list.files(out, pattern = "[.]html$", full.names = TRUE)
stopifnot(length(html) > 0L, all(file.info(html)$size > 1000))
summary <- list(elapsed.seconds = unname(elapsed), files = html,
    rows = vapply(result$html.objects, function(w) length(attr(w, "ivue")$row.ids), integer(1)),
    versions = vapply(c("ivue", "gflowx", "gflow", "dgraphs", "grip"),
                      function(p) as.character(packageVersion(p)), character(1)))
dput(summary, file = file.path(out, "results.R"))
print(summary)
