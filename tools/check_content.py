#!/usr/bin/env python3
"""Check publication contents, not legal clearance. Never print file contents."""
import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OMIT_DIRS = {'.git', 'dist', 'build', '.build', '.venv', '__pycache__', '.pytest_cache', 'node_modules'}
FORBIDDEN_SUFFIXES = {'.nup', '.nsp', '.nsz', '.xci', '.xcz', '.nca', '.nso', '.nro', '.kip', '.keys', '.sav', '.ipa', '.metallib', '.mtl4a', '.spv', '.bfres', '.bntx', '.bnsh', '.bfsha', '.bfsar', '.bfstm', '.img'}
FORBIDDEN_DIRS = {'romfs', 'exefs', 'romfs_overlay', 'romfs_overlay_mac', 'save', 'save.work', 'save-backups', 'pso_archive'}

def publication_files(root):
    import os
    for current, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in OMIT_DIRS)
        for name in sorted(files):
            yield Path(current) / name

def check(root, paths, fixtures):
    errors = []
    count = total = synthetic = 0
    for p in paths:
        rel = p.relative_to(root).as_posix()
        parts = Path(rel).parts
        if p.is_symlink():
            errors.append((rel, 'symlink: inspect its target before publication'))
            continue
        if not p.is_file():
            continue
        count += 1
        total += p.stat().st_size
        # The upstream parser tests contain three manufactured, truncated headers.
        # Only the exact pinned bytes are exempt, never arbitrary files in corpus/.
        if rel in fixtures and hashlib.sha256(p.read_bytes()).hexdigest() == fixtures[rel]:
            synthetic += 1
            continue
        if any(part.lower() in FORBIDDEN_DIRS or part.lower().endswith('.app') for part in parts):
            errors.append((rel, 'private game/output directory'))
            continue
        if p.suffix.lower() in FORBIDDEN_SUFFIXES or p.name.lower() in {'prod.keys', 'title.keys', 'env.txt'}:
            errors.append((rel, 'game data, keys, private settings or generated game shader'))
            continue
        with p.open('rb') as f:
            magic = f.read(4)
        if magic in {b'NSO0', b'NRO0', b'KIP1'}:
            errors.append((rel, 'extracted executable header, including extensionless files'))
        if p.stat().st_size >= 100 * 1024 * 1024:
            errors.append((rel, 'file exceeds GitHub’s normal 100 MiB file limit'))
    return errors, {'files': count, 'bytes': total, 'pinned_synthetic_fixtures': synthetic}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--root', type=Path, default=ROOT)
    ap.add_argument('--staged', action='store_true', help='Also inspect every staged path, including forcibly added ignored files')
    args = ap.parse_args()
    root = args.root.resolve()
    fixtures = json.loads((ROOT / 'tools/publish-fixtures.json').read_text())
    paths = list(publication_files(root))
    errors, report = check(root, paths, fixtures)
    if args.staged:
        result = subprocess.run(['git', '-C', str(root), 'diff', '--cached', '--name-only', '-z', '--diff-filter=ACMR'], capture_output=True, check=True)
        names = [p.decode() for p in result.stdout.split(b'\0') if p]
        # Read the index, not a potentially different working-tree version.
        # checkout-index writes only a temporary audit copy, never the real tree.
        with tempfile.TemporaryDirectory(prefix='greenkid-index-') as d:
            if names:
                subprocess.run(['git', '-C', str(root), 'checkout-index', '--stdin', '-z', '--prefix=' + d + '/'], input=result.stdout, check=True, capture_output=True)
                staged_errors, staged_report = check(Path(d), [Path(d) / n for n in names], fixtures)
                errors.extend((p, 'staged: ' + why) for p, why in staged_errors)
                report['staged_files_checked'] = staged_report['files']
    print(json.dumps({**report, 'passed': not errors, 'problems': errors}, indent=2))
    return bool(errors)

if __name__ == '__main__':
    sys.exit(main())
