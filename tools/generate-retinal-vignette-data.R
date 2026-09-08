#!/usr/bin/env Rscript

# Record the visualization-ready retinal case-study object bundled with ivue.

if (!file.exists("DESCRIPTION")) {
    stop("Run this script from the ivue repository root.")
}

artifact.dir <- file.path("artifacts", "retinal-readme")
layout.file <- Sys.getenv(
    "IVUE_RETINAL_LAYOUT",
    file.path(artifact.dir, "retinal-sknn-layout.rds")
)
if (!file.exists(layout.file)) {
    stop("Prepared retinal graph not found. Run 'make readme-retinal-layout'.")
}

retinal <- readRDS(layout.file)
needed <- c(
    "coordinates", "graph", "metadata", "k.selection", "input", "layout",
    "source.paths", "source.md5", "package.versions"
)
if (!all(needed %in% names(retinal))) {
    stop("The prepared retinal graph is missing required fields.")
}

metadata.file <- Sys.getenv(
    "IVUE_RETINAL_DATA", retinal$source.paths[["metadata"]]
)
if (!file.exists(metadata.file)) {
    stop("Retinal UMAP metadata not found: ", metadata.file)
}
source <- utils::read.csv(
    metadata.file, row.names = 1L, check.names = FALSE,
    stringsAsFactors = FALSE
)
umap.columns <- c("umap_coord1", "umap_coord2", "umap_coord3")
if (!all(umap.columns %in% names(source))) {
    stop("Retinal metadata does not contain the published 3D UMAP coordinates.")
}

sampled <- retinal$metadata
selected <- match(rownames(sampled), rownames(source))
if (anyNA(selected) || anyDuplicated(selected)) {
    stop("Prepared graph cells do not map uniquely to the UMAP metadata.")
}
if (!identical(source$age[selected], as.character(sampled$age)) ||
    !identical(source$umap2_CellType[selected], as.character(sampled$cell.type))) {
    stop("UMAP labels do not match the prepared graph sample.")
}

n <- nrow(sampled)
ids <- sprintf("cell-%05d", seq_len(n))
umap <- as.matrix(source[selected, umap.columns, drop = FALSE])
colnames(umap) <- c("x", "y", "z")
umap <- sweep(umap, 2L, colMeans(umap), "-")
rownames(umap) <- ids

sknn <- retinal$coordinates
colnames(sknn) <- c("x", "y", "z")
rownames(sknn) <- ids
edge.matrix <- retinal$graph$edge.matrix
edges <- data.frame(
    from = ids[edge.matrix[, 1L]],
    to = ids[edge.matrix[, 2L]],
    weight = retinal$graph$edge.weight,
    stringsAsFactors = FALSE
)
annotations <- data.frame(
    id = ids,
    age = sampled$age,
    cell.type = sampled$cell.type,
    stringsAsFactors = FALSE
)

case.study <- list(
    coordinates = list(umap = umap, sknn = sknn),
    graph = list(
        vertices = ids,
        edges = edges,
        directed = FALSE,
        weight.type = "distance"
    ),
    annotations = annotations,
    provenance = list(
        citation = paste(
            "Clark et al. (2019), Neuron 102:1111-1126.e5;",
            "doi:10.1016/j.neuron.2019.04.010; GEO GSE118614"
        ),
        sample = paste(
            "12,000 cells stratified by developmental stage and cell type;",
            "minimum 20 per nonempty stratum; seed 20190619"
        ),
        umap = paste(
            "Published three-dimensional UMAP coordinates for the matched",
            "retained cells; Canberra distance was used upstream"
        ),
        graph.input = retinal$input,
        graph.selection = retinal$k.selection,
        graph.layout = retinal$layout,
        source.md5 = retinal$source.md5,
        generator = "tools/generate-retinal-vignette-data.R",
        package.versions = retinal$package.versions
    )
)

if (any(grepl("barcode", names(case.study$annotations), ignore.case = TRUE)) ||
    any(grepl("/Users/|~", unlist(case.study$provenance)))) {
    stop("The public case-study object contains identifying or local-path fields.")
}

output <- file.path("inst", "extdata", "retinal-development.rds")
saveRDS(case.study, output, compress = "xz", version = 2L)
message("Wrote ", output, " (", format(file.info(output)$size, big.mark = ","),
        " bytes)")
