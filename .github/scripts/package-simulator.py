#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Archive a target's executables and accompanying license material for CI."""
import argparse
import hashlib
from pathlib import Path
import shutil
import tarfile
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('package', type=Path)
parser.add_argument('target')
parser.add_argument('package_archive', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
package = args.package.resolve()
family, variant = args.target.split('.')
build = package / family / 'variants' / variant / 'build/verilator'
executables = sorted(p for p in build.glob('*/V*') if p.is_file() and p.stat().st_mode & 0o111)
if not executables:
    parser.error(f'No simulator executables found in {build}')

with tempfile.TemporaryDirectory() as temporary:
    metadata = Path(temporary)
    with args.package_archive.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    (metadata / 'package.sha256').write_text(digest + '\n')
    (metadata / 'README.txt').write_text(
        f'Prebuilt simulators for {args.target}.\n'
        'IEEE VPI/DPI interface headers retain their separate notices.\n'
        'Component license and notice files retain their package-relative paths.\n')
    shutil.copyfile(package / 'tools/licenses/verilator/LICENSE.IEEE-1800',
                    metadata / 'LICENSE.IEEE-1800')
    if family == 'ibex':
        notices = package / 'tools/licenses/spike-aadf648'
        shutil.copytree(notices, metadata / 'spike')
    with tarfile.open(args.output, 'w:gz', dereference=True) as archive:
        for path in executables:
            archive.add(path, arcname=str(path.relative_to(package)), recursive=False)
        for path in sorted((package / family).rglob('*')):
            if path.is_file() and (path.name.upper().startswith(('LICENSE', 'NOTICE', 'COPYING', 'COPYRIGHT'))
                                   or 'LICENSES' in path.parts):
                archive.add(path, arcname=str(path.relative_to(package)), recursive=False)
        for path in package.glob('LICENSE*'):
            if path.is_file():
                archive.add(path, arcname=path.name, recursive=False)
        archive.add(metadata, arcname='ci-simulator')
