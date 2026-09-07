#!/usr/bin/env Rscript

# Reconstruct the data representation used for the published retinal UMAP,
# select a low-k symmetric kNN graph, and compute its 3D graph layout.

if (!file.exists("DESCRIPTION")) {
    stop("Run this script from the ivue repository root.")
}

required <- c("Matrix", "readxl", "irlba", "dgraphs", "grip")
missing <- required[!vapply(required, requireNamespace, logical(1L), quietly = TRUE)]
if (length(missing)) {
    stop("The retinal preparation requires: ", paste(missing, collapse = ", "))
}

out <- file.path("artifacts", "retinal-readme")
raw.dir <- file.path(out, "raw")
dir.create(raw.dir, recursive = TRUE, showWarnings = FALSE)

default.metadata <- path.expand(paste0(
    "~/current_projects/retinal_development/data/",
    "10x_Mouse_retina_pData_umap2_CellType_annot_w_horiz.csv"
))
default.high.variance <- path.expand(paste0(
    "~/current_projects/retinal_development/data/",
    "NIHMS1529461-supplement-7.xlsx"
))
paths <- c(
    counts = Sys.getenv(
        "IVUE_RETINAL_COUNTS",
        file.path(raw.dir, "GSE118614_10x_aggregate.mtx.gz")
    ),
    features = Sys.getenv(
        "IVUE_RETINAL_FEATURES",
        file.path(raw.dir, "GSE118614_genes.tsv.gz")
    ),
    cells = Sys.getenv(
        "IVUE_RETINAL_CELLS",
        file.path(raw.dir, "GSE118614_barcodes.tsv.gz")
    ),
    metadata = Sys.getenv("IVUE_RETINAL_DATA", default.metadata),
    high.variance = Sys.getenv("IVUE_RETINAL_HIGH_VARIANCE", default.high.variance)
)
missing.files <- names(paths)[!file.exists(paths)]
if (length(missing.files)) {
    stop(
        "Missing retinal source file(s): ", paste(missing.files, collapse = ", "),
        ". See man/figures/README.md for source links and path overrides."
    )
}

fingerprints <- unname(tools::md5sum(paths))
names(fingerprints) <- names(paths)
pca.file <- file.path(out, "retinal-umap-input-pc20.rds")
layout.file <- file.path(out, "retinal-sknn-layout.rds")

read.metadata <- function(path) {
    x <- utils::read.csv(path, row.names = 1L, check.names = FALSE,
                         stringsAsFactors = FALSE)
    needed <- c("barcode", "age", "Total_mRNAs", "umap2_CellType")
    if (!all(needed %in% names(x))) {
        stop("Retinal metadata is missing: ",
             paste(setdiff(needed, names(x)), collapse = ", "))
    }
    x
}

metadata <- read.metadata(paths[["metadata"]])
full.cells <- utils::read.delim(
    gzfile(paths[["cells"]]), row.names = 1L, check.names = FALSE,
    stringsAsFactors = FALSE
)
if (!all(c("barcode", "Total_mRNAs") %in% names(full.cells)) ||
    nrow(full.cells) != 120804L || anyDuplicated(rownames(full.cells))) {
    stop("The GEO cell table does not identify the expected 120,804 unique cells.")
}

cached.pca <- NULL
if (file.exists(pca.file)) {
    candidate <- readRDS(pca.file)
    if (identical(candidate$source.md5, fingerprints) &&
        identical(candidate$cells, rownames(full.cells))) {
        cached.pca <- candidate
        message("Using validated PC cache: ", pca.file)
    }
}

if (is.null(cached.pca)) {
    message("Reading the retinal count matrix...")
    counts.connection <- if (grepl("[.]gz$", paths[["counts"]])) {
        gzfile(paths[["counts"]])
    } else {
        paths[["counts"]]
    }
    counts <- methods::as(Matrix::readMM(counts.connection), "CsparseMatrix")
    features <- utils::read.delim(
        gzfile(paths[["features"]]), row.names = 1L, check.names = FALSE,
        stringsAsFactors = FALSE
    )
    high.variance <- readxl::read_excel(
        paths[["high.variance"]], sheet = 1L, skip = 1L
    )
    if (!"id" %in% names(features) || !"id" %in% names(high.variance)) {
        stop("Both feature sources must contain an 'id' column.")
    }
    if (nrow(counts) != nrow(full.cells) || ncol(counts) != nrow(features)) {
        stop("Count matrix dimensions do not match feature and cell metadata.")
    }
    totals <- Matrix::rowSums(counts)
    if (!identical(as.numeric(totals), as.numeric(full.cells$Total_mRNAs))) {
        stop("Count-matrix rows are not aligned with the GEO cell table.")
    }
    high.variance.index <- match(high.variance$id, features$id)
    if (anyNA(high.variance.index) || anyDuplicated(high.variance.index) ||
        length(high.variance.index) != 3290L) {
        stop("The published 3,290 high-variance genes do not match feature rows exactly.")
    }

    message("Computing log10(CPT + 1) for the 3,290 published genes...")
    expression <- counts[, high.variance.index, drop = FALSE]
    expression@x <- log10(
        expression@x * (10000 / totals)[expression@i + 1L] + 1
    )
    rownames(expression) <- rownames(full.cells)
    colnames(expression) <- high.variance$id

    message("Computing the first 20 centered, unscaled principal components...")
    set.seed(1L)
    pca <- irlba::prcomp_irlba(
        expression, n = 20L, center = TRUE, scale. = FALSE, retx = TRUE
    )
    rownames(pca$x) <- rownames(full.cells)
    cached.pca <- list(
        scores = pca$x,
        sdev = pca$sdev,
        cells = rownames(full.cells),
        feature.ids = high.variance$id,
        source.md5 = fingerprints,
        normalization = "log10(transcript copies per 10,000 + 1)",
        pca = paste(
            "20 components; centered; unscaled;",
            "irlba::prcomp_irlba; seed 1"
        )
    )
    saveRDS(cached.pca, pca.file, compress = "xz")
    message("Wrote ", pca.file)
    rm(counts, expression, features, high.variance, pca)
    invisible(gc())
}

if (!identical(rownames(cached.pca$scores), rownames(full.cells))) {
    stop("PC score rows are not aligned with the GEO cell table.")
}
retained.index <- match(rownames(metadata), cached.pca$cells)
if (anyNA(retained.index) || anyDuplicated(retained.index)) {
    stop("Retained retinal cells do not map uniquely into the full PCA population.")
}

age.levels <- c("E11", "E12", "E14", "E16", "E18",
                "P0", "P2", "P5", "P8", "P14")
cell.levels <- c(
    "Early RPCs", "Late RPCs", "Neurogenic Cells",
    "Retinal Ganglion Cells", "Amacrine Cells", "Horizontal Cells",
    "Photoreceptor Precursors", "Cones", "Rods", "Bipolar Cells",
    "Muller Glia"
)
if (!setequal(unique(metadata$age), age.levels) ||
    !setequal(unique(metadata$umap2_CellType), cell.levels)) {
    stop("Developmental-stage or cell-type labels differ from the expected data.")
}
metadata$age <- factor(metadata$age, levels = age.levels)
metadata$cell.type <- factor(metadata$umap2_CellType, levels = cell.levels)

allocate.stratified <- function(groups, target, minimum = 20L) {
    members <- split(seq_along(groups), groups, drop = TRUE)
    sizes <- vapply(members, length, integer(1L))
    allocation <- pmin(sizes, minimum)
    remaining <- target - sum(allocation)
    if (remaining < 0L) {
        stop("Sampling target is too small for the stratum minimum.")
    }
    capacity <- sizes - allocation
    if (remaining > 0L) {
        ideal <- remaining * capacity / sum(capacity)
        extra <- pmin(capacity, floor(ideal))
        allocation <- allocation + extra
        left <- target - sum(allocation)
        if (left > 0L) {
            eligible <- which(allocation < sizes)
            order.remainder <- eligible[order(
                ideal[eligible] - extra[eligible], decreasing = TRUE
            )]
            fill <- utils::head(order.remainder, left)
            allocation[fill] <- allocation[fill] + 1L
        }
    }
    allocation
}

sample.size <- 12000L
strata <- interaction(metadata$age, metadata$cell.type, drop = TRUE,
                      lex.order = TRUE)
members <- split(seq_len(nrow(metadata)), strata, drop = TRUE)
allocation <- allocate.stratified(strata, sample.size)
set.seed(20190619L)
selected <- unlist(
    Map(function(rows, n) rows[sample.int(length(rows), n)], members, allocation),
    use.names = FALSE
)
selected <- selected[sample(seq_along(selected))]
if (length(selected) != sample.size || anyDuplicated(selected)) {
    stop("Stratified sampling did not produce the requested unique cells.")
}
input <- cached.pca$scores[retained.index[selected], , drop = FALSE]

k.values <- 2:12
graphs <- vector("list", length(k.values))
diagnostics <- data.frame(
    k = integer(), components = integer(),
    largest.component.fraction = numeric(), edges = integer(),
    min.degree = integer()
)
message("Evaluating low-k symmetric kNN graphs...")
for (i in seq_along(k.values)) {
    graph <- dgraphs::create.sknn.graph(
        input, k = k.values[[i]], neighbor.method = "ann",
        connect.components = FALSE
    )
    component.sizes <- tabulate(graph$component_id_before)
    diagnostics <- rbind(diagnostics, data.frame(
        k = k.values[[i]],
        components = graph$n_components_before,
        largest.component.fraction = max(component.sizes) / sample.size,
        edges = graph$n_edges,
        min.degree = min(lengths(graph$adj_list))
    ))
    graphs[[i]] <- graph
    message(sprintf(
        "  k = %d: %d component(s), %.3f%% in the largest, %s edges",
        k.values[[i]], graph$n_components_before,
        100 * diagnostics$largest.component.fraction[[i]],
        format(graph$n_edges, big.mark = ",")
    ))
    if (i >= 3L && all(utils::tail(diagnostics$components, 3L) == 1L)) break
}

if (nrow(diagnostics) < 3L ||
    !all(utils::tail(diagnostics$components, 3L) == 1L)) {
    stop("No candidate k is connected for three consecutive values.")
}
selected.index <- nrow(diagnostics) - 2L
k.selected <- diagnostics$k[[selected.index]]
graph <- graphs[[selected.index]]
rm(graphs)
message("Selected k = ", k.selected,
        ": the smallest value connected for three consecutive candidates.")

layout.weights <- graph$edge_weight
positive <- layout.weights[layout.weights > 0]
if (!length(positive)) stop("The selected graph has no positive edge lengths.")
zero.edge.count <- sum(layout.weights == 0)
zero.edge.floor <- stats::median(positive) * 1e-6
layout.weights[layout.weights == 0] <- zero.edge.floor

message("Computing weighted-GRIP initialization and edge-KK refinement...")
fit <- grip::edge.kk(
    edges = graph$edge_matrix,
    n = sample.size,
    edge_weights = layout.weights,
    dim = 3L,
    init = "weighted_grip",
    weighted.grip.args = list(
        rounds = 100L,
        final_rounds = 240L,
        num_init = 24L,
        num_nbrs = 20L
    ),
    max_iter = 20L,
    density_mix_schedule = c(0, 0.5, 1),
    density_n = 512L,
    return_trace = FALSE,
    seed = 20190619L
)
coordinates <- sweep(fit$coords, 2L, colMeans(fit$coords), "-")
coordinates <- coordinates / max(sqrt(rowSums(coordinates^2)))
rownames(coordinates) <- rownames(metadata)[selected]

result <- list(
    coordinates = coordinates,
    graph = list(
        adj.list = graph$adj_list,
        weight.list = graph$weight_list,
        edge.matrix = graph$edge_matrix,
        edge.weight = graph$edge_weight
    ),
    metadata = metadata[selected, c("barcode", "age", "cell.type"), drop = FALSE],
    selected.rows = selected,
    k.selection = list(
        rule = paste(
            "smallest k whose native sKNN graph is connected for",
            "three consecutive candidate values"
        ),
        candidates = diagnostics,
        selected = k.selected
    ),
    input = list(
        representation = "first 20 PCs of log10(CPT + 1)",
        genes = length(cached.pca$feature.ids),
        distance = "Euclidean",
        cells = nrow(full.cells),
        retained.cells = nrow(metadata),
        sampled.cells = sample.size
    ),
    layout = list(
        method = "grip::edge.kk(init = 'weighted_grip')",
        zero.edge.count = zero.edge.count,
        zero.edge.floor = zero.edge.floor,
        final.edge.relative.rmse = utils::tail(
            fit$metadata$stage_summaries$final.edge.rel.rmse, 1L
        )
    ),
    source.paths = paths,
    source.md5 = fingerprints,
    package.versions = vapply(
        c("dgraphs", "grip"),
        function(package) as.character(utils::packageVersion(package)),
        character(1L)
    )
)
saveRDS(result, layout.file, compress = "xz")
utils::write.csv(diagnostics, file.path(out, "retinal-sknn-k-selection.csv"),
                 row.names = FALSE)
message("Wrote ", layout.file)
