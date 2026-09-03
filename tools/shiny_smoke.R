# Run against installed ivue and gflowui; this is a rendering integration harness.
stopifnot(requireNamespace("ivue", quietly = TRUE),
          requireNamespace("gflowui", quietly = TRUE),
          requireNamespace("shiny", quietly = TRUE))
options(rgl.useNULL = TRUE)
set.seed(1)
xs <- runif(250, -1, 1)
ys <- runif(250, -1, 1)
X <- cbind(xs, ys, 1.2 * (xs^2 - ys^2))
ui <- shiny::fluidPage(
  shiny::selectInput("family", "Color", c("plain", "numeric", "groups")),
  shiny::selectInput("primitive", "Primitive", c("point", "sphere")),
  shiny::checkboxInput("overlay", "Basin overlay", TRUE),
  rgl::rglwidgetOutput("scene", width = "100%", height = "600px"),
  shiny::verbatimTextOutput("status"))
server <- function(input, output, session) {
  widget <- shiny::reactive({
    specs <- if (isTRUE(input$overlay)) list(list(
      fun = function(ctx) {
        gflowui:::gflowui_draw_rgl_basin_layers(ctx$X, list(list(
          kind = "minimum_halo", key = "min|fixture", name = "Selected minima",
          vertices = c(2L, 4L), color = "#2563EB", rgl.size = 12, rgl.opacity = 0.5)))
      }, with_ctx = TRUE)) else list()
    args <- list(X = X, point.type = input$primitive, point.size = 6,
                 sphere.radius = 0.025, layers = gflowui:::gflowui_ivue_layers(specs))
    if (input$family == "numeric") {
      encoded <- gflowui:::gflowui_ivue_numeric(X[, 3], list(label = "Saddle height"))
      args$values <- encoded$values
      args$scale <- encoded$scale
      do.call(ivue::plot3D.cont, args)
    } else if (input$family == "groups") {
      args$groups <- ifelse(X[, 3] >= 0, "Nonnegative", "Negative")
      args$scale <- ivue::color.scale.groups(args$groups,
        c(Negative = "#D95479BB", Nonnegative = "#009F87CC"))
      do.call(ivue::plot3D.groups, args)
    } else do.call(ivue::plot3D.plain, args)
  })
  output$scene <- rgl::renderRglwidget(widget())
  output$status <- shiny::renderText({
    info <- attr(widget(), "ivue")
    jsonlite::toJSON(list(family = input$family, primitive = input$primitive,
      overlay = input$overlay, rows = length(info$row.ids),
      colors = length(unique(info$colors)),
      identities = identical(info$draw.ids$row, seq_len(nrow(X)))), auto_unbox = TRUE)
  })
}
shiny::runApp(shiny::shinyApp(ui, server), host = "127.0.0.1",
              port = as.integer(Sys.getenv("IVUE_SMOKE_PORT", "4873")), launch.browser = FALSE)
