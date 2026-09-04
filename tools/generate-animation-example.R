#!/usr/bin/env Rscript
# Run from the ivue repository. An optional grip source checkout records its
# commit and uses that checkout instead of an installed grip package.
args <- commandArgs(trailingOnly = TRUE)
source.commit <- NA_character_
if (length(args)) {
    source.root <- normalizePath(args[1], mustWork = TRUE)
    changed <- system2("git", c("-C", shQuote(source.root), "status", "--porcelain", "--", "R", "src"), stdout = TRUE)
    if (length(changed)) stop("The grip R/ and src/ trees must be clean for the example record.")
    source.commit <- system2("git", c("-C", shQuote(source.root), "rev-parse", "HEAD"), stdout = TRUE)
    pkgload::load_all(source.root, quiet = TRUE, export_all = FALSE)
}
if (!requireNamespace("grip", quietly = TRUE)) stop("Install grip or supply its source checkout.")
edges <- grip::edges.sierpinski.triangle(level = 4)
trace <- grip::trace.grip(edges, n = max(edges), dim = 2, preset = "carpet",
                           trace = "round", trace.every = 1, seed = 1)
index <- unique(as.integer(round(seq(1, length(trace$frames), length.out = min(40, length(trace$frames))))))
example <- list(edges = edges, frames = trace$frames[index], meta = trace$meta[index, , drop = FALSE],
    original.frame.index = index, original.frame.count = length(trace$frames),
    provenance = list(package = "grip", version = as.character(utils::packageVersion("grip")),
        commit = source.commit, generator = "tools/generate-animation-example.R",
        graph = "edges.sierpinski.triangle(level = 4)", seed = 1L,
        preset = "carpet", dimension = 2L, trace = "round", trace.every = 1L,
        coordinate.processing = "None; recorded frames are stored without alignment or normalization."))
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
saveRDS(example, "inst/extdata/sierpinski-trace.rds", compress = "xz", version = 2)
print(example$provenance)
cat(length(example$frames), "frames;", nrow(example$frames[[1]]), "vertices\n")
