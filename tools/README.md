# Developing and checking ivue

Run commands from the package root. `R/`, vignette `.Rmd` files, README.md,
and `tools/site-index.html` are maintained sources. `man/*.Rd` and NAMESPACE
come from roxygen; `build/`, check directories, and `artifacts/` are disposable
outputs excluded from source packages and Git. Private investigation records
live outside this repository.

## Routine changes

| Task | Entry point | Input → result | Typical cost |
|---|---|---|---|
| Regenerate help | `make document` | R roxygen comments → Rd/NAMESPACE | Seconds |
| Check the API map | `make audit-guide` | exports, Rd aliases, guide → exact coverage and help-target checks | Seconds; no rendering |
| Focused R tests | `Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-animation.R")'` | Source + selected tests → assertions | Seconds |
| Build distributable guides | `make build` | Package source → staged `build/ivue_*.tar.gz`, `build/vignettes/` | About a minute; no upstream fits |
| Audit an existing candidate | `make -o build audit-distribution` | Exact built archive → temporary installed help, vignette links/resources, byte counts, negative fixtures, archive exclusions | Under a minute |
| Full / minimal checks | `make check-cran`; `make -o build check-minimal` | Same archive → `ivue.Rcheck/`, `artifacts/minimal-check/` | Minutes; minimal check omits optional packages |
| Preview website | `make -o build site` | Same archive → `build/site/`, including help, guides, source download and manifest | Under a minute; local only |

The distribution audit installs with static HTML help so that every guide-to-help
link can be checked without an R help server. It also checks installed aliases,
the overview's index entry, the five-guide index and overview links, and runs the
package example. Normal R installations may serve help dynamically. The audit's
negative fixtures must detect a missing overview entry, missing local asset, and
broken anchor. CI runs this audit on the archive created by its minimal-check
step; it does not build a second candidate for the audit.

## Browser and Shiny qualification

`render_examples.R`, `render_audit_fixes.R`, `render_view_controls.R`, and
`render_gif_presentation.R` create small reproducible fixtures in `artifacts/`.
The corresponding `*_browser.cjs` checks run in the browser CI job using its
pinned Playwright runtime. They check real scene changes and exported camera
replay as well as keyboard controls, labels, overflow, and fallback text.
`browser_pixels.cjs` supports raster assertions. The ivue-only
`shiny_controls.R` / `shiny_controls_browser.cjs` check reactive scene updates
and independent animation players. `accessibility-checks.md` records the manual
assistive-technology procedure and the qualified combinations.

The older `project_smoke*`, `shiny_smoke*`, and `downstream_pipeline.R` exercise
optional sibling-package integrations; read their headers for prerequisites.
They are not required to build ivue's ordinary guides. `benchmark_scenes.R`
measures larger scenes; `capture_baseline.R` captures comparison data.

## Example figures and expensive retinal work

`build-guide-posters.R` regenerates the small static guide figures.
`retinal-display-transform.R` and `retinal-view-orientation.R` contain the
recorded display transformations; their `test-retinal-*` scripts check these
without fitting a new embedding. `saddle-delaunay.R` supports the surface demo.

**Do not run the retinal targets for an ordinary code or documentation edit.**
They require external caches/data and optional packages, can take hours, and
may regenerate large media or the redistributed display bundle:

- `make readme-retinal-layout` uses `prepare-retinal-readme.R` to prepare upstream
  layouts/cache inputs. Read its source and provenance requirements first.
- `make readme-retinal-sknn`, `readme-retinal-umap`, and
  `readme-retinal-comparison` run the render/capture/encode scripts and update
  README figures. They install a local browser runtime under `artifacts/`.
- `make retinal-vignette-data` runs `generate-retinal-vignette-data.R` to rebuild
  the bundled display data; `make retinal-vignette` also copies showcase figures.
- `prepare-retinal-phate-input.R` and `fit-retinal-phate.py` form a separate
  upstream PHATE calculation with `retinal-phate-requirements.txt`.

Existing provenance and data-use terms remain authoritative. A picture is not
an embedding-quality test. No large upstream calculation runs in the normal
build, distribution audit, package tests, or browser fixtures.

## Release utilities

`release_audit.R` and `release_browser.cjs` provide additional release probes.
`check_winbuilder.R` concerns the external Win-builder service: read its behavior
and obtain release authorization before submitting. Building/checking locally
is separate from CRAN submission. GitHub Pages uses `build_site.R` and
`audit_site.py`; the site manifest identifies the archive and source commit.
