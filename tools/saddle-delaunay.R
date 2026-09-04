# Run after creating X: one row per observation, with columns x, y, z.
# geometry is an add-on package, not part of base R:
# install.packages("geometry")
# During local ivue development, first use pkgload::load_all("~/current_projects/ivue").

# Triangulate the ORIGINAL two-dimensional parameter coordinates, once.
triangles <- geometry::delaunayn(X[, c("x", "y")])
surface <- ivue::layer3D.mesh(
  triangles, col = "gray75", alpha = 0.2,
  edge.col = "gray45", edge.alpha = 0.35, edge.width = 1
)
byr.scale <- ivue::color.scale.cont(
  X[, "z"], palette = c("blue", "yellow", "red"), center = 0
)

saddle.mesh <- ivue::plot3D.cont(
  X, values = X[, "z"], scale = byr.scale,
  point.type = "sphere", sphere.radius = 0.02,
  axes = FALSE, aspect = "equal",
  layers = list(surface, ivue::layer3D.axes()),
  camera = ivue::camera.zup(elevation = 20, turn = -135, zoom = 0.4),
  legend.title = "Original saddle height", legend.width = 160,
  width = 700L, height = 500L
)
saddle.mesh

# For the single-saddle experiment, reuse the SAME triangle indices and colors:
# k <- 10
# Z <- mds[[as.character(k)]]       # Or: mds.edge.kk[[as.character(k)]]
# ivue::plot3D.cont(
#   Z, values = X[, "z"], scale = byr.scale,
#   point.type = "sphere", sphere.radius = 0.02,
#   axes = FALSE, aspect = "equal",
#   layers = list(surface, ivue::layer3D.axes()),
#   camera = ivue::camera.zup(), width = 700L, height = 500L
# )
# Vertex identities and row order must match X. Do not retriangulate Z.
# This mesh is a display overlay, not the symmetric-kNN fitting/scoring graph.
