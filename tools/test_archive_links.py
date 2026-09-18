"""Exercise the archive link audit with real Markdown and tarball fixtures."""
from contextlib import redirect_stdout
from pathlib import Path
from tempfile import TemporaryDirectory
import io
import tarfile
from audit_archive_links import audit


def archive(path, readme):
    files = {'pkg/DESCRIPTION': 'Package: pkg\nVersion: 0.1.0\n',
             'pkg/README.md': readme,
             'pkg/guide.md': '# Example\n',
             'pkg/figures/a plot.png': 'image fixture',
             'pkg/inst/extdata/README.md': '[Guide](../../guide.md#example)',
             'pkg/inst/doc/guide.html': '<a href="../html/generated.html">Help</a>'}
    with tarfile.open(path, 'w:gz') as tar:
        for name, text in files.items():
            data = text.encode('utf-8')
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))


with TemporaryDirectory(prefix='ivue-link-fixtures-') as tmp:
    path = Path(tmp) / 'pkg.tar.gz'
    valid = '''# Package
[Guide](guide.md#example)
![Plot](figures/a%20plot.png)
[Static][poster]

[poster]: figures/a%20plot.png

<img src="figures/a%20plot.png">
<a href="guide.md#example">Guide</a>
[Web](https://example.org/guide)
![Remote](https://example.org/plot.png)
`[Not a link](absent.png)`
<!-- <img src="absent.png"> -->
```
[Not a link](absent.png)
```
'''
    archive(path, valid)
    with redirect_stdout(io.StringIO()):
        audit(path)
    cases = [('[Static](man/figures/absent.png)', 'missing man/figures/absent.png'),
             ('![Image](absent.png)', 'missing absent.png'),
             ('[Static][p]\n\n[p]: absent.png', 'missing absent.png'),
             ('<img src="absent.png">', 'missing absent.png'),
             ('<script src="absent.js"></script>', 'missing absent.js'),
             ('<link rel="stylesheet" href="absent.css">', 'missing absent.css'),
             ('<a href="absent.html">Guide</a>', 'missing absent.html'),
             ('[Case](Guide.md)', 'missing Guide.md'),
             ('[Anchor](guide.md#absent)', 'missing anchor'),
             ('[Outside](../outside.md)', 'missing ../outside.md'),
             ('[Local](file:///tmp/plot.png)', 'machine-local URI'),
             ('[Local](/tmp/plot.png)', 'machine-local URI')]
    for readme, expected in cases:
        archive(path, readme)
        try:
            audit(path)
        except AssertionError as error:
            assert expected in str(error), str(error)
        else:
            raise AssertionError(f'Audit missed {expected}')
print(f'PASS: valid archive and {len(cases)} missing-file/URI/anchor fixtures.')
