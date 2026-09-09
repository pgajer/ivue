# ivue 0.1.0

Initial release.

- **3D visualization:** `plot3D.plain()`, `plot3D.cont()`,
  `plot3D.groups()`, and `plot3D.graph()` display point clouds and embedded
  weighted graphs with numerical or categorical colors and highlighting.
  Browser widgets use `rgl` without requiring a native graphics window.

- **Geometric layers:** edges, paths, labels, triangular meshes, gridded
  reference surfaces, and origin-crossing coordinate axes can be combined
  with plotted observations.

- **Consistent views:** reusable continuous and categorical color scales
  provide matching legends. Plots default to an orthographic z-up camera;
  `camera.zup()` and explicit camera settings support reproducible views.

- **Animation and sharing:** `animate.frames()` plays recorded 2D or 3D
  coordinates with timeline and speed controls. Widgets can be saved as
  interactive HTML, and `write.animation.gif()` exports orthographic
  animations through the optional `magick` package.

- **Graph inputs:** `prepare.graph()` accepts edge tables, paired adjacency
  and weight lists, dense or sparse adjacency matrices, and igraph objects.
  Vertex-ID matching keeps coordinates and annotations aligned. Supplied
  layouts can be displayed directly; optional igraph layouts use explicit
  distance or strength weight semantics.

- **Documentation:** three vignettes introduce point-cloud and graph plotting,
  develop a retinal-development case study, and demonstrate coordinate
  animation and export.
