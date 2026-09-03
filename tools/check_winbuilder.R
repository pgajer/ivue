# Explicit developer action: uploads an already-checked tarball to Win-builder,
# not to CRAN. Results go to the maintainer in the package DESCRIPTION.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || !args[2] %in% c("release", "devel"))
    stop("Usage: Rscript tools/check_winbuilder.R <tarball> <release|devel>")
file <- normalizePath(args[1], mustWork = TRUE)
stopifnot(grepl("^ivue_[0-9.]+[.]tar[.]gz$", basename(file)),
          requireNamespace("httr", quietly = TRUE),
          requireNamespace("xml2", quietly = TRUE),
          requireNamespace("digest", quietly = TRUE))
url <- "https://win-builder.r-project.org/upload.aspx"
page <- httr::GET(url)
httr::stop_for_status(page)
doc <- xml2::read_html(httr::content(page, as = "raw"))
hidden <- xml2::xml_find_all(doc, ".//input[@type='hidden']")
body <- as.list(stats::setNames(xml2::xml_attr(hidden, "value"), xml2::xml_attr(hidden, "name")))
index <- if (args[2] == "release") "1" else "2"
body[[paste0("FileUpload", index)]] <- httr::upload_file(file, "application/gzip")
body[[paste0("Button", index)]] <- "Upload File"
cat("Uploading", basename(file), "to Win-builder R-", args[2], "\n")
cat("SHA-256:", digest::digest(file = file, algo = "sha256"), "\n")
response <- httr::POST(url, body = body, encode = "multipart", httr::timeout(120))
httr::stop_for_status(response)
content <- httr::content(response, as = "raw")
dir.create("artifacts/winbuilder", recursive = TRUE, showWarnings = FALSE)
writeBin(content, file.path("artifacts/winbuilder", paste0(args[2], "-upload.html")))
message <- xml2::xml_text(xml2::xml_find_first(xml2::read_html(content),
                         paste0(".//*[@id='Label", index, "']")))
cat("Server response:", message, "\n")
cat("Do not retry an uncertain upload without first checking for its result email.\n")
