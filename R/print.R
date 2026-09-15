#' Inspect Prepared Graphs and Color Scales
#'
#' Compact console summaries retain ordinary list access through `$`. Printing
#' does not load a graphics backend, evaluate a custom color function, or change
#' the object. Use `x$vertices`, `x$edges`, or `x$levels` for the full data.
#' @param x A prepared graph or color scale.
#' @param ... Reserved for compatibility with the print generic.
#' @return The original object, invisibly.
#' @seealso [prepare.graph()], [color.scale.cont()], [color.scale.groups()]
#' @export
print.ivue_graph <- function(x, ...) {
    n <- nrow(x$vertices)
    e <- x$edges
    used <- unique(c(e$from, e$to))
    cat(sprintf('<ivue_graph> %d vertices, %d edges, %d isolates; %s\n',
                n, nrow(e), n - length(used), if (x$directed) 'directed' else 'undirected'))
    cat('Weight meaning:', if (is.null(x$weight.type)) 'unspecified' else x$weight.type, '\n')
    weights <- e$weight[is.finite(e$weight)]
    cat('Finite weight range:', if (length(weights)) paste(format(range(weights), digits=5), collapse=' to ') else 'none', '\n')
    cat('Vertex IDs (row order):', .print.preview(x$vertices$id), '\n')
    cat('Edges (vertex row indices):', if (nrow(e)) .print.preview(paste(e$from, e$to, sep=' -> ')) else 'none', '\n')
    cat('Full tables: $vertices and $edges; weights do not set drawing styles.\n')
    invisible(x)
}

#' @rdname print.ivue_graph
#' @export
print.ivue_color_scale <- function(x, ...) {
    cat('<ivue_color_scale>', if (x$type == 'groups') 'categorical' else x$mode, '\n')
    if (x$type == 'groups') {
        cat('Levels:', length(x$levels), ';', .print.preview(x$levels), '\n')
        cat('Unknown groups:', x$unknown, '\n')
    } else {
        cat('Limits:', paste(format(x$limits, digits=5), collapse=' to '), '\n')
        if (!is.null(x$center)) cat('Center:', format(x$center, digits=5), '\n')
        if (x$mode == 'binned') cat('Bins:', length(x$breaks)-1L, '\n')
        cat('Out of bounds:', x$oob, '\n')
    }
    cat('Missing color:', x$na.color, '\n')
    cat('Palette:', if (!is.null(x$color.map)) 'custom pointwise function (not evaluated)' else .print.preview(x$colors), '\n')
    invisible(x)
}

.print.preview <- function(x) {
    if (!length(x)) return('none')
    # Bound both the number and width of arbitrary user-provided labels.
    items <- encodeString(substr(as.character(utils::head(x, 3L)), 1L, 24L), quote='"')
    paste0(paste(items, collapse=', '), if (length(x)>3L) ', ...' else '')
}
