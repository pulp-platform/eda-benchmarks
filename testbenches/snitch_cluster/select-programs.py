#!/usr/bin/env python3
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import sys
import yaml

source = Path(sys.argv[1])
for manifest in ('run.yaml', 'riscv_tests_isa.yaml'):
    for run in yaml.safe_load((source / 'test' / manifest).read_text())['runs']:
        if 'verilator' not in run.get('simulators', ['verilator']):
            continue
        elf = Path(run['elf'])
        if str(elf).startswith('../sw/tests/build/'):
            kind = 'runtime'
        elif str(elf).startswith('../sw/riscv-tests/build/'):
            kind = 'isa'
        else:
            continue  # Kernel verifiers are integrated separately.
        print(kind, elf.name, run.get('retcode', 0))
