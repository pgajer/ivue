# Small offline figures for the installed guides; no WebGL or upstream fits.
# Run from the package root after installing the current ivue candidate.
library(ivue)
project <- function(X, camera=camera.zup()) (cbind(as.matrix(X),1) %*% t(camera$userMatrix))[,1:3]
canvas <- function(file, draw, width=900, height=420) {
    grDevices::png(file, width=width, height=height, res=110)
    on.exit(grDevices::dev.off())
    graphics::par(mar=c(1,1,3,1))
    draw()
}
set.seed(1)
xs <- runif(250,-1,1); ys <- runif(250,-1,1)
X <- cbind(xs,ys,1.2*(xs^2-ys^2))
canvas('vignettes/figures/saddle-points.png', function() {
    p <- project(X)
    graphics::plot(p[,1:2],asp=1,pch=16,cex=.65,col='#197A68',axes=FALSE,xlab='',ylab='',
                   main='250 points on a saddle')
})
# Reproduce the introduction's area-uniform sample and 2D triangulation.
set.seed(1); xy <- matrix(numeric(),ncol=2)
while (nrow(xy)<500) {
    proposal <- matrix(runif(4000,-1,1),ncol=2)
    area <- sqrt(1+4*.8^2*rowSums(proposal^2))
    xy <- rbind(xy,proposal[runif(nrow(proposal))<area/sqrt(1+8*.8^2),,drop=FALSE])
}
xy <- xy[1:500,]; X <- cbind(xy,.8*(xy[,1]^2-xy[,2]^2))
tri <- geometry::delaunayn(xy)
canvas('vignettes/figures/saddle-mesh.png', function() {
    p <- project(X)
    graphics::plot(p[,1:2],type='n',asp=1,axes=FALSE,xlab='',ylab='',main='Triangular faces connect the sampled observations')
    for (i in order(rowMeans(matrix(p[tri,3],ncol=3))))
        graphics::polygon(p[tri[i,],1:2],col='#dddddd',border='#aaaaaa',lwd=.4)
    col <- map.colors(X[,3],color.scale.cont(X[,3],center=0,palette=c('blue','yellow','red')))$colors
    graphics::points(p[,1:2],pch=16,cex=.3,col=col)
})
grid <- expand.grid(x=seq(-1,1,length.out=7), y=seq(-1,1,length.out=7))
frames <- lapply(c(0,.6,1.2),function(a) cbind(grid,a*(grid$x^2-grid$y^2)))
colors <- map.colors(frames[[3]][,3],color.scale.cont(frames[[3]][,3],center=0,
                palette=c('#2455A4','#ECE6C2','#B83232')))$colors
ps <- lapply(frames,project,camera=camera.zup(elevation=25,turn=-130))
limits <- apply(do.call(rbind,ps),2,range)
canvas('vignettes/figures/saddle-animation.png',function() {
    graphics::par(mfrow=c(1,3),mar=c(1,1,3,1))
    for (i in seq_along(ps)) graphics::plot(ps[[i]][,1:2],xlim=limits[,1],ylim=limits[,2],
        asp=1,pch=16,cex=.8,col=colors,axes=FALSE,xlab='',ylab='',
        main=c('Plane: amplitude 0','Halfway: amplitude 0.6','Saddle: amplitude 1.2')[i],cex.main=.9)
},width=1050,height=350)
