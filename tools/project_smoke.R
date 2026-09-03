# A real gflowui project with synthetic data and an isolated temporary registry.
options(rgl.useNULL = TRUE)
root <- tempfile("ivue-project-")
dir.create(file.path(root, "results"), recursive = TRUE)
options(gflowui.projects_data_dir = file.path(root, "registry"))
set.seed(44)
x <- runif(80, -1, 1); y <- runif(80, -1, 1)
X <- cbind(x, y, 1.2 * (x^2 - y^2))
g <- dgraphs::build.iknn.graphs.and.selectk(X, kmin = 6L, kmax = 8L,
    method = "none", trim.disconnected = FALSE, verbose = FALSE)
graph.file <- file.path(root, "results", "graphs.rds")
layout.file <- file.path(root, "results", "layout_k8.rds")
saveRDS(g, graph.file)
saveRDS(X, layout.file)
spec <- gflowui::build_project_spec_iknn_3x3(
    project_root = root,
    graph_sets = list(list(id = "saddle", label = "Saddle sample",
      graph_file = graph.file, k_values = 6:8, selected_k = 8L,
      layout_assets = list(grip_layouts = list(list(k = 8L, path = layout.file)),
        presets = list(renderer = "rglwidget", vertex_layout = "point")))),
    defaults = list(graph_set_id = "saddle", reference_graph_set_id = "saddle", reference_k = 8L))
gflowui::register_project(root, project_id = "ivue_saddle", project_name = "ivue Saddle QA",
    profile = "iknn_3x3", project_spec = spec, scan_results = FALSE, overwrite = TRUE)
tryCatch(gflowui::run_gflowui(host = "127.0.0.1",
    port = as.integer(Sys.getenv("IVUE_PROJECT_PORT", "4874")), launch.browser = FALSE),
    finally = unlink(root, recursive = TRUE))
