"""Check built/installed vignette links and assets without network access.

Run: python3 tools/audit_vignette_html.py build/vignettes
External hyperlinks are citations; executable/image/style resources must be local
or embedded. This checks packaging, not browser execution.
"""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote
import re
import sys

class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.ids, self.refs, self.resources = set(), [], []
        self.source = path.read_text()
        self.feed(self.source)
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'a' and 'href' in attrs:
            self.refs.append(attrs['href'])
        for key in ('src', 'poster'):
            if key in attrs:
                self.resources.append(attrs[key])
        if tag == 'link' and 'href' in attrs:
            self.resources.append(attrs['href'])

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/vignettes').resolve()
# R generates index.html with help-server navigation outside the package tree;
# its vignette entries are checked through R's installed vignette index.
pages = {p.resolve(): Page(p) for p in root.glob('*.html') if p.name != 'index.html'}
assert len(pages) >= 5, 'Expected five installed vignettes'
errors = []
for path, page in pages.items():
    if re.search(r'/Users/|/Library/Frameworks/|file://', page.source):
        errors.append(f'{path.name}: absolute machine path')
    css = re.findall(r'url\([\s\'"]*([^\s\)\'"]+)', page.source)
    # JS source may contain url() expressions; only literal embedded/local CSS
    # assets have extensions and are actionable resource references here.
    css = [x for x in css if x.startswith('data:') or re.search(r'\.(woff2?|ttf|png|jpg|svg)(?:[?#]|$)', x)]
    for ref, resource in [(x, False) for x in page.refs] + [(x, True) for x in page.resources + css]:
        url = urlsplit(ref)
        if url.scheme == 'data':
            continue
        if url.scheme or url.netloc:
            if resource:
                errors.append(f'{path.name}: external resource {ref[:120]}')
            continue
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        if not target.exists():
            errors.append(f'{path.name}: missing {ref}')
        elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
            errors.append(f'{path.name}: missing anchor {ref}')
    print(f'{path.name}: {path.stat().st_size:,} bytes; {len(page.resources)} embedded/local resources')
assert not errors, '\n'.join(errors)
size = sum(p.stat().st_size for p in root.rglob('*') if p.is_file())
print(f'PASS: local files/anchors/resources. Documentation files: {size:,} bytes ({size / 2**20:.3f} MiB).')
