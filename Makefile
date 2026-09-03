.PHONY: document build check install

PKGNAME := ivue
VERSION := $(shell sed -n 's/^Version: //p' DESCRIPTION)
TARBALL := $(PKGNAME)_$(VERSION).tar.gz
R_ENV := env -u R_HOME -u R_LIBS -u R_LIBS_USER -u R_LIBS_SITE
R_RUN := $(R_ENV) R
RSCRIPT_RUN := $(R_ENV) Rscript

document:
	$(RSCRIPT_RUN) -e 'roxygen2::roxygenise()'

build: document
	$(R_RUN) CMD build --no-build-vignettes --no-manual .

check: build
	RGL_USE_NULL=TRUE $(R_RUN) CMD check --no-manual $(TARBALL)

install: build
	$(R_RUN) CMD INSTALL $(TARBALL)
