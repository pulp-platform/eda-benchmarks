#!/usr/bin/env python3
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import json
import os
import subprocess
import sys


def main():
    case_dir = Path(sys.argv[1]).resolve()
    simulator, *args = sys.argv[2:]
    simulator = str(Path(simulator).absolute())
    log_dir = Path.cwd()
    work_dir = Path(simulator).parent / case_dir.name
    work_dir.mkdir(parents=True, exist_ok=True)
    if not (case_dir / 'verify.args').is_file():
        os.chdir(work_dir)
        os.execv(simulator, [simulator, *args])
    args = [arg for arg in args if not arg.startswith('+PRELOAD=')]
    launcher = case_dir.parent / 'simulator.py'
    env = dict(os.environ, PYTHONPATH=str(case_dir.parent / 'python'),
               SNITCH_SIMULATOR_COMMAND=json.dumps([simulator, *args]))
    substitutions = {'${sim_bin}': str(launcher), '${elf}': str(case_dir / 'firmware.elf')}
    verify_args = [substitutions.get(arg, arg)
                   for arg in (case_dir / 'verify.args').read_text().splitlines()]
    result = subprocess.run([
        sys.executable, str(case_dir / 'verify.py'),
        *verify_args,
        '--log', str(log_dir / 'simulator.log'), '--dump-results',
    ], env=env, cwd=work_dir)
    results = work_dir / 'results.csv'
    if results.exists():
        results.replace(log_dir / 'results.csv')
    log_path = log_dir / 'simulator.log'
    log = log_path.read_text() if log_path.exists() else ''
    for line in log.splitlines():
        if line != 'TEST PASSED':
            print(line)
    if result.returncode or 'TEST PASSED' not in log.splitlines():
        return 1
    print('TEST PASSED')
    return 0


if __name__ == '__main__':
    sys.exit(main())
