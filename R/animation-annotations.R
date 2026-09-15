# Text is measured on the actual raster device. Split even an unbroken ID;
# reject layouts that cannot retain legible text and a useful scene area.
.animation.wrap <- function(text, pixels) {
    measure <- function(x) graphics::strwidth(x, units = "inches") * 96
    unlist(lapply(strsplit(text, "\n", fixed = TRUE)[[1]], function(paragraph) {
        if (!nzchar(paragraph)) return("")
        chars <- strsplit(paragraph, "", fixed = TRUE)[[1]]
        lines <- character()
        while (length(chars)) {
            widths <- measure(vapply(seq_along(chars), function(j)
                paste(chars[seq_len(j)], collapse = ""), ""))
            fit <- which(widths <= pixels)
            if (!length(fit)) .stop("GIF annotations do not fit; increase width or height.")
            n <- max(fit)
            if (n < length(chars)) {
                spaces <- which(chars[seq_len(n)] == " ")
                if (length(spaces)) n <- max(spaces)
            }
            lines <- c(lines, trimws(paste(chars[seq_len(n)], collapse = "")))
            chars <- chars[-seq_len(n)]
        }
        lines
    }), use.names = FALSE)
}

.animation.layout <- function(info, width, height, labels, annotations) {
    line <- graphics::strheight("Mg", units = "inches") * 96 * 1.6
    legend <- if (annotations) info$mapping else NULL
    side <- if (is.null(legend)) 0 else min(260, floor(width * .42))
    caption <- if (annotations && !is.null(info$caption))
        .animation.wrap(info$caption, width - 24) else character()
    footer <- if (length(caption)) length(caption) * line + 20 else 0
    label.lines <- if (labels) lapply(info$labels, .animation.wrap, pixels=width-side-16) else list()
    header <- if (labels) max(lengths(label.lines)) * line + 16 else 0
    if (width - side < 64 || height - footer - header < 64)
        .stop("GIF annotations or frame labels do not fit; increase width or height, or disable labels/annotations.")
    title <- rows <- character()
    ramp <- 0
    if (!is.null(legend)) {
        title <- .animation.wrap(if (is.null(info$legend.title)) "Color" else info$legend.title, side - 24)
        data <- legend$legend
        texts <- ifelse(is.na(data$count), data$label, sprintf("%s (%d)", data$label, data$count))
        rows <- lapply(texts, .animation.wrap, pixels=side-46)
        ramp <- if (legend$scale$type == "continuous" && legend$scale$mode == "continuous") 22 else 0
        needed <- 24 + length(title)*line + ramp + sum(lengths(rows)*line + 8)
        if (needed > height - footer)
            .stop("GIF legend does not fit; increase width or height, or use annotations = FALSE.")
    }
    list(scene=c(0, (width-side)/width, footer/height, (height-header)/height),
         side=side, footer=footer, line=line, caption=caption, labels=label.lines,
         title=title, rows=rows, ramp=ramp)
}

.animation.annotations <- function(info, layout, width, height) {
    graphics::par(fig=c(0, 1, 0, 1), mar=rep(0, 4), xaxs="i", yaxs="i")
    graphics::plot.new(); graphics::plot.window(c(0, width), c(0, height))
    draw.lines <- function(lines, x, y) {
        for (label in lines) {
            graphics::text(x, y, label, adj=c(0, 1), col="#222222")
            y <- y-layout$line
        }
        y
    }
    if (length(layout$caption)) {
        graphics::rect(0, 0, width, layout$footer, col="white", border=NA)
        draw.lines(layout$caption, 12, layout$footer-10)
    }
    if (layout$side) {
        left <- width-layout$side
        graphics::rect(left, layout$footer, width, height, col="white", border=NA)
        y <- draw.lines(layout$title, left+12, height-12)-8
        if (layout$ramp) {
            scale <- info$mapping$scale
            cols <- .continuous.colors(.scale.sequence(scale$limits, 64L), scale)
            xs <- seq(left+12, width-12, length.out=65)
            graphics::rect(xs[-65], y-12, xs[-1], y, col=cols, border=NA)
            y <- y-layout$ramp
        }
        for (j in seq_along(layout$rows)) {
            graphics::rect(left+12, y-10, left+22, y,
                           col=info$mapping$legend$color[j], border="#777777")
            y <- draw.lines(layout$rows[[j]], left+30, y)-8
        }
    }
    invisible(NULL)
}
