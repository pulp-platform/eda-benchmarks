# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import re
import shutil
import subprocess
import sys

import yaml

here = Path(__file__).resolve().parent
source, toolchain = map(Path, sys.argv[1:])
build, data = source, here / 'data/redmule_tb'
cases = yaml.safe_load((source / 'scripts/regression.yml').read_text())['redmule_regression']
prepared = []
for name, case in cases.items():
    match = re.fullmatch(r'M(\d+)_N(\d+)_K(\d+)', name)
    if match is None:
        raise ValueError(f'Unrecognized upstream case: {name}')
    m, n, k = match.groups()
    golden = case['command'].split(' && ')[0]
    if golden != f'make golden M={m} N={n} K={k}':
        raise ValueError(f'Unrecognized upstream generator: {golden}')
    shape = f'gemm_FP16_{m}x{n}x{k}'
    dims = [f'M={m}', f'N={n}', f'K={k}']
    subprocess.run(['make', '-C', str(build / 'golden-model'), 'gemm', *dims,
                    f'SW={build}/sw/inc/{shape}', f'PENV={here}/.venv'], check=True)
    subprocess.run(['make', '-C', str(build), '-B', 'sw-build', *dims,
                    'REDMULE_COMPLEX=0', 'XTEN=imc_zicsr',
                    f'CC={toolchain}/bin/riscv32-unknown-elf-gcc',
                    f'LD={toolchain}/bin/riscv32-unknown-elf-gcc',
                    f'OBJDUMP={toolchain}/bin/riscv32-unknown-elf-objdump',
                    f'OBJCOPY={toolchain}/bin/riscv32-unknown-elf-objcopy',
                    f'PYTHON={here}/.venv/bin/python'], check=True)
    destination = data / name
    destination.mkdir(parents=True, exist_ok=True)
    for kind in ('instr', 'data'):
        shutil.copy2(build / 'sw/build' / shape / f'stim_{kind}.txt', destination)
    (destination / 'run.args').write_text(''.join(
        f'+STIM_{kind.upper()}=${{DATA_DIR}}/{name}/stim_{kind}.txt\n'
        for kind in ('instr', 'data')))
    prepared.append(name)
(data / 'testcases.txt').write_text(''.join(f'{name}\n' for name in prepared))
print(f'Prepared {len(prepared)} RedMulE regression cases')
