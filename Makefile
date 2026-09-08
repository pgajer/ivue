.PHONY: document build check check-cran check-minimal install readme-retinal \
	readme-retinal-layout readme-retinal-deps readme-retinal-sknn \
	readme-retinal-umap readme-retinal-comparison retinal-vignette \
	retinal-vignette-data

PKGNAME := ivue
VERSION := $(shell sed -n 's/^Version: //p' DESCRIPTION)
TARBALL := $(PKGNAME)_$(VERSION).tar.gz
R_ENV := env -u R_HOME -u R_LIBS -u R_LIBS_USER -u R_LIBS_SITE
R_RUN := $(R_ENV) R
RSCRIPT_RUN := $(R_ENV) Rscript
NODE ?= node
NPM ?= npm
PLAYWRIGHT_VERSION ?= 1.62.1
RETINAL_NODE_DIR := artifacts/retinal-readme/node
RETINAL_PLAYWRIGHT := $(RETINAL_NODE_DIR)/node_modules/playwright

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

readme-retinal-layout:
	$(RSCRIPT_RUN) tools/prepare-retinal-readme.R

readme-retinal-deps:
	@test -f $(RETINAL_PLAYWRIGHT)/package.json || \
		$(NPM) install --prefix $(RETINAL_NODE_DIR) --no-save --no-package-lock \
		playwright@$(PLAYWRIGHT_VERSION)

readme-retinal-sknn: readme-retinal-layout readme-retinal-deps
	$(RSCRIPT_RUN) tools/render-retinal-readme.R --view=sknn
	PLAYWRIGHT_MODULE=$(CURDIR)/$(RETINAL_PLAYWRIGHT) \
		$(NODE) tools/capture-retinal-readme.cjs --view=sknn --animation
	$(RSCRIPT_RUN) tools/encode-retinal-readme.R --view=sknn

readme-retinal-umap: readme-retinal-layout readme-retinal-deps
	$(RSCRIPT_RUN) tools/render-retinal-readme.R --view=umap
	PLAYWRIGHT_MODULE=$(CURDIR)/$(RETINAL_PLAYWRIGHT) \
		$(NODE) tools/capture-retinal-readme.cjs --view=umap

readme-retinal-comparison: readme-retinal-layout readme-retinal-deps
	$(RSCRIPT_RUN) tools/render-retinal-readme.R --view=comparison
	PLAYWRIGHT_MODULE=$(CURDIR)/$(RETINAL_PLAYWRIGHT) \
		$(NODE) tools/capture-retinal-readme.cjs --view=comparison --animation
	$(RSCRIPT_RUN) tools/encode-retinal-readme.R --view=comparison

readme-retinal: readme-retinal-sknn readme-retinal-comparison

retinal-vignette-data: readme-retinal-layout
	$(RSCRIPT_RUN) tools/generate-retinal-vignette-data.R

retinal-vignette: readme-retinal readme-retinal-umap retinal-vignette-data
	mkdir -p vignettes/figures
	cp man/figures/readme-retinal-umap.png vignettes/figures/retinal-umap.png
	cp man/figures/readme-retinal-sknn.png vignettes/figures/retinal-sknn.png
	cp man/figures/readme-retinal-comparison.png \
		vignettes/figures/retinal-comparison.png
