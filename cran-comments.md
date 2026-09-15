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

Current candidate checked September 14, 2026:

- macOS arm64, R-devel 4.7.0 (2026-06-24 r90190):
  `make check-cran` with HTML Tidy 5.8.0, 0 errors, 0 warnings,
  1 NOTE (`New submission`). All 729 assertions passed; examples,
  all five vignette rebuilds, and PDF/HTML manuals passed.
- `make check-minimal -o build` checked the same archive with the
  repository's dependency-only settings: Status OK, 710 assertions passed,
  two magick tests skipped. This target does not rebuild vignettes.
- Separate preparation/color/camera/layer probes confirmed that rgl was not
  loaded. All 18 exported functions have help and exactly one function-guide
  catalog row; no S3 methods are registered.
- The installed vignette index includes all five HTML guides and their
  sources. Their local links and embedded resources were checked. Browser
  rendering, rotation, colors/legends, geometric layers, playback controls,
  and both self-contained and directory-based HTML exports were inspected
  in the Codex in-app browser on macOS. A small GIF export also passed.

Installed size is INFO on this R version: 5.4 MB total, including 4.6 MB of
`doc`. The vignette files total 4,733,573 bytes before R adds its index;
installed `doc` totals 4,736,844 bytes. The guides are self-contained HTML;
no remote resources are needed to render their examples. The existing
animation vignette now retains 24 layout frames and uses smaller illustrative
grids, and checks a three-frame GIF without embedding a large animation asset.

The optional grip integration was exercised with local grip 0.1.2;
the two functions used by the existing vignette are exported by CRAN grip
0.2.0. All declared external dependencies are available on CRAN. The two new
guides introduce no dependencies.

Earlier source passed Linux, Windows, and macOS CI jobs, including R 4.1.3.
Those results do not validate this revised candidate. New Windows/Linux,
R-release/minimum-R, and Win-builder results remain to be collected before
release coordination. No submission or service upload was performed here.

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
