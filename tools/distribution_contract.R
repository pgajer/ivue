# Shared by the installed-candidate audit and its negative fixture.
audit.overview.index <- function(index) {
    if (!grepl('href=["\x27]ivue-package.html["\x27]', index))
        stop("Installed help index lacks the package overview link.")
    invisible(TRUE)
}
