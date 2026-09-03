library(ivue)
dir.create("artifacts", showWarnings = FALSE)
set.seed(1)
xs <- runif(250, -1, 1)
ys <- runif(250, -1, 1)
zs <- 1.2 * (xs^2 - ys^2)
X <- cbind(x = xs, y = ys, z = zs)
sc <- color.scale.cont(zs, center = 0, palette = c("#2166AC", "#F7F7F7", "#B2182B"))
path <- order(xs)[seq(1L, 250L, length.out = 20L)]
edges <- data.frame(from = as.character(head(path, -1)), to = as.character(tail(path, -1)),
                    weight = rep(1, length(path) - 1L))
widgets <- list(
  saddle = plot3D.cont(X, zs, scale = sc, point.size = 6, axes = TRUE,
                      xlab = "x", ylab = "y", zlab = "z", legend.title = "Saddle height"),
  plain = plot3D.plain(X, point.type = "sphere", sphere.radius = 0.025, col = "#197A68", axes = TRUE),
  groups = plot3D.groups(X, factor(ifelse(zs >= 0, "Nonnegative", "Negative")),
                        point.size = 6, axes = TRUE),
  graph = plot3D.graph(edges, vertices = seq_len(nrow(X)), X = X, values = zs,
                       scale = sc, point.size = 5, axes = TRUE,
                       edge.col = "#333333", edge.width = 2,
                       layers = list(layer3D.path(path[1:5], col = "#E69F00", width = 5),
                                     layer3D.labels(path[c(1, 5)], c("Start", "End"))))
)
for (name in names(widgets)) {
  htmlwidgets::saveWidget(widgets[[name]], file.path("artifacts", paste0(name, ".html")),
                          selfcontained = FALSE, libdir = "lib")
}
htmltools::save_html(htmltools::tagList(widgets$saddle, widgets$groups),
                    "artifacts/multiple.html", libdir = "lib")
if (rmarkdown::pandoc_available()) {
  htmlwidgets::saveWidget(widgets$saddle, "artifacts/saddle-selfcontained.html", selfcontained = TRUE)
}
cat("Created saddle, plain, groups, and graph browser examples in artifacts/.\n")
