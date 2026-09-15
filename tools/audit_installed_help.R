# Run against a built, installed candidate, not a development namespace.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
local({
    lib <- tempfile("ivue-help-library-")
    dir.create(lib)
    on.exit(unlink(lib, recursive = TRUE))
    status <- system2(file.path(R.home("bin"), "R"),
                      c("CMD", "INSTALL", "--html", paste0("--library=", shQuote(lib)), shQuote(args[1])))
    stopifnot(status == 0L)
    library(ivue, lib.loc = lib, character.only = FALSE)
    pkg <- find.package("ivue", lib.loc = lib)
    for (alias in c("ivue", "ivue-package"))
        stopifnot(length(help(alias, package = "ivue", lib.loc = lib)) == 1L)
    index <- paste(readLines(file.path(pkg, "html", "00Index.html")), collapse = "\n")
    source("tools/distribution_contract.R", local=TRUE)
    audit.overview.index(index)
    overview <- utils:::.getHelpFile(help("ivue", package = "ivue", lib.loc = lib))
    html <- paste(capture.output(tools::Rd2HTML(overview)), collapse = "\n")
    guides <- c("function-guide", "example-data", "ivue-introduction", "retinal-development", "animation")
    for (guide in guides) {
        stopifnot(grepl(paste0('../doc/', guide, '.html'), html, fixed = TRUE),
                  file.exists(file.path(pkg, "doc", paste0(guide, ".html"))))
    }
    stopifnot(setequal(vignette(package = "ivue", lib.loc = lib)$results[, "Item"], guides))
    stopifnot(system2("python3", c("tools/audit_vignette_html.py", shQuote(file.path(pkg, "doc")))) == 0L)
    example("ivue", package = "ivue", lib.loc = lib, ask = FALSE, echo = FALSE)
    cat("PASS: package aliases, visible overview index, five installed guide links, and package example.\n")
})
