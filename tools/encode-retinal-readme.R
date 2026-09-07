#!/usr/bin/env Rscript

if (!requireNamespace("magick", quietly = TRUE)) {
    stop("Package 'magick' is required to encode the README animation.")
}

out <- file.path("artifacts", "retinal-readme")
paths <- file.path(out, "frames", sprintf("frame-%03d.png", 0:71))
if (!all(file.exists(paths))) {
    stop("Retinal animation frames are missing. Run capture-retinal-readme.cjs --animation first.")
}

frames <- magick::image_read(paths)
frames <- magick::image_scale(frames, "960x")
frames <- magick::image_quantize(frames, max = 128L, colorspace = "sRGB",
                                 dither = TRUE)
animation <- magick::image_animate(frames, fps = 10L, loop = 0,
                                   optimize = TRUE)
gif <- file.path("man", "figures", "readme-retinal-development.gif")
magick::image_write(animation, gif)
message("Wrote ", gif, " (", format(file.info(gif)$size, big.mark = ","), " bytes)")
