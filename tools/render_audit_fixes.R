# Developer fixtures for actual geometry opacity, separate from historical runs.
library(ivue)
out <- "artifacts/audit-fixes/opacity"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
X <- rbind(c(-1, 0, 0), c(1, 0, 0), c(0, 1, 0))
graph <- prepare.graph(data.frame(from = "a", to = "b", weight = 2),
                        vertices = c("a", "b", "isolate"))
for (family in c("plain", "sphere", "continuous", "groups", "graph", "edges", "path", "labels")) {
    for (alpha in c(0, 1)) {
        col <- if (alpha == 0) "#FF000000" else "#FF0000FF"
        w <- switch(family,
            plain = plot3D.plain(X, col = "red", alpha = alpha, point.size = 25),
            sphere = plot3D.plain(X, col = "red", alpha = alpha,
                                  point.type = "sphere", sphere.radius = 0.12),
            continuous = plot3D.cont(X, c(0, 1, NA), point.size = 25,
                scale = color.scale.cont(0:1, palette = col, na.color = col)),
            groups = plot3D.groups(X, c("a", "b", NA), point.size = 25,
                scale = color.scale.groups(c("a", "b"), c(a = col, b = col), na.color = col)),
            graph = plot3D.graph(graph, X = X, values = c(0, 1, NA), point.size = 25,
                edge.col = col, edge.width = 6,
                scale = color.scale.cont(0:1, palette = col, na.color = col)),
            edges = plot3D.plain(X, col = "transparent", layers = list(
                layer3D.edges(matrix(c(1, 2), 1), col = col, width = 6))),
            path = plot3D.plain(X, col = "transparent", layers = list(
                layer3D.path(1:3, col = col, width = 6))),
            labels = plot3D.plain(X, col = "transparent", layers = list(
                layer3D.labels(1:3, c("A", "B", "C"), col = col, cex = 2))))
        htmlwidgets::saveWidget(w, file.path(out, paste0(family, "-", alpha, ".html")),
                                selfcontained = FALSE)
    }
}
fixtures <- list(
    half = plot3D.plain(X, col = "red", alpha = 0.5, point.size = 25),
    highlight = plot3D.plain(X, col = "red", point.size = 25, highlight = 1,
                             non.highlight.style = list(col = "red", alpha = 0)),
    missing = plot3D.cont(X, c(0, 1, NA), point.size = 25,
                          scale = color.scale.cont(0:1, palette = "red", na.color = "transparent")))
for (name in names(fixtures)) htmlwidgets::saveWidget(fixtures[[name]],
    file.path(out, paste0(name, ".html")), selfcontained = FALSE)
writeLines(c(system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
             capture.output(sessionInfo())), file.path(out, "session.txt"))
