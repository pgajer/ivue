"""Negative fixtures: each mutation must be caught by the production audit."""
from pathlib import Path
from tempfile import TemporaryDirectory
from contextlib import redirect_stdout
import io
from audit_vignette_html import audit

with TemporaryDirectory(prefix='ivue-audit-fixture-') as tmp:
    root = Path(tmp)
    for i in range(5):
        (root / f'guide{i}.html').write_text('<h1 id="start">Guide</h1><a href="guide0.html#start">Start</a>')
    def check():
        with redirect_stdout(io.StringIO()):
            audit(root)
    check()
    for html, message in [('<a href="guide0.html#absent">Broken</a>', 'missing anchor'),
                          ('<img src="absent.png">', 'missing absent.png')]:
        page = root / 'guide4.html'
        original = page.read_text()
        page.write_text(html)
        try:
            check()
        except AssertionError as e:
            assert message in str(e), str(e)
        else:
            raise AssertionError(f'Audit missed {message}')
        page.write_text(original)
print('PASS: negative missing-resource and broken-anchor fixtures.')
