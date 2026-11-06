## Submission

Update of ivue from 0.1.0 to 0.1.1.

This is a documentation update. It adds a worked comparison of exact and
projected coordinates, improves guide navigation and installation instructions,
and removes unavailable article links. The five installed guides share local
assets and use browser-native mathematical notation, retaining offline viewing
while reducing documentation size to approximately 3.91 MiB.

R functions, exports, dependencies, widget code and bundled retinal data are
unchanged from CRAN 0.1.0. There is no maintainer or license change. The prior
session-state and README-link corrections are retained.

## Checks

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190), with clean Makevars and
  HTML Tidy 5.8.0: 0 errors, 0 warnings, 0 notes. All 920 assertions, examples,
  five vignette rebuilds and PDF/HTML manual checks pass.
- Reduced-dependency check of the same archive: 0 errors, 0 warnings, 0 notes;
  861 assertions pass, with four magick tests and one Shiny test skipped.
- Installed help, guide links, local resources, source exclusions and offline
  browser rendering pass. All five guides render at desktop and mobile widths
  without external resource requests.

The current CRAN catalog lists no reverse dependencies. No API has changed.
