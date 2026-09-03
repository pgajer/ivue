## Submission Type

First submission of ivue 0.1.0. No prior CRAN feedback.

## Package Scope

Browser-based three-dimensional point and weighted-graph visualization using
rgl null-device scenes, reusable color scales, and geometric layers.
No native graphics device is opened by ordinary plotting. rgl is a suggested
backend loaded only at the rendering boundary; color mapping works without it.
igraph and Matrix are optional graph adapters. Examples and tests guard the
suggested packages and do not launch a browser or write outside temporary files.

## Test Environments

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190), full `--as-cran` check of the
  R-release-built submission archive: 0 errors, 0 warnings, 1 NOTE.
- Linux, Windows, and macOS R 4.6.1; Linux R-devel (2026-09-01 r90464), Windows
  R-devel (2026-09-02 r90474), and Linux R 4.1.3: Status OK in CI using
  `--as-cran --no-manual` with incoming checks disabled by the CI action.
- Dependency-only checks on Linux R-release and local macOS R-devel: Status OK.
- Initial Win-builder R-devel (2026-08-31 r90457 ucrt), Windows Server 2022 x64:
  0 errors, 0 warnings, 1 NOTE covering `New submission` and four invalid
  README file links. All 158 test assertions, examples, and manuals passed.
  The links now point to GitHub. The replacement archive passed local full
  and dependency-only checks and all seven CI jobs.
- Repeat Win-builder R-devel (2026-08-31 r90457 ucrt), checked at
  2026-09-03 15:49:06 UTC: 0 errors, 0 warnings, 1 NOTE (`New submission`).
  The README-link findings are resolved; examples, tests, vignette rebuilding,
  and PDF/HTML manuals passed. The result log has been reviewed and preserved.
- Corrected-candidate CI at commit `ab4a857`: all seven jobs passed on Linux
  R-release/devel/4.1.3, Windows R-release/devel, macOS R-release, and Chromium.
  Each package job passed 273 assertions. The browser job passed the general
  interaction suite and all 38 geometry-opacity cases.
- macOS arm64, local R-devel 4.7.0: full `--as-cran` check of the exact
  R-release-built corrected archive: 0 errors, 0 warnings, 1 NOTE (`New
  submission`). Dependency-only check: Status OK.
- Win-builder R-devel (2026-08-31 r90457 ucrt), checked at 2026-09-03
  16:49:06 UTC: 0 errors, 0 warnings, 1 NOTE (`New submission`). Tests,
  vignette rebuilding, and PDF/HTML manuals passed.

## Notes

The local incoming check reports only `New submission`. PDF and HTML manual
checks and vignette rebuilding passed. This is a new package with no CRAN
reverse dependencies. Its migrated development consumers were tested locally.

## Independent Audit Correction

The independent audit of the previous archive found lost geometry opacity and
five scale/input/legend issues. The corrected candidate passes the unchanged 14
R probes and unchanged browser probe. New browser tests also cover points,
spheres, scales, missing colors, highlights, edges, paths, and labels at desktop
and mobile widths. The categorical API is now `plot3D.groups`; `prepare.graph`
exposes normalized graph data without rgl; and named annotations align by exact
vertex ID. Point identification and camera reset are recorded as post-CRAN work.

This draft remains on hold until the implementation is independently reviewed.
The older archives and their Win-builder results must not be used for submission.
