library(ivue)

stopifnot(!"rgl" %in% loadedNamespaces())
sc <- color.scale.cont(c(-1, 0, 1), palette = c("blue", "red"))
mapped <- map.colors(c(-1, 0, 1, NA), sc)
stopifnot(length(mapped$colors) == 4L, tail(mapped$colors, 1) == "gray80")
groups <- color.scale.groups(c("a", "b"), c(a = "red", b = "blue"))
stopifnot(identical(map.colors(c("b", "a"), groups)$colors, c("blue", "red")))
stopifnot(inherits(layer3D.path(1:3), "ivue_layer"))
stopifnot(inherits(layer3D.axes(), "ivue_layer"),
          identical(dim(camera.zup()$userMatrix), c(4L, 4L)),
          camera.zup()$fov == 0)
graph <- prepare.graph(data.frame(from = "a", to = "b"),
                        vertices = c("a", "b", "isolate"), weight.type = "unweighted")
stopifnot(nrow(graph$vertices) == 3L, graph$edges$weight == 1,
          !"igraph" %in% loadedNamespaces())
stopifnot(!"rgl" %in% loadedNamespaces())

if (!nzchar(system.file(package = "rgl"))) {
    failure <- tryCatch(plot3D.plain(matrix(1:9, 3)), error = identity)
    stopifnot(inherits(failure, "error"),
              grepl("install.packages('rgl')", conditionMessage(failure), fixed = TRUE))
}
