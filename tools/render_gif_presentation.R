# Small raster/WebGL scale comparisons and annotated exports; no upstream fits.
library(ivue)
dir.create('artifacts', showWarnings=FALSE)
args <- commandArgs(trailingOnly=TRUE)
cases <- expand.grid(zoom=c(.4,.8), shape=c('wide','tall'), extent=c(1,2), stringsAsFactors=FALSE)
if (length(args)) {
    source(args[1]) # Controlled camera recipe written by the browser regression.
    cases <- data.frame(zoom=view$camera$zoom, shape='wide', extent=1)
}
records <- vector('list', nrow(cases))
for (j in seq_len(nrow(cases))) {
    config <- cases[j, ]
    X <- rbind(c(-.5,0,0),c(.5,0,0))
    camera <- if (length(args)) view$camera else camera.zup(90,0,zoom=config$zoom)
    w <- animate.frames(list(X, X*config$extent*2), camera=camera,
        col=c('#FF0000','#0000FF'), point.size=12, controls=TRUE)
    info <- attr(w,'ivue.animation')
    width <- if (config$shape=='wide') 600 else 360
    height <- if (config$shape=='wide') 360 else 600
    name <- if (length(args)) 'recovered' else paste0('case-',j)
    htmlwidgets::saveWidget(w, file.path('artifacts',paste0('gif-',name,'.html')), selfcontained=FALSE)
    projection <- ivue:::.animation.projection(info)
    png <- file.path('artifacts',paste0('gif-',name,'.png'))
    ivue:::.animation.png(info,projection,1,png,width,height,FALSE)
    img <- magick::image_data(magick::image_read(png), channels='rgb')
    rgb <- array(as.integer(unclass(img)),dim=dim(img))
    centers <- lapply(1:2,function(i) {
        primary <- if(i==1) 1 else 3
        hit <- which(rgb[primary,,]>200 & rgb[2,,]<50 & rgb[4-primary,,]<50,arr.ind=TRUE)
        stopifnot(nrow(hit)>0)
        colMeans(hit)
    })
    records[[j]] <- list(name=name, width=width,height=height, X=unname(X),
        raster.distance=sqrt(sum((centers[[1]]-centers[[2]])^2)))
}
jsonlite::write_json(records, if(length(args)) 'artifacts/gif-recovered.json' else 'artifacts/gif-projections.json',
    auto_unbox=TRUE, digits=16)
if (!length(args)) {
    types <- unique(as.character(readRDS(system.file('extdata','retinal-development.rds',package='ivue'))$annotations$cell.type))
    X <- cbind(cos(seq(0,2*pi,length.out=12)),sin(seq(0,2*pi,length.out=12)),0)
    groups <- c(types,NA)
    mapping <- map.colors(groups,color.scale.groups(groups))
    w <- animate.frames(list(X*.3,X*.6,X),mapping=mapping,
        caption='Color: retinal category labels used here as an illustrative legend. Positions: an expanding circle, not retinal coordinates.',
        legend.title='Eleven retinal categories',labels=c('Initial','Middle','Final'))
    write.animation.gif(w,'artifacts/annotated-categories.gif',width=720,height=640,annotations=TRUE,overwrite=TRUE)
    info <- attr(w,'ivue.animation'); projection <- ivue:::.animation.projection(info)
    for(i in 1:3) ivue:::.animation.png(info,projection,i,paste0('artifacts/annotated-categories-',i,'.png'),720,640,TRUE,TRUE)
    for(mode in c('continuous','binned')) {
        values <- c(seq(-1,1,length.out=11),NA)
        mapping <- map.colors(values,color.scale.cont(values,mode=mode,n.bins=3,palette=c('#0000FF80','#FF000080')))
        w <- animate.frames(list(X*.3,X*.6,X),mapping=mapping,
            caption='Color: fixed final height; positions: current frame.',legend.title='Final height')
        write.animation.gif(w,paste0('artifacts/annotated-',mode,'.gif'),width=600,height=480,annotations=TRUE,overwrite=TRUE)
    }
}
