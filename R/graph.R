#' Draw a Weighted Embedded Graph
#'
#' Graph input is normalized independently of the rendering engine. Supplied
#' coordinates never trigger layout computation or igraph construction.
#'
#' @param graph A named list with adj.list and weight.list (neighbors are row
#'   indices); a list with edges and vertices; a weighted data frame with from,
#'   to, weight columns plus the vertices argument; a numerical square adjacency
#'   matrix; a Matrix sparse adjacency matrix; or an igraph object. Matrices use
#'   zero for absent edges; use lists/tables to represent zero-weight edges.
#' @param X Finite n-by-3 coordinates. Unnamed rows follow vertex order; named
#'   rows must match vertex IDs exactly and are aligned to graph vertex order.
#' @param layout NULL when X is supplied, otherwise "fr", "kk", or a function
#'   of the normalized graph returning n-by-3 coordinates. Supply exactly one
#'   of X and layout. Custom functions receive vertices (id plus attributes),
#'   edges (integer from/to indices, weight, attributes), directed, weight.type.
#' @param vertices Explicit vertex IDs or a data frame with a unique id column.
#'   Required for edge-table input, including isolated vertices. Adjacency lists
#'   default to list names, or character row numbers when unnamed.
#' @param directed Logical directedness; NULL uses stored directedness or FALSE.
#'   This release rejects directed rendering, self-loops, and parallel edges.
#'   Undirected adjacency lists must be reciprocal with equal weights.
#' @param weight.type "distance", "strength", or "unweighted". Required for
#'   weighted layout algorithms but not supplied-coordinate drawing. The fr
#'   algorithm requires strengths; kk requires distances. No inversion occurs.
#'   Unweighted mode only accepts missing or unit weights.
#' @param seed Seed used locally for layout computation, without changing the
#'   caller's random-number state.
#' @param edge.col,edge.width Explicit visual attributes, scalar or one per
#'   normalized edge. They are not automatically inferred from weights.
#' @param values,groups Optional vertex coloring, in graph vertex order. Supply
#'   at most one; color scales and legends use the corresponding point family.
#' @param layers Additional layer3D specifications.
#' @param ... Named controls for the selected point family. Legacy graph-layout
#'   and basin arguments are not supported.
#' @return A widget with normalized graph data in attr(widget, "ivue")$graph.
#' @details Only fr and kk need igraph. Negative and zero finite weights can be
#'   stored/drawn, but these layout algorithms require positive weights.
#'   Explicit sparse zeros are rejected because zero-edge semantics would be
#'   ambiguous. Duplicate/asymmetric adjacency entries are rejected, not averaged.
#'   igraph vertex names supply canonical IDs; a pre-existing id attribute is
#'   retained as .igraph.id (an existing .igraph.id attribute is a conflict).
#' @seealso [plot3D.plain()], [layer3D.edges()]
#' @export
#' @examples
#' g <- list(adj.list = list(2L, c(1L, 3L), 2L, integer()),
#'           weight.list = list(2, c(2, 4), 4, numeric()))
#' X <- rbind(c(0, 0, 0), c(1, 1, 0), c(2, 0, 1), c(0, 2, 1))
#' if (nzchar(system.file(package = "rgl"))) w <- plot3D.graph(g, X = X)
plot3D.graph <- function(graph, X = NULL, layout = NULL, vertices = NULL,
                         directed = NULL, weight.type = NULL, seed = 1L,
                         edge.col = "gray65", edge.width = 1,
                         values = NULL, groups = NULL, layers = list(), ...) {
    if (is.null(X) == is.null(layout)) .stop("Supply exactly one of X and layout.")
    g <- .normalize.graph(graph, vertices, directed, weight.type)
    if (g$directed) .stop("Directed graph rendering is not yet supported; do not silently discard directions.")
    if (is.null(X)) {
        X <- if (is.function(layout)) .with.seed(seed, layout(g)) else
            .compute.igraph.layout(g, layout, seed = seed)
    }
    X <- .align.coordinates(X, g$vertices$id)
    if (!is.null(values) && !is.null(groups)) .stop("Supply values or groups, not both.")
    if (!is.list(layers) || inherits(layers, "ivue_layer")) .stop("layers must be a list.")
    edge.matrix <- matrix(as.integer(as.matrix(g$edges[c("from", "to")])), ncol = 2L)
    edge.layer <- layer3D.edges(edge.matrix, edge.col, edge.width)
    dots <- list(...)
    fun <- if (!is.null(values)) plot3D.cont else if (!is.null(groups)) plot3D.cltrs else plot3D.plain
    allowed <- setdiff(union(names(formals(fun)), names(formals(plot3D.plain))),
                       c("X", "values", "groups", "layers", "..."))
    if (!identical(fun, plot3D.plain)) allowed <- setdiff(allowed, "col")
    .named.list(dots, allowed, "graph scene controls")
    args <- c(list(X = X, layers = c(list(edge.layer), layers)), dots)
    if (!is.null(values)) args$values <- values
    if (!is.null(groups)) args$groups <- groups
    w <- do.call(fun, args)
    attr(w, "ivue")$graph <- g
    w
}

.vertex.table <- function(vertices) {
    if (!is.data.frame(vertices)) vertices <- data.frame(id = as.character(vertices))
    if (anyDuplicated(names(vertices))) .stop("Vertex table column names must be unique.")
    if (!"id" %in% names(vertices)) .stop("vertices must have an id column.")
    vertices$id <- as.character(vertices$id)
    if (!nrow(vertices) || anyNA(vertices$id) || any(!nzchar(vertices$id)) || anyDuplicated(vertices$id))
        .stop("Vertex IDs must be nonempty, unique, and nonmissing; at least one vertex is required.")
    rownames(vertices) <- NULL
    vertices
}

.normalize.graph <- function(graph, vertices = NULL, directed = NULL, weight.type = NULL) {
    if (inherits(graph, "ivue_graph")) {
        if (!is.null(vertices) || !is.null(directed) || !is.null(weight.type))
            .stop("Do not override an already normalized graph.")
        return(graph)
    }
    if (!is.null(weight.type)) weight.type <- match.arg(weight.type, c("distance", "strength", "unweighted"))
    if (inherits(graph, "igraph")) {
        if (!requireNamespace("igraph", quietly = TRUE)) .stop("igraph is required for igraph input.")
        if (!is.null(vertices)) .stop("igraph already supplies its vertex set.")
        stored.directed <- igraph::is_directed(graph)
        if (!is.null(directed) && !identical(directed, stored.directed)) .stop("Conflicting directedness.")
        directed <- stored.directed
        v <- igraph::as_data_frame(graph, what = "vertices")
        ids <- if ("name" %in% names(v)) as.character(v$name) else as.character(seq_len(igraph::vcount(graph)))
        if ("id" %in% names(v)) {
            if (".igraph.id" %in% names(v)) .stop("Rename the conflicting igraph .igraph.id attribute.")
            names(v)[names(v) == "id"] <- ".igraph.id"
        }
        v$id <- ids
        e <- igraph::as_data_frame(graph, what = "edges")
        graph <- list(vertices = v, edges = e)
    }
    if (is.matrix(graph) || inherits(graph, "sparseMatrix")) {
        if (nrow(graph) != ncol(graph)) .stop("Adjacency matrices must be square.")
        ids <- rownames(graph)
        if (is.null(ids)) ids <- if (is.null(vertices)) as.character(seq_len(nrow(graph))) else
            .vertex.table(vertices)$id
        if (!is.null(colnames(graph))) {
            if (anyDuplicated(colnames(graph)) || !setequal(colnames(graph), ids))
                .stop("Matrix row and column IDs must match uniquely.")
            graph <- graph[, match(ids, colnames(graph)), drop = FALSE]
        }
        if (is.null(vertices)) vertices <- ids
        v <- .vertex.table(vertices)
        if (nrow(v) != nrow(graph)) .stop("Matrix dimensions must match the vertex count.")
        if (!identical(v$id, ids)) .stop("Matrix vertex IDs must match its row order.")
        if (inherits(graph, "sparseMatrix")) {
            if (!requireNamespace("Matrix", quietly = TRUE)) .stop("Matrix is required for sparse input.")
            trip <- Matrix::summary(methods::as(graph, "generalMatrix"))
            if (!"x" %in% names(trip) || !is.numeric(trip$x)) .stop("Sparse weights must be numeric.")
            if (any(trip$x == 0, na.rm = TRUE)) .stop("Explicit sparse zeros are ambiguous; use an edge table for zero-weight edges.")
            ii <- trip$i; jj <- trip$j; ww <- trip$x
        } else {
            if (!is.numeric(graph) || any(!is.finite(graph))) .stop("Matrix weights must be finite numeric values.")
            idx <- which(graph != 0, arr.ind = TRUE)
            ii <- idx[, 1]; jj <- idx[, 2]; ww <- graph[idx]
        }
        rows <- factor(ii, levels = seq_len(nrow(v)))
        a <- unname(split(jj, rows))
        w <- unname(split(ww, rows))
        graph <- list(adj.list = a, weight.list = w, vertices = v)
        vertices <- NULL
    }
    if (is.data.frame(graph)) graph <- list(edges = graph)
    if (!is.list(graph)) .stop("Unsupported graph format.")
    if (!is.null(vertices) && !is.null(graph$vertices)) .stop("Vertex set supplied twice.")
    if (is.null(vertices)) vertices <- graph$vertices
    if (!is.null(graph$directed)) {
        if (!is.null(directed) && !identical(directed, graph$directed)) .stop("Conflicting directedness.")
        directed <- graph$directed
    }
    if (is.null(directed)) directed <- FALSE
    .flag(directed, "directed")
    if (!is.null(graph$weight.type)) {
        if (!is.null(weight.type) && !identical(weight.type, graph$weight.type)) .stop("Conflicting weight.type.")
        weight.type <- match.arg(graph$weight.type, c("distance", "strength", "unweighted"))
    }
    adjacency <- !is.null(graph$adj.list)
    if (adjacency && !is.null(graph$edges)) .stop("Supply adjacency lists or edges, not both.")
    if (adjacency) {
        a <- graph$adj.list
        w <- graph$weight.list
        if (!is.list(a)) .stop("adj.list must be a list.")
        if (is.null(vertices)) vertices <- if (!is.null(names(a))) names(a) else as.character(seq_along(a))
        v <- .vertex.table(vertices)
        if (length(a) != nrow(v)) .stop("Adjacency length must match the vertex set.")
        if (!is.null(names(a)) && !identical(names(a), v$id)) .stop("Named adjacency lists must follow vertex order.")
        if (is.null(w) && identical(weight.type, "unweighted")) w <- lapply(a, function(x) rep(1, length(x)))
        if (!is.list(w) || length(w) != length(a)) .stop("weight.list must align with adj.list.")
        if (!is.null(names(w)) && !identical(names(w), v$id))
            .stop("Named weight lists must follow vertex order.")
        for (i in seq_along(a)) {
            .indices(a[[i]], nrow(v), "adj.list")
            if (anyDuplicated(a[[i]])) .stop("Duplicate adjacency entries are not supported.")
            if (!is.numeric(w[[i]]) || length(w[[i]]) != length(a[[i]]) || any(!is.finite(w[[i]])))
                .stop("Every weight list must align with finite numeric neighbor weights.")
        }
        e <- data.frame(from = rep(seq_along(a), lengths(a)),
                        to = as.integer(unlist(a, use.names = FALSE)),
                        weight = as.numeric(unlist(w, use.names = FALSE)))
        if (!directed && nrow(e)) {
            reverse <- match(paste(e$to, e$from, sep = ":"), paste(e$from, e$to, sep = ":"))
            if (anyNA(reverse) || any(e$weight != e$weight[reverse]))
                .stop("Undirected adjacency must be reciprocal with equal weights.")
            e <- e[e$from <= e$to, , drop = FALSE]
        }
    } else {
        if (is.null(vertices)) .stop("Edge-table graphs require an explicit vertex set, including isolates.")
        v <- .vertex.table(vertices)
        e <- graph$edges
        if (!is.data.frame(e) || !all(c("from", "to") %in% names(e)))
            .stop("edges must be a data frame with from, to, and weight columns.")
        if (anyDuplicated(names(e))) .stop("Edge table column names must be unique.")
        e$from <- match(as.character(e$from), v$id)
        e$to <- match(as.character(e$to), v$id)
        if (anyNA(e$from) || anyNA(e$to)) .stop("Edge endpoints must match vertex IDs.")
        if (is.null(e$weight) && identical(weight.type, "unweighted")) e$weight <- rep(1, nrow(e))
    }
    if (!is.numeric(e$weight) || length(e$weight) != nrow(e) || any(!is.finite(e$weight)))
        .stop("Edges require finite numeric weights, or explicit unweighted mode.")
    if (identical(weight.type, "unweighted") && any(e$weight != 1))
        .stop("Unweighted mode cannot discard non-unit weights.")
    if (any(e$from == e$to)) .stop("Self-loops are not supported.")
    keys <- if (directed) paste(e$from, e$to, sep = ":") else
        paste(pmin(e$from, e$to), pmax(e$from, e$to), sep = ":")
    if (anyDuplicated(keys)) .stop("Parallel edges are not supported; aggregate them explicitly if appropriate.")
    rownames(e) <- NULL
    structure(list(vertices = v, edges = e, directed = directed, weight.type = weight.type), class = "ivue_graph")
}

.align.coordinates <- function(X, ids) {
    if (is.data.frame(X) && .row_names_info(X, 1L) < 0L) {
        X <- .coordinates(X)
        rownames(X) <- NULL
    }
    X <- .coordinates(X)
    if (nrow(X) != length(ids)) .stop("Coordinate rows must match the vertex count.")
    if (!is.null(rownames(X))) {
        if (anyDuplicated(rownames(X)) || !setequal(rownames(X), ids))
            .stop("Coordinate row names must match vertex IDs exactly.")
        X <- X[match(ids, rownames(X)), , drop = FALSE]
    }
    rownames(X) <- ids
    X
}

.with.seed <- function(seed, expr) {
    .scalar(seed, "seed", 0, .Machine$integer.max, TRUE)
    had.seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had.seed) previous <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
        if (had.seed) assign(".Random.seed", previous, envir = .GlobalEnv)
        else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
            rm(".Random.seed", envir = .GlobalEnv)
    }, add = TRUE)
    set.seed(seed)
    force(expr)
}

.compute.igraph.layout <- function(graph, algorithm = c("fr", "kk"),
                                   vertices = NULL, directed = NULL,
                                   weight.type = NULL, dim = 3L, seed = 1L) {
    g <- .normalize.graph(graph, vertices, directed, weight.type)
    algorithm <- match.arg(algorithm)
    if (!(length(dim) == 1L && is.numeric(dim) && !is.na(dim) && dim %in% c(2L, 3L)))
        .stop("Layout dimension must be 2 or 3.")
    if (g$directed) .stop("Directed layouts are not supported by this adapter.")
    if (is.null(g$weight.type)) .stop("Declare weight.type before computing a layout.")
    expected <- if (algorithm == "fr") "strength" else "distance"
    if (!g$weight.type %in% c(expected, "unweighted"))
        .stop(algorithm, " requires weight.type = '", expected, "'; weights are not automatically inverted.")
    if (any(g$edges$weight <= 0)) .stop("Layout weights must be positive.")
    if (!requireNamespace("igraph", quietly = TRUE)) .stop("Install igraph to compute this layout.")
    n <- nrow(g$vertices)
    if (n == 1L) return(matrix(0, 1L, dim, dimnames = list(g$vertices$id, NULL)))
    .with.seed(seed, {
        ig <- igraph::make_empty_graph(n, directed = FALSE)
        if (nrow(g$edges)) ig <- igraph::add_edges(ig, as.vector(t(as.matrix(g$edges[c("from", "to")]))))
        fun <- if (algorithm == "fr") igraph::layout_with_fr else igraph::layout_with_kk
        X <- fun(ig, dim = dim, weights = g$edges$weight)
        if (!is.matrix(X) || !identical(dim(X), c(n, as.integer(dim))) || any(!is.finite(X)))
            .stop("Layout algorithm returned invalid coordinates.")
        rownames(X) <- g$vertices$id
        X
    })
}
