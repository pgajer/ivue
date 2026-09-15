# Small, ivue-only interactive qualification app; no sibling checkout required.
library(shiny)
library(ivue)
X <- rbind(a=c(-1,-1,0), b=c(1,-1,0), c=c(0,1,1))
ui <- fluidPage(
    titlePanel('ivue controls in Shiny'),
    numericInput('revision', 'Scene revision', 1, min=1),
    textInput('outside', 'Unrelated input'),
    rgl::rglwidgetOutput('scene', height='350px'),
    rgl::rglwidgetOutput('reference', height='350px'),
    uiOutput('animation'),
    verbatimTextOutput('status'))
server <- function(input, output, session) {
    output$scene <- rgl::renderRglwidget({
        revision <- input$revision
        plot3D.groups(X / revision, c(a='A',b='B',c='C'),
            description=paste('Reactive triangle, revision', revision), height=350)
    })
    output$reference <- rgl::renderRglwidget(plot3D.plain(X,
        description='Independent reference triangle', height=350))
    # renderUI preserves all companion HTML widgets and captions.
    output$animation <- renderUI({
        revision <- input$revision
        animate.frames(list(X*.5, X), labels=c('Half size','Full size'),
            description=paste('Reactive animation, revision', revision),
            caption='Positions change; the same observations remain.', height=350)
    })
    output$status <- renderText(paste('Revision', input$revision))
}
shinyApp(ui, server, options=list(port=as.integer(Sys.getenv('IVUE_SMOKE_PORT','4873')),
    host='127.0.0.1', launch.browser=FALSE))
