# Developer benchmark, deliberately excluded from examples and CRAN checks.
library(ivue)
options(rgl.useNULL = TRUE)
dir.create("artifacts/benchmark", recursive = TRUE, showWarnings = FALSE)
invisible(plot3D.plain(matrix(1:9, 3))) # Warm backend initialization separately.
results <- list()
for (n in c(250L, 5000L, 25000L)) {
    set.seed(1200 + n)
    x <- runif(n, -1, 1); y <- runif(n, -1, 1)
    X <- cbind(x, y, z = 1.2 * (x^2 - y^2))
    graph <- list(vertices = as.character(seq_len(n)),
      edges = data.frame(from = seq_len(n - 1L), to = 2:n, weight = 1))
    for (family in c("points", "edges")) {
        build.seconds <- numeric(3)
        for (i in seq_along(build.seconds)) {
            gc()
            build.seconds[i] <- system.time(w <- if (family == "points") {
                plot3D.cont(X, X[, 3], point.size = 4)
            } else plot3D.graph(graph, X = X, point.size = 3))["elapsed"]
        }
        file <- file.path("artifacts/benchmark", paste0(family, "-", n, ".html"))
        save.seconds <- system.time(htmlwidgets::saveWidget(w, file, selfcontained = FALSE))["elapsed"]
        deps <- sub(".html$", "_files", file)
        dep.bytes <- sum(file.info(list.files(deps, recursive = TRUE, full.names = TRUE))$size)
        row <- data.frame(family = family, vertices = n,
            edges = if (family == "edges") n - 1L else 0L,
            build.median.seconds = median(build.seconds), save.seconds = unname(save.seconds),
            html.bytes = file.info(file)$size, dependency.bytes = dep.bytes,
            widget.bytes = as.numeric(object.size(w)))
        results[[length(results) + 1L]] <- row
        print(row)
    }
}
write.csv(do.call(rbind, results), "artifacts/benchmark/results.csv", row.names = FALSE)
writeLines(c(capture.output(sessionInfo()), "", "Three warm builds per scene; one external-asset HTML save."),
           "artifacts/benchmark/session.txt")
