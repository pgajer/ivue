## Submission

Update of ivue from 0.1.0 to 0.1.1.

This is a documentation update. It adds a worked comparison of exact and
projected coordinates, improves guide navigation and installation instructions,
and removes unavailable article links. The five installed guides share local
assets and use browser-native mathematical notation, retaining offline viewing
while reducing installed documentation to approximately 3.92 MiB.

R functions, exports, dependencies, widget code and bundled retinal data are
unchanged from CRAN 0.1.0. There is no maintainer or license change. The prior
session-state and README-link corrections are retained.

## Checks

- Full check of the submission archive on macOS arm64, R-devel 4.7.0
  (2026-06-24 r90190), clean Makevars and HTML Tidy 5.8.0: 0 errors,
  0 warnings, 0 notes. All 920 assertions, examples, five vignette rebuilds
  and PDF/HTML manual checks pass.
- Linux, macOS arm64 and Windows R-release 4.6.2; Linux and Windows R-devel 4.7.0
  (2026-11-05 r90840): 0 errors, 0 warnings, 0 notes, with 920 assertions
  on each platform. These CI checks omit the manual, covered locally above.
- Reduced-dependency check of the submission archive: 0 errors, 0 warnings,
  0 notes; 861 assertions pass, with four magick tests and one Shiny test skipped.
- R 4.1.3, checking the submission archive with supported optional dependencies:
  0 errors, 0 warnings, 1 expected note listing unavailable suggested packages
  (grip, magick, shiny, geometry and igraph). There are 843 passing assertions
  and nine expected skips. Current-R jobs provide full optional coverage;
  this compatibility check uses prebuilt guides and omits manual rebuilding.
- Installed help, guide links, local resources and source archive audits pass.
  All five guides render offline at desktop and mobile widths without external
  requests; interactive widgets render and rotate successfully. Chromium widget and
  animation checks, plus Chromium/Firefox camera, GIF and Shiny checks, pass.

The current CRAN catalog lists no reverse dependencies. Project-local dgraphs
and grip checks pass. Failures in gflow, gflowx and gflowui reproduce with the
same check categories and assertion counts using CRAN ivue 0.1.0; they are
unrelated to this documentation update. No API has changed.
