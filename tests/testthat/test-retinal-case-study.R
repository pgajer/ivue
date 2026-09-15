test_that("retinal case-study data preserve cross-view identities", {
    path <- system.file("extdata", "retinal-development.rds", package = "ivue")
    expect_true(nzchar(path))
    retina <- readRDS(path)

    expect_named(retina, c("coordinates", "graph", "annotations", "provenance"))
    expect_named(retina$coordinates, c("umap", "sknn"))
    expect_equal(dim(retina$coordinates$umap), c(12000L, 3L))
    expect_equal(dim(retina$coordinates$sknn), c(12000L, 3L))
    fitting <- retina$provenance$fitting.graph
    expect_equal(fitting$vertices, 120804L)
    expect_equal(fitting$edges, 374597L)
    expect_equal(fitting$components, 1L)
    expect_equal(retina$provenance$graph.selection$selected, 4L)
    expect_gt(fitting$displayed.edges, 0L)
    expect_lt(fitting$displayed.edges, fitting$edges)
    expect_equal(nrow(retina$graph$edges), fitting$displayed.edges)
    expect_true(all(retina$graph$edges$from %in% retina$annotations$id))
    expect_true(all(retina$graph$edges$to %in% retina$annotations$id))
    expect_true(all(is.finite(retina$graph$edges$weight)))
    expect_true(all(retina$graph$edges$weight >= 0))
    expect_identical(rownames(retina$coordinates$umap), retina$annotations$id)
    expect_identical(rownames(retina$coordinates$sknn), retina$annotations$id)
    expect_identical(retina$graph$vertices, retina$annotations$id)
    expect_false(any(grepl("barcode", names(retina$annotations), ignore.case = TRUE)))
    expect_true(all(is.finite(retina$coordinates$umap)))
    expect_true(all(is.finite(retina$coordinates$sknn)))

    graph <- prepare.graph(retina$graph)
    expect_s3_class(graph, "ivue_graph")
    expect_identical(graph$weight.type, "distance")
    expect_equal(nrow(graph$vertices), 12000L)
    expect_equal(nrow(graph$edges), fitting$displayed.edges)
})

test_that("retinal display units and unavailable historical parameters are explicit", {
    retina <- readRDS(system.file("extdata", "retinal-development.rds", package = "ivue"))
    transforms <- retina$provenance$display.transforms
    expect_named(transforms, c("umap", "sknn"))
    expect_length(transforms$umap$center, 3L)
    expect_true(all(is.finite(transforms$umap$center)))
    expect_identical(transforms$umap$scale.factor, 1)
    expect_equal(colMeans(retina$coordinates$umap), c(x = 0, y = 0, z = 0), tolerance = 1e-12)
    expect_equal(colMeans(retina$coordinates$sknn), c(x = 0, y = 0, z = 0), tolerance = 1e-12)
    expect_equal(max(sqrt(rowSums(retina$coordinates$sknn^2))), 1, tolerance = 1e-12)
    expect_match(transforms$sknn$scale.rule, "maximum Euclidean radius")
    if (grepl("not retained", transforms$sknn$parameter.status)) {
        expect_true(all(is.na(transforms$sknn$center)))
        expect_true(is.na(transforms$sknn$scale.factor))
    } else {
        expect_true(all(is.finite(transforms$sknn$center)))
        expect_gt(transforms$sknn$scale.factor, 0)
    }
})
