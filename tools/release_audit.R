# Developer-only online audit; not run during package checks.
# Usage: Rscript tools/release_audit.R [auto|update|new]
stopifnot(requireNamespace("xml2", quietly = TRUE), requireNamespace("curl", quietly = TRUE))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) <= 1L)
mode <- match.arg(if (length(args)) args else "auto", c("auto", "update", "new"))
dir.create("artifacts", showWarnings = FALSE)
desc <- read.dcf("DESCRIPTION")[1, ]
cran <- available.packages(repos = "https://cran.r-project.org", filters = list())
stopifnot(nrow(cran) > 0L)
package <- desc[["Package"]]
published <- package %in% rownames(cran)
if (mode == "auto") mode <- if (published) "update" else "new"
name.matches <- NULL
reverse.dependencies <- NULL
published.version <- if (published) cran[package, "Version"] else NA_character_
if (mode == "update") {
    if (!published) stop("An update requires an existing CRAN package: ", package)
    if (utils::compareVersion(desc[["Version"]], published.version) <= 0L)
        stop("Version must exceed CRAN ", published.version, ": ", desc[["Version"]])
    reverse.dependencies <- tools::package_dependencies(package, db = cran,
        which = c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances"),
        reverse = TRUE)[[package]]
} else {
    repos <- c(BioCsoft = "https://bioconductor.org/packages/release/bioc",
               BioCann = "https://bioconductor.org/packages/release/data/annotation",
               BioCexp = "https://bioconductor.org/packages/release/data/experiment",
               BioCworkflows = "https://bioconductor.org/packages/release/workflows")
    catalogs <- c(list(CRAN = cran), lapply(repos, function(repo) {
        ap <- available.packages(contriburl = contrib.url(repo, "source"), filters = list())
        stopifnot(nrow(ap) > 0L)
        ap
    }))
    archive <- xml2::read_html("https://cran.r-project.org/src/contrib/Archive/")
    archive.names <- sub("/$", "", xml2::xml_text(xml2::xml_find_all(archive, ".//a")))
    name.matches <- lapply(c(lapply(catalogs, rownames), list(CRANarchive = archive.names)),
        function(x) x[tolower(x) == tolower(package)])
    if (any(lengths(name.matches))) stop("Package name is already in use; select update mode if appropriate.")
}
deps <- tools::package_dependencies(package, db = read.dcf("DESCRIPTION"),
    which = c("Depends", "Imports", "Suggests"))[[package]]
base.pkgs <- rownames(installed.packages(priority = c("base", "recommended")))
external <- setdiff(deps, c("R", base.pkgs))
stopifnot(all(external %in% rownames(cran)))
dependency.audit <- cran[external, c("Package", "Version", "License", "Repository"), drop = FALSE]
urls <- unlist(strsplit(paste(desc[["URL"]], desc[["BugReports"]]), "[,[:space:]]+"))
urls <- urls[nzchar(urls)]
url.status <- vapply(urls, function(url) curl::curl_fetch_memory(url)$status_code, integer(1))
result <- list(checked.at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    submission.type = mode, package = package, version = desc[["Version"]],
    published.version = published.version, reverse.dependencies = reverse.dependencies,
    name.matches = name.matches, dependencies = dependency.audit,
    url.status = url.status, package.license = desc[["License"]])
dput(result, file = "artifacts/release-audit.R")
print(result)
stopifnot(all(url.status == 200L))
