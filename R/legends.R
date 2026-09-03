.css.color <- function(col) {
    rgba <- grDevices::col2rgb(col, alpha = TRUE)
    sprintf("rgba(%d,%d,%d,%.4f)", rgba[1, ], rgba[2, ], rgba[3, ], rgba[4, ] / 255)
}

.legend <- function(widget, mapping, title, position, font.size, width, alpha = 1) {
    data <- mapping$legend
    items <- lapply(seq_len(nrow(data)), function(i) {
        label <- data$label[i]
        if (!is.na(data$count[i])) label <- sprintf("%s (%d)", label, data$count[i])
        htmltools::tags$div(style = "display:flex;gap:6px;align-items:center;margin:2px 0;",
            htmltools::tags$span(style = paste0("flex:0 0 12px;height:12px;border:1px solid #777;background:",
                                                .css.color(.with.alpha(data$color[i], alpha)), ";")),
            htmltools::tags$span(style = "overflow-wrap:anywhere;min-width:0;", label))
    })
    ramp <- NULL
    if (mapping$scale$type == "continuous" && mapping$scale$mode == "continuous") {
        sc <- mapping$scale
        cols <- .continuous.colors(.scale.sequence(sc$limits, 33L), sc)
        ramp <- htmltools::tags$div(style = paste0("height:12px;margin:4px 0;background:linear-gradient(to right,",
                    paste(.css.color(.with.alpha(cols, alpha)), collapse = ","), ");"))
    }
    box <- htmltools::tags$div(class = "ivue-legend",
        style = paste0("position:absolute;top:8px;", position, ":8px;z-index:5;",
            "max-width:calc(100% - 32px);width:", width, "px;max-height:40%;overflow:auto;",
            "box-sizing:border-box;padding:8px;background:rgba(255,255,255,.92);",
            "border:1px solid #bbb;border-radius:4px;font-family:sans-serif;",
            "font-size:", font.size, "px;color:#222;"),
        htmltools::tags$strong(style = "overflow-wrap:anywhere;", title), ramp, items)
    # Render hooks also work in Shiny, where prepended widget content is ignored.
    htmlwidgets::onRender(widget, "function(el, x, data) {
      var container = document.createElement('div');
      container.innerHTML = data.legend;
      el.style.position = 'relative';
      el.appendChild(container.firstElementChild);
    }", data = list(legend = as.character(box)))
}
