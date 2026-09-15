# Build a small static site from the same archive distributed for installation.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, file.exists(args[1]))
archive <- normalizePath(args[1])
local({
    stage <- tempfile("ivue-site-")
    dir.create(stage)
    on.exit(unlink(stage, recursive = TRUE))
    utils::untar(archive, exdir = stage)
    pkg <- file.path(stage, "ivue")
    version <- read.dcf(file.path(pkg, "DESCRIPTION"))[1, "Version"]
    output <- file.path("build", "site")
    unlink(output, recursive = TRUE)
    dir.create(output, recursive = TRUE)
    dir.create(file.path(output, "html"))
    dir.create(file.path(output, "doc"))
    files <- list.files(file.path(pkg, "inst", "doc"), full.names = TRUE)
    stopifnot(all(file.copy(files, file.path(output, "doc"), recursive = TRUE)))
    # A file-only guide index replaces R's help-server navigation in hosted HTML.
    guides <- c("function-guide" = "Finding your way around ivue",
                "example-data" = "Example data and reusable recipes",
                "ivue-introduction" = "Point clouds and weighted graphs",
                "retinal-development" = "Retinal development",
                "animation" = "Coordinate animations and export")
    guide.links <- paste(sprintf('<li><a href="%s.html">%s</a></li>', names(guides), guides), collapse = "\n")
    writeLines(paste0('<!doctype html><html lang="en"><meta charset="utf-8"><title>ivue guides</title>',
                     '<h1>ivue guides</h1><ul>', guide.links, '</ul><a href="../">Home</a></html>'),
               file.path(output, "doc", "index.html"))
    docs <- lapply(list.files(file.path(pkg, "man"), "[.]Rd$", full.names = TRUE), tools::parse_Rd)
    field <- function(doc, tag) unlist(lapply(Filter(function(x) identical(attr(x, "Rd_tag"), tag), doc), as.character))
    links <- unlist(lapply(docs, function(doc) stats::setNames(
        rep(paste0(field(doc, "\\name"), ".html"), length(field(doc, "\\alias"))), field(doc, "\\alias"))))
    for (doc in docs) tools::Rd2HTML(doc, package = "ivue", Links = links, texmath = "none",
        out = file.path(output, "html", paste0(field(doc, "\\name"), ".html")))
    file.copy(file.path(R.home("doc"), "html", "R.css"), file.path(output, "html", "R.css"))
    file.copy(file.path(R.home("doc"), "html", "Rlogo.svg"), file.path(output, "html", "Rlogo.svg"))
    reference.links <- paste(vapply(docs, function(doc) sprintf('<li><a href="%s.html">%s</a></li>',
        field(doc, "\\name"), htmltools::htmlEscape(paste(field(doc, "\\title"), collapse = ""))), ""), collapse = "\n")
    writeLines(paste0('<!doctype html><html lang="en"><meta charset="utf-8"><title>ivue reference</title>',
        '<h1>ivue reference</h1><ul>', reference.links, '</ul><a href="../">Home</a></html>'),
        file.path(output, "html", "index.html"))
    # Rd2HTML's reference navigation uses R's conventional index filename.
    file.copy(file.path(output, "html", "index.html"), file.path(output, "html", "00Index.html"))
    stopifnot(file.copy(archive, file.path(output, basename(archive))))
    stopifnot(file.copy("vignettes/figures/retinal-sknn.png", file.path(output, "retinal-sknn.png")))
    commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
    dirty <- length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L
    manifest <- list(package = "ivue", version = version, commit = commit,
                     uncommitted.changes = dirty, archive = basename(archive),
                     md5 = unname(tools::md5sum(archive)), built.utc = format(Sys.time(), tz = "UTC"))
    dput(manifest, file.path(output, "build-info.R"))
    template <- paste(readLines("tools/site-index.html", warn = FALSE), collapse = "\n")
    template <- gsub("@@VERSION@@", version, template, fixed = TRUE)
    template <- gsub("@@COMMIT@@", commit, template, fixed = TRUE)
    template <- gsub("@@ARCHIVE@@", basename(archive), template, fixed = TRUE)
    writeLines(template, file.path(output, "index.html"))
    file.create(file.path(output, ".nojekyll"))
    cat("Built", output, "from", basename(archive), "\n")
})
