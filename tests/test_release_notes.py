from pathlib import Path
import importlib.util

spec = importlib.util.spec_from_file_location('notes', 'tools/release_notes.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
paths = list(Path('release-notes').glob('v*.md'))
assert paths, 'No authored release notes'
for path in paths:
    module.validate_notes(path.stem[1:])
toc = Path('Cuniel_plus/Cuniel_plus.toc').read_text(encoding='utf-8')
version = next(line.split(':', 1)[1].strip() for line in toc.splitlines() if line.startswith('## Version:'))
module.validate_notes(version)
readme = Path('README.md').read_text(encoding='utf-8')
current = readme.split('## 本次更新', 1)[1].split('\n## ', 1)[0]
assert version in current and '12.1.5' in current and '70448' in current
assert '120105' in toc and 'release-notes/v' + version + '.md' in readme
print('PASS: every release has versioned authored notes; current README names addon and installed client build')
