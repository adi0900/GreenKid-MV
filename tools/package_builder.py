#!/usr/bin/env python3
"""Package the generic builder. This never imports a game folder or a game app."""
import argparse
import hashlib
import json
import plistlib
import shutil
import subprocess
import zipfile
from pathlib import Path
from check_content import ROOT, check, publication_files

def run(*args):
    subprocess.run([str(x) for x in args], check=True)

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--skip-execution-check', action='store_true', help='Cross-compile on an Intel CI host; still verify the bundle signature')
    args = ap.parse_args()
    paths = list(publication_files(ROOT))
    fixtures = json.loads((ROOT / 'tools/publish-fixtures.json').read_text())
    errors, report = check(ROOT, paths, fixtures)
    if errors:
        raise SystemExit(json.dumps(errors, indent=2))
    version = (ROOT / 'VERSION').read_text().strip()
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=True)
    app = dist / 'GreenKid-MV.app'
    if app.exists():
        raise SystemExit('dist/GreenKid-MV.app already exists. Keep the previous release and use a fresh output folder before packaging again.')
    contents = app / 'Contents'
    executable = contents / 'MacOS/GreenKid-MV'
    resources = contents / 'Resources'
    engine = resources / 'engine'
    executable.parent.mkdir(parents=True)
    docs = resources / 'Documentation'
    docs.mkdir(parents=True)
    print('Copying checked source and compiler tools; no game inputs are accepted.', flush=True)
    for p in paths:
        target = engine / p.relative_to(ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, target)
    for name in ('README.md', 'CREDITS.md', 'AUTHORS.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md'):
        shutil.copy2(ROOT / name, docs / name)
    run('xcrun', 'swiftc', '-swift-version', '5', '-O', '-target', 'arm64-apple-macos15.0', '-framework', 'AppKit', ROOT / 'launcher/mac/main.swift', '-o', executable)
    info = {
        'CFBundleName': 'GreenKid-MV', 'CFBundleDisplayName': 'GreenKid-MV',
        'CFBundleIdentifier': 'local.greenkidmv.builder', 'CFBundleExecutable': 'GreenKid-MV',
        'CFBundlePackageType': 'APPL', 'CFBundleShortVersionString': version.split('-')[0],
        'CFBundleVersion': '1', 'LSMinimumSystemVersion': '15.0',
        'NSHighResolutionCapable': True,
        'NSDownloadsFolderUsageDescription': 'Build a private local game from the dump folder you choose.',
        'NSDocumentsFolderUsageDescription': 'Build a private local game from the dump folder you choose.'
    }
    (contents / 'Info.plist').write_bytes(plistlib.dumps(info))
    (contents / 'PkgInfo').write_text('APPL????')
    run('codesign', '--force', '--sign', '-', app)
    run('codesign', '--verify', '--strict', app)
    if not args.skip_execution_check:
        run(executable, '--self-check')
    errors, bundled_report = check(engine, list(publication_files(engine)), fixtures)
    if errors:
        raise SystemExit('Bundled engine failed content check: ' + json.dumps(errors))
    archive = dist / f'GreenKid-MV-{version}-macOS-arm64.zip'
    run('ditto', '-c', '-k', '--norsrc', '--noextattr', '--noacl', '--keepParent', app, archive)  # no __MACOSX/ metadata entries
    source_zip = dist / f'GreenKid-MV-{version}-source.zip'
    with zipfile.ZipFile(source_zip, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p in paths:
            z.write(p, 'GreenKid-MV/' + p.relative_to(ROOT).as_posix())
    hashes = []
    for p in (archive, source_zip):
        digest = hashlib.file_digest(p.open('rb'), 'sha256').hexdigest()
        hashes.append(f'{digest}  {p.name}')
    (dist / 'SHA256SUMS.txt').write_text('\n'.join(hashes) + '\n')
    (dist / 'CONTENT-CHECK.json').write_text(json.dumps({'source': report, 'bundled_engine': bundled_report, 'upstream_revision': (ROOT / 'UPSTREAM-REVISION').read_text().strip(), 'game_assets_included': False}, indent=2) + '\n')
    print('Prepared game-free release files in ' + str(dist))

if __name__ == '__main__':
    main()
