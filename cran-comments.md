## Submission

Resubmission of ivue 0.1.0 addressing the September 18, 2026 report of invalid
README file URIs. The September 17 session-settings fixes are retained.
There are no CRAN reverse dependencies.

## Changes Addressing Review

- Replaced the README's two relative static-image links,
  `man/figures/readme-retinal-sknn.png` and
  `man/figures/readme-retinal-phate-comparison.png`, with verified HTTPS
  URLs pinned to the same Git commit as the existing animations. The images
  exist in the repository but are intentionally excluded from the source
  package. README figures remain online; vignette figures remain bundled.
- A new build-time check parses Markdown/HTML links in the actual tarball,
  reproduces both failures in the previous submission, and passes for this
  candidate. Twelve negative fixtures cover missing linked files, images,
  scripts, stylesheets, anchors, and machine-local paths. Installed guide
  resources, help links, retinal data, and widget assets also pass inspection.
- The September 17 fixes remain unchanged: both GIF helpers immediately
  register graphical-parameter restoration before drawing, and the temporary
  `rgl.useNULL` option has immediate restoration. Success/error regression
  tests still pass. Functions, examples, and vignettes do not call `setwd()`.

## Checks

Candidate package contents checked September 18, 2026 (commit fb9074c):

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190):
  `R_TIDYCMD=/opt/homebrew/bin/tidy make check-cran`, with HTML Tidy 5.8.0:
  0 errors, 0 warnings, 1 NOTE (`New submission`). All 920 assertions passed;
  examples, all five vignette rebuilds, and PDF/HTML manuals passed.
- `make -o build check-minimal` checked the same archive with dependency-only
  settings: Status OK, 861 assertions passed, four magick tests and one Shiny
  test skipped. This check does not rebuild vignettes.
- `make -o build audit-distribution` installs the exact archive and checks
  overview/index discovery, all five guides, their help links, local resources,
  byte counts, and source exclusions. Negative fixtures detect a missing
  overview entry, broken anchor, and missing asset.
- `urlchecker::url_check()` passes on the exact archive, including both new
  static-image URLs. The separate offline archive check covers local file
  references, which the online URL check alone did not detect.
- GitHub Actions run 35378299264 passed all six package jobs (Linux
  R-release/R-devel/R 4.1, Windows R-release/R-devel, macOS R-release) and
  the Chromium/Firefox browser checks. Five package jobs report Status OK;
  R 4.1 reports only the installed-size NOTE (5.8 MB total, 4.9 MB doc).
  The Linux R-release job also passed the new archive-link and asset checks.

Installed size is INFO on this R version: 5.8 MB total, including 4.9 MB of
`doc`. Installed documentation totals 5,113,197 bytes (4.876 MiB), including
R's generated vignette index. Guides retain local/embedded resources and do
not need remote assets to render essential examples. Large retinal fitting
and media-generation tasks remain outside normal checks.

Examples guard optional dependencies and do not launch a browser or native
graphics window. The retinal case study uses bundled coordinates and static
posters; large upstream computations are not run during checks. No new
Win-builder upload was made; fresh Windows CI checks are listed above.

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
