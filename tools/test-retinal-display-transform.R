source("tools/retinal-display-transform.R")
X <- rbind(c(8, 20, 30), c(12, 20, 30), c(10, 20, 30))
normalized <- retinal.display.transform(X, rescale = TRUE)
stopifnot(identical(normalized$transform$center, c(10, 20, 30)),
          identical(normalized$transform$scale.factor, 2),
          identical(normalized$coordinates, rbind(c(-1, 0, 0), c(1, 0, 0), c(0, 0, 0))))
centered <- retinal.display.transform(X)
stopifnot(identical(centered$transform$scale.factor, 1),
          identical(sweep(centered$coordinates, 2, centered$transform$center, "+"), X))
cat("Display transforms: known center/radius and inverse transformation verified.\n")
