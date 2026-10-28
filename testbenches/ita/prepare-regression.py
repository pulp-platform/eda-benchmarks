#!/usr/bin/env python3
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import shutil
import subprocess
import sys
import yaml

here = Path(__file__).resolve().parent
source = here.parent.parent / 'deps/ita'
class Loader(yaml.SafeLoader):
    pass
Loader.add_constructor('!reference', lambda loader, node: loader.construct_sequence(node))
cases = yaml.load((source / '.gitlab-ci.yml').read_text(), Loader=Loader)['run_sim']['parallel']['matrix']
cases.append(dict(S=64, E=64, P=64, F=64, activation='identity', no_stalls=0, single_attention=0))
data = here / 'data/ita_tb'
data.mkdir(parents=True, exist_ok=True)
generated = set()
names = []
for case in cases:
    shape = f"S{case['S']}_E{case['E']}_P{case['P']}_F{case['F']}_H1_B1_{case['activation'].capitalize()}"
    if shape not in generated:
        subprocess.run([sys.executable, str(source / 'testGenerator.py'), '--seed', '0', '-H', '1',
                        '-S', str(case['S']), '-E', str(case['E']), '-P', str(case['P']), '-F', str(case['F']),
                        '--activation', case['activation']], check=True)
        shutil.copytree(source / 'simvectors' / f'data_{shape}', data / shape, dirs_exist_ok=True)
        generated.add(shape)
    name = f"{shape}_nostalls{case['no_stalls']}_single{case['single_attention']}"
    destination = data / name
    destination.mkdir(exist_ok=True)
    args = [f'+stimuli=${{DATA_DIR}}/{shape}',
            f"+SEQ_LENGTH={case['S']}", f"+EMBED_SIZE={case['E']}",
            f"+PROJ_SPACE={case['P']}", f"+FF_SIZE={case['F']}",
            f"+ACTIVATION={dict(identity=0, relu=2, gelu=1)[case['activation']]}",
            f"+NO_STALLS={case['no_stalls']}", f"+SINGLE_ATTENTION={case['single_attention']}"]
    (destination / 'run.args').write_text('\n'.join(args) + '\n')
    names.append(name)
(data / 'testcases.txt').write_text('\n'.join(names) + '\n')
