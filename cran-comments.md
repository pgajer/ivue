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

## Notes

The local incoming check reports only `New submission`. PDF and HTML manual
checks and vignette rebuilding passed. This is a new package with no CRAN
reverse dependencies. Its migrated development consumers were tested locally.

## Internal Audit Gate — Not Ready for Submission

An independent audit reproduced lost geometry opacity in the current archive:
even alpha = 0 draws opaque points and spheres, while legends show the requested
opacity. Edge and label color alpha is also lost. Smaller scale/input/legend
findings and reproduction scripts are in
tools/audits/ivue-0.1.0-independent-audit.md.

Do not upload the current archive or use this draft comment. Correct the
rendering defect, resolve or explicitly disposition the remaining audit findings,
check a replacement archive, and then replace this internal gate with the final
factual submission narrative. Clean check logs do not resolve the audit findings.
