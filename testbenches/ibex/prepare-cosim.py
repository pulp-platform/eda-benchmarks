# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import shutil
import sys
from bin_to_vmem import bin_to_vmem
here = Path(sys.argv[1])
base = here / 'build/cosim'
for variant in ('minimal', 'full'):
    dest = here / 'variants' / variant / 'data/ibex_cosim_tb'
    dest.mkdir(parents=True, exist_ok=True)
    for source in base.glob('LICENSE*'):
        shutil.copy2(source, dest)
    shutil.copy2(base / 'README.txt', dest)
    cases = ['coremark']
    if variant == 'full':
        cases += ['pmp_smoke_test', 'dit_test']
    for name in cases:
        case_dir = dest / name
        case_dir.mkdir(exist_ok=True)
        if name == 'coremark':
            shutil.copy2(base / 'firmware.txt', case_dir / 'firmware.txt')
        else:
            binary = here.parents[1] / 'deps/ibex/examples/sw/simple_system' / name / f'{name}.bin'
            bin_to_vmem(binary, case_dir / 'firmware.txt')
        (case_dir / 'run.args').write_text(
            f'--meminit=ram,${{DATA_DIR}}/{name}/firmware.txt,vmem\n')
    (dest / 'testcases.txt').write_text(''.join(f'{name}\n' for name in cases))
    with (dest / 'README.txt').open('a') as f:
        f.write('Programs: ' + ', '.join(cases) + '\n')
    (dest / 'README.md').write_text(
        '# Ibex co-simulation selection\n\n'
        'The full configuration excludes dummy_instr_test: SecureIbex dummy '
        'instructions combined with branch prediction reproduce upstream '
        'issue https://github.com/lowRISC/ibex/issues/1479. The failing program '
        'is not distributed. Branch prediction remains enabled in the DUT.\n')
