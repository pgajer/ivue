# Source Provenance

The initial implementation adapts the visualization behavior of Pawel Gajer's
gflow package, under GPL (>= 3), at commit
`86faf94b7a7e5cf462382a18dc8f35491647acdc`.

| Source in gflow | Destination in ivue | Treatment |
| --- | --- | --- |
| R/plot_utils.R: plot3D.plain.widget, plot3D.cont.widget, plot3D.cltrs.widget | R/plot3D.R, R/scene.R, R/legends.R | Shared lifecycle and new canonical API; no aliases copied |
| R/plot_utils.R: .run_plot3d_html_layers, label.end.pts, plot3D.tree, plot3D.path | R/layers.R | Explicit layer specifications and validated row identities |
| R/stats_utils.R: quantize.cont.var; R/plot_utils.R: quantize.for.legend | R/colors.R | Redesigned continuous/binned scales and reusable mapping |
| R/graphics.R: plot3D.graph, .compute.igraph.layout | R/graph.R | Redesigned weighted input normalization and optional layout adapter |

Implementations were reorganized and rewritten against documented contracts;
legacy function bodies and aliases are not bundled as a second implementation.
gflow's inst/COPYRIGHTS lists Eigen, Spectra, ANN, and Qhull. None of those
vendored libraries or their source files are imported into ivue. Optional
igraph and required rgl remain separately installed dependencies.

Baseline consumers inspected: gflowui at
`474218781e63095a8ac1e508b269b4bd7ae42003` and gflowx at
`549029ff8074dcce359fa7a959596c49409f3c2b`.
