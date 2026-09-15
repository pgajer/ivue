args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args) == 1L, file.exists(args))
files <- utils::untar(args, list=TRUE)
# R CMD build creates this installed-vignette index after source exclusions.
files <- setdiff(files, c('ivue/build/', 'ivue/build/vignette.rds'))
stopifnot(!any(grepl('^ivue/(tools|private|artifacts|build|[.]github)/', files)))
cat('PASS: development tools, private records, build products and CI files excluded from source archive.\n')
