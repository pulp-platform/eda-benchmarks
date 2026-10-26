#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import json
import pathlib
import sys
import os
import shutil

source, destination, name, workspace, output, settings = sys.argv[1:]
workspace, output, settings = map(pathlib.Path, (workspace, output, settings))
includes, files, defines = [], [], {}
for line in pathlib.Path(source).read_text().splitlines():
    line = line.strip()
    if not line or line.startswith('//'):
        continue
    if line.startswith('+incdir+'):
        includes.append(line.removeprefix('+incdir+'))
    elif line.startswith('+define+'):
        key, _, value = line.removeprefix('+define+').partition('=')
        defines[key] = value or None
    elif line.startswith(('+', '-')):
        raise ValueError(f'Expected a flat source list, got {line!r}')
    else:
        files.append(line)
extensions = {'.v', '.sv', '.vh', '.svh', '.h', '.hh', '.hpp', '.c', '.cc', '.cpp'}

def copy_path(value, directory=False):
    source = pathlib.Path(value).resolve()
    if not source.is_relative_to(workspace):
        return str(source)
    target = output / source.relative_to(workspace)
    if directory:
        target.mkdir(parents=True, exist_ok=True)
        for path in source.rglob('*'):
            if path.is_file() and '.git' not in path.parts and path.suffix in extensions:
                destination = target / path.relative_to(source)
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, destination)
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    return str(target)

includes = [copy_path(path, True) for path in includes]
files = [copy_path(path) for path in files]
for filename, directory in (('cpp_files.txt', False), ('cpp_include_dirs.txt', True)):
    metadata = settings / filename
    if not metadata.exists():
        continue
    for line in metadata.read_text().splitlines():
        if not line:
            continue
        path = (settings.parent.parent / line).resolve()
        if path.is_relative_to(output):
            path = workspace / path.relative_to(output)
        copy_path(path, directory)

for directory, subdirs, names in os.walk(workspace):
    subdirs[:] = [name for name in subdirs if name != '.git']
    relative = pathlib.Path(directory).relative_to(workspace)
    if not (output / relative).is_dir() and 'LICENSES' not in relative.parts:
        continue
    for filename in names:
        if filename.lower().startswith(('license', 'copying', 'notice', 'copyright', 'readme.license')) or 'LICENSES' in relative.parts:
            target = output / relative / filename
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(pathlib.Path(directory) / filename, target)

pathlib.Path(destination).parent.mkdir(parents=True, exist_ok=True)
pathlib.Path(destination).write_text(json.dumps({
    'package': {'name': name},
    'sources': [{'include_dirs': list(dict.fromkeys(includes)),
                 'defines': defines, 'files': list(dict.fromkeys(files))}],
}, indent=2) + '\n')
