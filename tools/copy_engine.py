#!/usr/bin/env python3
"""Copy only checked publication files; never copy Git history or release outputs."""
import json
import shutil
import sys
from pathlib import Path
from check_content import check, publication_files

src, dst = (Path(p).resolve() for p in sys.argv[1:3])
paths = list(publication_files(src))
fixtures = json.loads((src / 'tools/publish-fixtures.json').read_text())
errors, _ = check(src, paths, fixtures)
if errors:
    raise SystemExit('Source content check failed: ' + ', '.join(p for p, _ in errors))
for p in paths:
    target = dst / p.relative_to(src)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, target)
