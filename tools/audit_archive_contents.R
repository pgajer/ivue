args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args) == 1L, file.exists(args))
files <- utils::untar(args, list=TRUE)
# Preserve R's prebuilt vignette index across R build implementations.
stopifnot('ivue/build/vignette.rds' %in% files)
files <- setdiff(files, c('ivue/build/', 'ivue/build/vignette.rds'))
stopifnot(!any(grepl('^ivue/(tools|private|artifacts|build|[.]github)/', files)))
cat('PASS: development tools, private records, build products and CI files excluded from source archive.\n')
