# Developer-only online audit; not run during package checks.
stopifnot(requireNamespace("xml2", quietly = TRUE), requireNamespace("curl", quietly = TRUE))
dir.create("artifacts", showWarnings = FALSE)
desc <- read.dcf("DESCRIPTION")[1, ]
repos <- c(CRAN = "https://cran.r-project.org",
           BioCsoft = "https://bioconductor.org/packages/release/bioc",
           BioCann = "https://bioconductor.org/packages/release/data/annotation",
           BioCexp = "https://bioconductor.org/packages/release/data/experiment",
           BioCworkflows = "https://bioconductor.org/packages/release/workflows")
catalogs <- lapply(repos, function(repo) {
    ap <- available.packages(contriburl = contrib.url(repo, "source"), filters = list())
    stopifnot(nrow(ap) > 0L)
    ap
})
archive.url <- "https://cran.r-project.org/src/contrib/Archive/"
archive <- xml2::read_html(archive.url)
archive.names <- sub("/$", "", xml2::xml_text(xml2::xml_find_all(archive, ".//a")))
name.matches <- lapply(c(lapply(catalogs, rownames), list(CRANarchive = archive.names)),
                      function(x) x[tolower(x) == tolower(desc[["Package"]])])
deps <- tools::package_dependencies(desc[["Package"]], db = read.dcf("DESCRIPTION"),
    which = c("Depends", "Imports", "Suggests"))[[1]]
base.pkgs <- rownames(installed.packages(priority = c("base", "recommended")))
external <- setdiff(deps, c("R", base.pkgs))
stopifnot(all(external %in% rownames(catalogs$CRAN)))
dependency.audit <- catalogs$CRAN[external, c("Package", "Version", "License", "Repository"), drop = FALSE]
urls <- c(desc[["URL"]], desc[["BugReports"]])
url.status <- vapply(urls, function(url) curl::curl_fetch_memory(url)$status_code, integer(1))
result <- list(checked.at = format(Sys.time(), tz = "UTC", usetz = TRUE),
               name.matches = name.matches, catalog.sizes = vapply(catalogs, nrow, integer(1)),
               dependencies = dependency.audit, url.status = url.status,
               package.license = desc[["License"]])
dput(result, file = "artifacts/release-audit.R")
print(result)
stopifnot(all(lengths(name.matches) == 0L), all(url.status == 200L))
