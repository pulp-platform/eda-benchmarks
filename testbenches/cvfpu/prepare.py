#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import subprocess
import os

here = Path(__file__).resolve().parent
root = here.parent.parent
host = here / 'build/host'
bench = (here / 'sources.f').read_text().replace('@HOST@', str(host))
for variant in ('full', 'fp32_fma'):
    recipe = root / 'bender/cvfpu/variants' / variant
    rtl = subprocess.check_output([
        os.environ.get('BENDER', str(root / 'bender/bin/bender')), '-d', str(recipe), 'script',
        'flist-plus', '-t', 'synthesis'], text=True)
    rtl = '\n'.join(line for line in rtl.splitlines()
                    if not line.startswith(('+define+SYNTHESIS',
                                            '+define+COMMON_CELLS_ASSERTS_OFF',
                                            '+define+TARGET_SYNTHESIS')))
    directory = host / variant
    directory.mkdir(parents=True, exist_ok=True)
    sources = directory / 'filelist.f'
    sources.write_text(rtl + '\n' + bench +
                       ('+define+BENCH_FP32_FMA\n' if variant == 'fp32_fma' else ''))
    subprocess.run(['python3', str(root / 'testbenches/common/flist-to-bender.py'),
                    str(sources), str(directory / 'Bender.yml'),
                    f'cvfpu_{variant}_verification', str(host), str(here / 'data/host'),
                    str(here / 'variants' / variant / 'verilator/cvfpu_tb')], check=True)

data = here / 'data/cvfpu_tb'
data.mkdir(parents=True, exist_ok=True)
cases = []
classes = ['fpu_single_op_test', 'fpu_random_test', 'fpu_op_group_test',
           'fpu_fmt_single_op_test', 'fpu_fmt_random_test', 'fpu_fmt_op_group_test']
for test in classes:
    for seed in range(1, 51):
        name = f'{test}_seed{seed}'
        cases.append(name)
        case = data / name
        case.mkdir(exist_ok=True)
        (case / 'run.args').write_text(
            f'+UVM_TESTNAME={test}\n+NB_TXNS=10\n+verilator+seed+{seed}\n')
(data / 'testcases.txt').write_text('\n'.join(cases) + '\n')
(data / 'README.txt').write_text(
    'OpenHW CVFPU UVM: 2f787402256b76d00e397d72a00b57120db455cf\n'
    'CORE-V helpers: 1dfa4836868fc2fc8e3754ee5c1c43fb42948aa3\n'
    'UVM: Accellera 1.1d; archive SHA256 b6f74e64dda5efa08e86dd15c22e921c404dd7d4eb4334ab62afe61fca0f6369\n'
    'Upstream VCS transaction count: 10; 50 fixed reseeds per available class.\n'
    'Coverage: scalar FP32/FP64/FP16; fp32_fma is restricted to FP32 arithmetic.\n'
    'Excluded: other formats and vector/PACE/dot-product operations.\n'
    'Skipped vectors: DIV/SQRT with improperly NaN-boxed operands; '
    'float-to-float conversion of infinity; integer-to-float overflow; '
    'FMA/add/multiply underflow rounding to the smallest normal value.\n'
    'Unavailable regression classes: fpu_conv_test, fpu_special_val_test, '
    'fpu_random_op_bp_test, fpu_op_group_bp_test; missing bug_f2i_seq.\n')
