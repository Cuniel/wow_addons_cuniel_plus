"""Validate authored release notes; optionally backfill existing GitHub releases."""
from pathlib import Path
import argparse
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def validate_notes(version):
    path = ROOT / 'release-notes' / ('v' + version + '.md')
    body = path.read_text(encoding='utf-8')
    required = ['Cuniel_plus ' + version, '适用版本', '本次更新', '安装']
    if any(term not in body for term in required):
        raise ValueError('Release notes missing version, compatibility, changes, or installation: ' + str(path))
    changes = body.split('## 本次更新', 1)[1].split('\n## ', 1)[0]
    if not any(line.startswith('- ') for line in changes.splitlines()):
        raise ValueError('Release notes require concrete change bullets: ' + str(path))
    return path, body


def backfill():
    raw = subprocess.check_output(['gh', 'release', 'list', '--limit', '100', '--json', 'tagName'], text=True, encoding='utf-8')
    for release in json.loads(raw):
        tag = release['tagName']
        path = ROOT / 'release-notes' / (tag + '.md')
        if not path.is_file():
            continue
        validate_notes(tag.removeprefix('v'))
        current = json.loads(subprocess.check_output(['gh', 'release', 'view', tag, '--json', 'body'], text=True, encoding='utf-8'))
        if current['body'].strip() != path.read_text(encoding='utf-8').strip():
            subprocess.run(['gh', 'release', 'edit', tag, '--notes-file', str(path)], check=True)
            print('Updated release notes: ' + tag)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--backfill', action='store_true')
    args = parser.parse_args()
    toc = (ROOT / 'Cuniel_plus/Cuniel_plus.toc').read_text(encoding='utf-8')
    version = next(line.split(':', 1)[1].strip() for line in toc.splitlines() if line.startswith('## Version:'))
    validate_notes(version)
    print('Validated release notes for ' + version)
    if args.backfill:
        backfill()
