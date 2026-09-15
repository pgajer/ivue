## Submission

First submission of ivue 0.1.0. There are no CRAN reverse dependencies.

## Package Scope

Interactive 3D point and embedded-graph visualization with reusable color
scales, geometric layers, recorded-frame playback, and optional GIF export.
The optional rgl backend is loaded only when
rendering; color mapping and graph preparation work without it. Ordinary
plotting uses null-device scenes without opening a native graphics window.
Examples and tests guard optional packages and do not launch a browser.

## Checks

Candidate package contents checked September 15, 2026 (commit b6c46bd):

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190):
  `R_TIDYCMD=/opt/homebrew/bin/tidy make check-cran`, with HTML Tidy 5.8.0:
  0 errors, 0 warnings, 1 NOTE (`New submission`). All 890 assertions passed;
  examples, all five vignette rebuilds, and PDF/HTML manuals passed.
  An earlier run selected the system's older Tidy and reported an additional
  HTML-validation NOTE; selecting the existing modern executable resolved it.
- `make -o build check-minimal` checked the same archive with dependency-only
  settings: Status OK, 845 assertions passed, three magick tests and one Shiny
  test skipped. This check does not rebuild vignettes.
- Preparation/color/camera/layer probes confirm rgl is not loaded. All 18
  explicit exports have help and one catalog row; 2 S3 print methods are
  documented through their object workflows.
- `make -o build audit-distribution` installs the exact archive and checks
  overview/index discovery, all five guides, their help links, local resources,
  byte counts, and source exclusions. Negative fixtures detect a missing
  overview entry, broken anchor, and missing asset.
- GitHub Actions run 35034646370 passed all six package jobs: Linux R-release,
  R-devel and R 4.1, Windows R-release and R-devel, and macOS R-release. Its
  browser job passed Chromium 151 and Firefox 153 controls, exports, GIF scale
  comparisons, and Shiny rerender/focus checks. These are browser checks, not
  a screen-reader or accessibility-conformance certification.

Installed size is INFO on this R version: 5.8 MB total, including 4.9 MB of
`doc`. Installed documentation totals 5,113,210 bytes (4.876 MiB), including
R's generated vignette index. Guides retain local/embedded resources and do
not need remote assets to render essential examples. Large retinal fitting
and media-generation tasks remain outside normal checks.

Shiny is an optional suggested dependency for reactive-context tests. Ordinary
preparation and rendering do not require it. The optional grip workflow remains
guarded, and no upstream retinal analysis was rerun. Win-builder has not been
rerun for these contents. No submission or external checking-service upload
was performed here.

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
