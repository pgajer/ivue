## Submission

First submission of ivue 0.1.0. There are no CRAN reverse dependencies.

## Package Scope

Interactive 3D point and embedded-graph visualization with reusable color
scales and geometric layers. The optional rgl backend is loaded only when
rendering; color mapping and graph preparation work without it. Ordinary
plotting uses null-device scenes without opening a native graphics window.
Examples and tests guard optional packages and do not launch a browser.

## Checks

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190): full `--as-cran` check,
  0 errors, 0 warnings, 1 NOTE. All 297 assertions, examples, vignette
  rebuilding, and PDF/HTML manuals passed.
- Linux R-release/devel/4.1.3, Windows R-release/devel, and macOS R-release:
  Status OK in CI (`--as-cran --no-manual`, incoming checks disabled).
- Dependency-only checks on Linux R-release and macOS R-devel: Status OK.

The source archive was built with R 4.6.1 on Linux and checked unchanged on
macOS R-devel. The only NOTE is `New submission`.
