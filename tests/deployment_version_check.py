"""Check the deployment contract of a real Copier-rendered project."""
from pathlib import Path
import re
import sys

project = Path(sys.argv[1]).resolve()
workflows = project / '.github/workflows'
entry = workflows / 'startup.yml'
references = []
for path in sorted(workflows.glob('*.y*ml')):
    content = path.read_text()
    references += [(path, ref) for ref in re.findall(r'uses:\s*([\w.-]+/[\w.-]+/\.github/[^\s#]+)', content)
                   if '/.github/workflows/project' in ref or 'Deploy-your-Startup/deploy/' in ref]
    for local in re.findall(r'uses:\s*\./(\.github/workflows/[^\s#]+)', content):
        assert (project / local).is_file(), (path, local)
assert len(references) == 1, references
assert references[0][0] == entry, references
assert re.search(r'/project(?:-pages)?\.yml@[A-Za-z0-9][\w./-]*$', references[0][1]), references
for directory in (project / 'deployment', project / '.github'):
    assert not (directory / 'shared-roles.ref').exists()
    assert not (directory / 'shared-roles.sha256').exists()
print('One deployment reference; local callers resolve; no duplicate pin files')
