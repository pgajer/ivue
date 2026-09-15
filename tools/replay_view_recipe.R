# Reconstruct the known browser fixture with settings exported by its controls.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L)
library(ivue)
source(args[1], local=TRUE)
X <- rbind(a=c(-1,-1,0),b=c(1,-1,0),c=c(0,1,1))
w <- do.call(plot3D.groups, c(list(X=X,groups=c(a='A',b='B',c='C'),
    point.size=15,height=420,description='Reconstructed view'), view))
htmlwidgets::saveWidget(w,args[2],selfcontained=FALSE,libdir='lib')
