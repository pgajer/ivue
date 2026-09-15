test_that('limits are validated before rendering without adding observations', {
    X <- rbind(a=c(-1,0,0), b=c(1,0,0))
    expect_error(plot3D.plain(X, limits=matrix(0,2,3)), '3-by-2')
    expect_error(plot3D.plain(X, limits=matrix(0,3,2)), 'contain')
    bad <- rbind(c(1,-1),c(-1,1),c(-1,1))
    expect_error(plot3D.plain(X, limits=bad), 'nondecreasing')
    skip_if(!nzchar(system.file(package='rgl')))
    limits <- rbind(c(-2,2),c(-3,3),c(-4,4))
    a <- plot3D.plain(X, limits=limits, camera=camera.zup())
    b <- plot3D.plain(X/2, limits=limits, point.type='sphere', sphere.radius=10,
        layers=list(layer3D.surface(c(-20,20),c(-20,20),matrix(0,2,2)),
                    layer3D.labels(1,'A label beyond the point')))
    pa <- attr(a,'ivue')$scene$rootSubscene$par3d
    pb <- attr(b,'ivue')$scene$rootSubscene$par3d
    expect_equal(pa$bbox, as.vector(t(limits)))
    expect_equal(pb$bbox, pa$bbox)
    expect_equal(pb$observer, pa$observer)
    expect_identical(attr(b,'ivue')$X, X/2)
    expect_equal(nrow(attr(b,'ivue')$draw.ids), 2L)
    expect_equal(attr(b,'ivue')$observation.ids, c('a','b'))
    flat <- plot3D.plain(X, limits=rbind(c(-2,2),c(0,0),c(0,0)))
    expect_true(all(is.finite(attr(flat,'ivue')$scene$rootSubscene$par3d$scale)))
    normal <- plot3D.plain(X, limits=limits, aspect='normalized')
    expect_equal(attr(normal,'ivue')$scene$rootSubscene$par3d$scale * c(4,6,8),
                 rep(sqrt(mean(c(4,6,8)^2)),3), tolerance=1e-6)
})

test_that('animation carries a fixed mapping and caption with its player', {
    X <- rbind(c(0,0),c(1,1),c(2,0))
    m <- map.colors(c(-1,0,1), color.scale.cont(c(-1,1)))
    expect_error(animate.frames(list(X,X),mapping=m,col='red'), 'not both')
    expect_error(animate.frames(list(X,X),mapping=list()), 'map.colors')
    skip_if(!nzchar(system.file(package='rgl')))
    w <- animate.frames(list(X,X*2),mapping=m,caption='<final height>',description='Changing triangle')
    info <- attr(w,'ivue.animation')
    expect_identical(info$mapping,m)
    expect_identical(info$col, m$colors)
    expect_identical(info$caption,'<final height>')
    expect_match(w$jsHooks$render[[2]]$data$legend, 'Read legend as table')
    expect_match(paste(vapply(w$append[-1],as.character,''),collapse=''), '&lt;final height&gt;')
    expect_identical(w$append[[1]]$jsHooks$render[[1]]$data$description, 'Changing triangle')
})

test_that('Shiny renderUI animations have explicit connected companion IDs', {
    skip_if(!nzchar(system.file(package='rgl')))
    skip_if_not_installed('shiny')
    session <- shiny::MockShinySession$new()
    on.exit(session$close())
    X <- rbind(c(0,0),c(1,1))
    widgets <- shiny::withReactiveDomain(session, list(
        animate.frames(list(X, X*2)), animate.frames(list(X, X*2))))
    expect_false(identical(widgets[[1]]$elementId, widgets[[2]]$elementId))
    for(w in widgets) {
        player <- w$append[[1]]
        expect_true(nzchar(w$elementId))
        expect_identical(player$x$sceneId, w$elementId)
        expect_identical(w$x$players, player$elementId)
    }
})
