# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import os
import shutil
import subprocess
import sys
import yaml

here = Path(__file__).resolve().parent
source, toolchain = map(Path, sys.argv[1:])
build, data = source, here / 'data/opope_tb'
ci = yaml.safe_load((source / '.gitlab/.gitlab-ci.yml').read_text())
cases = []
env = os.environ.copy()
env['PATH'] = str(toolchain / 'riscv32-unknown-elf/bin') + ':' + env['PATH']
for job in ('hwpe-test', 'complex-test'):
    assert ci[job]['variables']['COMPLEX_MODE'] == '0'
    for case in ci[job]['parallel']['matrix']:
        assert case['OP'] == 'gemm' and case['FMT'] in ('FP16', 'FP8FP16')
        m, n, k = (int(case[d]) for d in ('M', 'N', 'K'))
        name = f"{case['FMT']}_M{m}_N{n}_K{k}"
        subprocess.run(['make', '-C', str(build / 'golden-model'), 'gemm',
                        f'SW={build}/sw/inc', f'M={m}', f'N={n}', f'K={k}',
                        f"fp_fmt={case['FMT']}", 'transpose=1',
                        f'PYTHON={here}/.venv/bin/python'], check=True)
        subprocess.run(['make', '-C', str(build), '-B', 'sw-build', 'target=vsim',
                        'OPOPE_COMPLEX=0',
                        f'CC={toolchain}/bin/riscv32-unknown-elf-gcc',
                        f'OBJDUMP={toolchain}/bin/riscv32-unknown-elf-objdump',
                        f'PYTHON={here}/.venv/bin/python'], env=env, check=True)
        dest = data / name
        dest.mkdir(exist_ok=True)
        for kind in ('instr', 'data'):
            shutil.copy2(build / f'sw/build/stim_{kind}.txt', dest)
        (dest / 'run.args').write_text(''.join(
            f'+STIM_{kind.upper()}=${{DATA_DIR}}/{name}/stim_{kind}.txt\n'
            for kind in ('instr', 'data')))
        cases.append(name)
(data / 'testcases.txt').write_text(''.join(f'{name}\n' for name in cases))
print(f'Prepared {len(cases)} OPOPE cases')
