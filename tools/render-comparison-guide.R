options(rgl.useNULL=TRUE)
pkgload::load_all('.',quiet=TRUE)
out<-file.path(getwd(),'build','comparison-guide')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
e<-new.env(parent=globalenv())
rmarkdown::render('vignettes/ivue-introduction.Rmd',output_dir=out,envir=e,quiet=TRUE)
stopifnot(e$have.rgl,nrow(e$saddle)==500L,length(e$original.dist)==124750L,
  e$comparison.quality$RMS_relative_error_percent[1]<1e-8,
  e$comparison.quality$RMS_relative_error_percent[2]>0,
  identical(attr(e$comparison.exact.widget,'ivue')$row.ids,
            attr(e$comparison.projected.widget,'ivue')$row.ids))
write.csv(e$comparison.quality,file.path(out,'comparison-quality.csv'),row.names=FALSE)
cat('PASS: both comparison scenes rendered; original distances and row correspondence checked.\n')
