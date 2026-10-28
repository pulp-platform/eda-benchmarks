#!/usr/bin/env python3
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import argparse
import sys
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('--verifiers-dir', type=Path)
parser.add_argument('--no-fp-divsqrt', action='store_true')
args = parser.parse_args()
source = args.source
for manifest in ('run.yaml', 'riscv_tests_isa.yaml'):
    for run in yaml.safe_load((source / 'test' / manifest).read_text())['runs']:
        if 'verilator' not in run.get('simulators', ['verilator']):
            continue
        elf = Path(run['elf'])
        if str(elf).startswith('../sw/tests/build/'):
            kind = 'runtime'
        elif str(elf).startswith('../sw/riscv-tests/build/'):
            kind = 'isa'
        elif str(elf).startswith('../sw/kernels/'):
            kind = 'kernel' if 'cmd' in run else 'kernel-basic'
        else:
            continue
        if kind.startswith('kernel') and args.no_fp_divsqrt and elf.stem in {
                'gelu', 'correlation', 'kmeans'}:
            print(f'Skipping {elf.stem}: requires floating-point divide/square-root',
                  file=sys.stderr)
            continue
        print(kind, elf.relative_to('../sw'), run.get('retcode', 0))
        if kind == 'kernel' and args.verifiers_dir:
            directory = args.verifiers_dir / elf.stem
            directory.mkdir(parents=True, exist_ok=True)
            (directory / 'verify.args').write_text('\n'.join(run['cmd'][1:]) + '\n')
