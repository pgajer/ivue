.view.controls <- function(w, description, controls, aspect, X) {
    w$dependencies <- c(w$dependencies, list(htmltools::htmlDependency(
        'ivue-view', '0.1.0', src = c(file = system.file('www', package='ivue')),
        script='view.js', stylesheet='view.css')))
    # Descriptions remain readable without JavaScript, alongside document posters.
    in.shiny <- isNamespaceLoaded("shiny") && !is.null(shiny::getDefaultReactiveDomain())
    if (!in.shiny) w <- htmlwidgets::appendContent(w, htmltools::tags$p(class='ivue-description', description,
        htmltools::tags$noscript(' Interactive controls require JavaScript and WebGL; use the static figures and captions in the guides.')))
    htmlwidgets::onRender(w, 'function(el, x, data) { window.ivueView(el, data); }',
        data=list(description=description, controls=controls, aspect=aspect,
                  shinyDescription=in.shiny,
                  observationBounds=as.vector(apply(X,2,range))))
}
