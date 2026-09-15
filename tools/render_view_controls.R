# Browser regression fixtures for accessible controls, camera recipes and bounds.
library(ivue)
dir.create('artifacts',showWarnings=FALSE)
X <- rbind(a=c(-1,-1,0), b=c(1,-1,0), c=c(0,1,1))
limits <- rbind(c(-2,2),c(-2,2),c(-2,2))
camera <- camera.zup(elevation=35,turn=0)
widgets <- list(
    plot3D.groups(X, c(a='A',b='B',c='C'), limits=limits, camera=camera,
        point.size=15,height=420,description='Three reference observations'),
    plot3D.plain(X/2,limits=limits,camera=camera,point.size=15,height=420,
        description='The same configuration contracted by half'))
htmltools::save_html(htmltools::tagList(widgets),'artifacts/view-controls.html',libdir='lib')
sc <- color.scale.cont(c(-1,0,1)); mapping <- map.colors(c(-1,0,1),sc)
w <- animate.frames(list(X*0,X/2,X), mapping=mapping,
    labels=c('Initial','Middle','Final'),description='Triangle expansion',
    caption='Color: final height; positions: current frame.',legend.title='Final height',
    height=420,point.size=15)
htmlwidgets::saveWidget(w,'artifacts/annotated-animation.html',selfcontained=TRUE)
long <- plot3D.groups(cbind(1:11,0,0),paste('Retinal cell type',1:11),
    description='Eleven labeled categories',height=420)
htmlwidgets::saveWidget(long,'artifacts/readable-legend.html',selfcontained=TRUE)
