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

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190): full `--as-cran` check,
  0 errors, 0 warnings, 1 NOTE. All 729 assertions, examples, vignette
  rebuilding, and PDF/HTML manuals passed with HTML Tidy 5.
- Linux R-release/devel, Windows R-release/devel, and macOS R-release:
  Status OK in CI (`--as-cran --no-manual`, incoming checks disabled).
  R-devel CI used September 8, 2026 r90509.
- Linux R 4.1.3: 0 errors, 0 warnings, 1 installed-size NOTE in CI.
  All six CI package jobs passed 729 assertions.
- Dependency-only checks on Linux R-release and macOS R-devel: Status OK.

The September 9 source archive was checked unchanged on macOS R-devel.
Its only NOTE is `New submission`. Installed size is reported as INFO on
current R (6.1 MB total, including 5.3 MB of documentation); R 4.1.3 reports
the size as a NOTE (6.0 MB total, including 5.2 MB of documentation).

The retinal case-study vignette uses bundled coordinates and static posters;
its large rendering and upstream data-processing recipes are not evaluated
during checking. Other vignettes and tests exercise the rendering functions.

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
