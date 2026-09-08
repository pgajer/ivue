#!/usr/bin/env Rscript

if (!requireNamespace("magick", quietly = TRUE)) {
    stop("Package 'magick' is required to encode the README animation.")
}

args <- commandArgs(trailingOnly = TRUE)
view.arg <- grep("^--view=", args, value = TRUE)
if (length(view.arg) != 1L) {
    stop("Supply exactly one of --view=sknn, --view=umap, or --view=comparison.")
}
view <- sub("^--view=", "", view.arg)
if (!view %in% c("sknn", "umap", "comparison")) {
    stop("Unknown retinal view: ", view)
}

out <- file.path("artifacts", "retinal-readme")
paths <- file.path(out, paste0("frames-", view),
                   sprintf("frame-%03d.png", 0:71))
if (!all(file.exists(paths))) {
    stop("Retinal ", view, " animation frames are missing.")
}

frames <- magick::image_read(paths)
frames <- magick::image_scale(frames, "960x")
frames <- magick::image_quantize(frames, max = 128L, colorspace = "sRGB",
                                 dither = TRUE)
# Hold the same comparison frames longer without adding image data.
fps <- if (view == "comparison") 5L else 10L
animation <- magick::image_animate(frames, fps = fps, loop = 0,
                                   optimize = TRUE)
gif <- file.path("man", "figures", paste0("readme-retinal-", view, ".gif"))
magick::image_write(animation, gif)
message("Wrote ", gif, " (", format(file.info(gif)$size, big.mark = ","), " bytes)")
