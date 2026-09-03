.PHONY: document build check check-cran check-minimal install

PKGNAME := ivue
VERSION := $(shell sed -n 's/^Version: //p' DESCRIPTION)
TARBALL := $(PKGNAME)_$(VERSION).tar.gz
R_ENV := env -u R_HOME -u R_LIBS -u R_LIBS_USER -u R_LIBS_SITE
R_RUN := $(R_ENV) R
RSCRIPT_RUN := $(R_ENV) Rscript

document:
	$(RSCRIPT_RUN) -e 'roxygen2::roxygenise()'

build: document
	$(R_RUN) CMD build .

check: build
	RGL_USE_NULL=TRUE $(R_RUN) CMD check --no-manual $(TARBALL)

check-cran: build
	RGL_USE_NULL=TRUE $(R_ENV) R_MAKEVARS_USER=/dev/null R CMD check --as-cran $(TARBALL)

check-minimal: build
	mkdir -p artifacts/minimal-check
	_R_CHECK_DEPENDS_ONLY_=true _R_CHECK_FORCE_SUGGESTS_=false RGL_USE_NULL=TRUE $(R_RUN) CMD check --no-manual --no-vignettes --output=artifacts/minimal-check $(TARBALL)

install: build
	$(R_RUN) CMD INSTALL $(TARBALL)
