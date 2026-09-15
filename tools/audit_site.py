"""Check local links/resources in the generated site, including installed help."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/site').resolve()
class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.refs, self.ids = [], set()
        self.feed(path.read_text())
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if 'name' in attrs and tag == 'a':
            self.ids.add(attrs['name'])
        for key in ('href', 'src', 'poster'):
            if key in attrs:
                self.refs.append((attrs[key], key != 'href' or tag == 'link'))
pages = {p.resolve(): Page(p) for p in root.rglob('*.html')}
errors = []
for path, page in pages.items():
    for ref, resource in page.refs:
        url = urlsplit(ref)
        if url.scheme or url.netloc:
            if resource and url.scheme != 'data':
                errors.append(f'{path.relative_to(root)}: external resource {ref}')
            continue
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        if target.is_dir():
            target /= 'index.html'
        if not target.is_relative_to(root) or not target.exists():
            errors.append(f'{path.relative_to(root)}: missing/outside-site {ref}')
        elif target in pages and url.fragment and unquote(url.fragment) not in pages[target].ids:
            errors.append(f'{path.relative_to(root)}: missing anchor {ref}')
assert not errors, '\n'.join(errors)
print(f'PASS: {len(pages)} site pages, local links, anchors, images and stylesheets.')
