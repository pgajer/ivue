"""Check local documentation links against the files actually in an R tarball.

Pandoc parses Markdown links, images, reference links, and embedded HTML.
Installed vignette HTML is checked separately by audit_vignette_html.py because
its help links resolve only after R has generated the installed help directory.
This check is offline; external HTTP(S) URLs need a separate network check.
"""
from html.parser import HTMLParser
from pathlib import PurePosixPath
from urllib.parse import unquote, urlsplit
import json
import posixpath
import subprocess
import sys
import tarfile


class HTMLLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        keys = ('href', 'src', 'poster') + (('data',) if tag == 'object' else ())
        for key in keys:
            if attrs.get(key):
                self.refs.append(attrs[key])
        if attrs.get('id'):
            self.ids.add(attrs['id'])
        if tag == 'a' and attrs.get('name'):
            self.ids.add(attrs['name'])


def document_links(text, markdown=True):
    html = HTMLLinks()
    refs, ids = [], set()
    if markdown:
        parsed = subprocess.run(['pandoc', '--from=markdown', '--to=json'],
                                input=text, text=True, capture_output=True, check=True)

        def walk(node):
            if isinstance(node, dict):
                kind, content = node.get('t'), node.get('c')
                if kind in ('Link', 'Image'):
                    refs.append(content[-1][0])
                elif kind == 'Header':
                    ids.add(content[1][0])
                elif kind in ('Div', 'Span'):
                    ids.add(content[0][0])
                elif kind in ('RawInline', 'RawBlock') and content[0] == 'html':
                    html.feed(content[1])
                for value in node.values():
                    walk(value)
            elif isinstance(node, list):
                for value in node:
                    walk(value)

        walk(json.loads(parsed.stdout))
    else:
        html.feed(text)
    return refs + html.refs, ids | html.ids


def audit(archive):
    with tarfile.open(archive) as package:
        members = package.getmembers()
        names = {m.name.rstrip('/') for m in members}
        descriptions = [n for n in names if len(PurePosixPath(n).parts) == 2
                        and n.endswith('/DESCRIPTION')]
        if len(descriptions) != 1:
            raise AssertionError('Expected one R package root with DESCRIPTION')
        root = str(PurePosixPath(descriptions[0]).parent)
        pages = {}
        for member in members:
            path = PurePosixPath(member.name)
            relative = path.relative_to(root)
            if (member.isfile() and path.suffix.lower() in ('.md', '.html', '.htm')
                    and relative.parts[:2] != ('inst', 'doc')):
                text = package.extractfile(member).read().decode('utf-8')
                pages[str(path)] = document_links(text, path.suffix.lower() == '.md')

    errors, local, external = [], 0, 0
    for page, (refs, _) in pages.items():
        for ref in refs:
            url = urlsplit(ref)
            if url.scheme == 'file' or (url.path.startswith('/') and not url.netloc):
                errors.append(f'{page}: machine-local URI {ref}')
                continue
            if url.scheme or url.netloc:
                external += 1
                continue
            local += 1
            target = posixpath.normpath(posixpath.join(posixpath.dirname(page),
                       unquote(url.path))) if url.path else page
            if target not in names:
                errors.append(f'{page}: missing {ref}')
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target][1]:
                errors.append(f'{page}: missing anchor {ref}')
    if errors:
        raise AssertionError('\n'.join(errors))
    print(f'PASS: {len(pages)} archive documents, {local} local references; '
          f'{external} external references left to the network URL check.')


if __name__ == '__main__':
    audit(sys.argv[1])
