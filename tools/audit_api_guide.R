# Run from the package root; no package loading or rendering is needed.
ns <- parse("NAMESPACE")
entries <- function(kind) Filter(function(x) is.call(x) &&
  identical(x[[1L]], as.name(kind)), as.list(ns))
exports <- vapply(entries("export"), function(x) as.character(x[[2L]]), "")
guide <- readLines("vignettes/function-guide.Rmd", warn = FALSE)
linked.guide <- guide
guide <- gsub("\\[(`[^`]+`)\\]\\([^)]+\\)", "\\1", guide)
rows <- grep("^\\| `[^`]+[(][)]` \\|", guide, value = TRUE)
catalog <- sub("^\\| `([^`]+)[(][)]`.*$", "\\1", rows)
if (anyDuplicated(catalog) || !setequal(catalog, exports)) {
  stop("Catalog mismatch: missing = ", paste(setdiff(exports, catalog), collapse = ", "),
       "; extra = ", paste(setdiff(catalog, exports), collapse = ", "),
       "; duplicates = ", paste(unique(catalog[duplicated(catalog)]), collapse = ", "))
}
stopifnot(all(lengths(strsplit(rows, "|", fixed = TRUE)) == 5L))
definitions <- unlist(lapply(list.files("R", "[.]R$", full.names = TRUE), function(p) {
  expr <- as.list(parse(p))
  vapply(Filter(function(x) is.call(x) && identical(x[[1L]], as.name("<-")) &&
    is.call(x[[3L]]) && identical(x[[3L]][[1L]], as.name("function")), expr),
    function(x) as.character(x[[2L]]), "")
}))
stopifnot(all(exports %in% definitions))
rd <- lapply(list.files("man", "[.]Rd$", full.names = TRUE), tools::parse_Rd)
aliases <- unlist(lapply(rd, function(doc) unlist(lapply(Filter(function(x)
  identical(attr(x, "Rd_tag"), "\\alias"), doc), as.character))))
stopifnot(all(exports %in% aliases))
# Each catalog link points to the canonical Rd topic, including shared topics.
field <- function(doc, tag) unlist(lapply(Filter(function(x)
  identical(attr(x, "Rd_tag"), tag), doc), as.character))
for (doc in rd) {
  topic <- field(doc, "\\name")
  for (alias in intersect(exports, field(doc, "\\alias"))) {
    expected <- paste0("| [`", alias, "()`](../html/", topic, ".html) |")
    stopifnot(sum(startsWith(linked.guide, expected)) == 1L)
  }
}
methods <- vapply(entries("S3method"), function(x)
  paste(as.character(x[[2L]]), as.character(x[[3L]]), sep="."), "")
stopifnot(all(methods %in% definitions), all(methods %in% aliases))
n.methods <- length(methods)
stopifnot(any(grepl(sprintf("%d explicit public function exports", length(exports)), guide, fixed = TRUE)),
          any(grepl(sprintf("%d S3 methods", n.methods), guide, fixed = TRUE)))
# Vignette cross-links must resolve to maintained sources (anchors checked after build).
for (p in list.files("vignettes", "[.]Rmd$", full.names = TRUE)) {
  text <- paste(readLines(p, warn = FALSE), collapse = "\n")
  links <- regmatches(text, gregexpr("\\]\\(([a-z][a-z0-9-]*)[.]html(?:#[^)]*)?\\)", text, perl = TRUE))[[1]]
  target <- sub("^.*\\]\\(([^.#]+)[.]html.*$", "\\1", links)
  stopifnot(all(file.exists(file.path("vignettes", paste0(target, ".Rmd")))))
}
cat(sprintf("Catalog: %d/%d exports, exactly one row each; %d S3 registrations; all local definitions and help aliases verified.\n",
            length(catalog), length(exports), n.methods))
