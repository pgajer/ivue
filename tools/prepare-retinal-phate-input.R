#!/usr/bin/env Rscript

# Export the existing PC cache unchanged; never reconstruct or refit the PCs here.
out <- file.path("artifacts", "retinal-phate")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
pc.path <- file.path("artifacts", "retinal-readme", "retinal-umap-input-pc20.rds")
layout.path <- file.path("artifacts", "retinal-readme", "retinal-sknn-layout.rds")
pc <- readRDS(pc.path)
layout <- readRDS(layout.path)
X <- pc$scores
display.index <- match(rownames(layout$coordinates), rownames(X))
stopifnot(identical(dim(X), c(120804L, 20L)), all(is.finite(X)),
          identical(pc$cells, rownames(X)), !anyDuplicated(pc$cells),
          identical(pc$source.md5, layout$source.md5),
          length(display.index) == 12000L, !anyNA(display.index),
          !anyDuplicated(display.index),
          identical(rownames(layout$metadata), rownames(layout$coordinates)))
binary <- file.path(out, "pc20-float64.bin")
writeBin(as.double(X), binary, size = 8L, endian = "little")
roundtrip <- matrix(readBin(binary, "double", n = length(X), size = 8L,
                            endian = "little"), nrow = nrow(X))
stopifnot(identical(as.vector(roundtrip), as.vector(X)))
utils::write.csv(data.frame(row.zero = display.index - 1L,
                            id = rownames(layout$coordinates)),
                  file.path(out, "display-index.csv"), row.names = FALSE)
writeLines(rownames(X), file.path(out, "fitting-cell-ids.txt"))
jsonlite::write_json(list(
    rows = nrow(X), columns = ncol(X), dtype = "little-endian float64",
    order = "F", pc.cache.md5 = unname(tools::md5sum(pc.path)),
    binary.md5 = unname(tools::md5sum(binary)), source.md5 = pc$source.md5,
    normalization = pc$normalization, pca = pc$pca,
    display.rule = "Exact existing 12,000 cells in existing display order"
), file.path(out, "input.json"), pretty = TRUE, auto_unbox = TRUE)
message("Exported all 120,804 x 20 scores with an exact float64 round-trip check.")
