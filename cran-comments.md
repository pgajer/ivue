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
- Linux, Windows, and macOS R 4.6.1; Linux R-devel (2026-09-02 r90473), Windows
  R-devel (2026-09-02 r90474), and Linux R 4.1.3: Status OK in CI using
  `--as-cran --no-manual` with incoming checks disabled by the CI action.
- Dependency-only checks on Linux R-release and local macOS R-devel: Status OK.
- Win-builder R-devel: exact archive uploaded; result review pending.

## Notes

The local incoming check reports only `New submission`. PDF and HTML manual
checks and vignette rebuilding passed. This is a new package with no CRAN
reverse dependencies. Its migrated development consumers were tested locally.

Do not submit this comment until the pending Win-builder review is complete.
