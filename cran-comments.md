## Submission

Resubmission of ivue 0.1.0 following the September 17, 2026 request to restore
options, graphical parameters, and the working directory with immediate
`on.exit()` handlers. There are no CRAN reverse dependencies.

## Changes Addressing Review

- Both GIF rendering helpers in `R/animation-gif.R` and
  `R/animation-annotations.R` now save graphical parameters and immediately
  register `on.exit()` restoration, before changing them. Restoration runs
  before closing the private PNG device, on success and error. Only relevant
  parameters are saved; derived dimensions such as `pin` can be invalid to
  reapply on very small devices with default margins.
- The temporary `rgl.useNULL` option in `R/scene.R` already has an immediate
  restoration handler. Regression tests now also cover an initially FALSE
  or absent option, including errors during drawing. The renderer retains
  its existing device and subscene cleanup.
- Package functions, examples, and vignettes do not call `setwd()`.
- New regression tests verify annotation parameter restoration, successful
  and failed GIF export with two existing graphics devices, unchanged caller
  options and working directory, and widget error cleanup. Eight raster
  comparisons confirm unchanged rendering pixels.

## Package Scope

Interactive 3D point and embedded-graph visualization with reusable color
scales, geometric layers, recorded-frame playback, and optional GIF export.
The optional rgl backend is loaded only when
rendering; color mapping and graph preparation work without it. Ordinary
plotting uses null-device scenes without opening a native graphics window.
Examples and tests guard optional packages and do not launch a browser.

## Checks

Candidate package contents checked September 17, 2026 (commit 5cf42dc):

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190):
  `R_TIDYCMD=/opt/homebrew/bin/tidy make check-cran`, with HTML Tidy 5.8.0:
  0 errors, 0 warnings, 1 NOTE (`New submission`). All 920 assertions passed;
  examples, all five vignette rebuilds, and PDF/HTML manuals passed.
- `make -o build check-minimal` checked the same archive with dependency-only
  settings: Status OK, 861 assertions passed, four magick tests and one Shiny
  test skipped. This check does not rebuild vignettes.
- Preparation/color/camera/layer probes confirm rgl is not loaded. All 18
  explicit exports have help and one catalog row; 2 S3 print methods are
  documented through their object workflows.
- `make -o build audit-distribution` installs the exact archive and checks
  overview/index discovery, all five guides, their help links, local resources,
  byte counts, and source exclusions. Negative fixtures detect a missing
  overview entry, broken anchor, and missing asset.
- GitHub Actions run 35240857184 passed all six package jobs: Linux R-release,
  R-devel and R 4.1; Windows R-release and R-devel; and macOS R-release.
  Its browser job also passed, including Chromium/Firefox controls, GIF
  comparisons, and Shiny rerender/focus checks.

Installed size is INFO on this R version: 5.8 MB total, including 4.9 MB of
`doc`. Installed documentation totals 5,113,201 bytes (4.876 MiB), including
R's generated vignette index. Guides retain local/embedded resources and do
not need remote assets to render essential examples. Large retinal fitting
and media-generation tasks remain outside normal checks.

Shiny is an optional suggested dependency for reactive-context tests. Ordinary
preparation and rendering do not require it. The optional grip workflow remains
guarded, and no upstream retinal analysis was rerun. No CRAN resubmission
or Win-builder upload has been made for these contents.

The retinal case study uses bundled coordinates and static posters. Its
large rendering and upstream data-processing recipes are not evaluated
during checking. The source values and their redistribution scope are unchanged.

## Retinal Example: Source Terms

The retinal example contains a subset of published numerical coordinates and
cell annotations from Clark et al. (2019),
DOI:10.1016/j.neuron.2019.04.010, associated with GEO GSE118614, together with
graph-layout coordinates computed for this package. The original sources are
credited in the package.

The upstream repository makes the data publicly available. Its stated
prepublication consent restriction applied before January 1, 2019; we found
no separate dataset license. We disclose these circumstances explicitly and
would appreciate guidance if CRAN requires additional documentation for
inclusion of this example.

Upstream source and use agreement:
https://github.com/gofflab/developing_mouse_retina_scRNASeq#use-agreement
