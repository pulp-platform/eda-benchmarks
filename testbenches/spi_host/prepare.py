#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import subprocess
import os
import hjson

here = Path(__file__).resolve().parent
root = here.parent.parent
host = here / 'build/host'
rtl = subprocess.check_output([
    os.environ.get('BENDER', str(root / 'bender/bin/bender')), '-d', str(root / 'bender/spi_host/variants/default'),
    'script', 'flist-plus', '-t', 'synthesis', '--top', 'spi_host_synth'], text=True).splitlines()
rtl = [line for line in rtl if not line.startswith('+define+TARGET_SYNTHESIS')]
names = {Path(line).name for line in rtl if not line.startswith('+')}
lines = []
for line in (here / 'sources.f').read_text().replace('@HOST@', str(host)).splitlines():
    if line.endswith('/spi_host_reg_pkg.sv'):
        lines.extend(rtl)
    if not line.startswith('+') and (Path(line).name in names or '/lowrisc_ip_spi_host_1.0/rtl/' in line):
        continue
    lines.append(line)
filelist = host / 'filelist.f'
filelist.write_text('\n'.join(lines) + '\n')
subprocess.run(['python3', str(root / 'testbenches/common/flist-to-bender.py'),
                str(filelist), str(host / 'Bender.yml'), 'spi_host_verification',
                str(host), str(here / 'data/host'),
                str(here / 'variants/default/verilator/spi_host_tb')], check=True)

config = hjson.loads((host / 'opentitan/hw/ip/spi_host/dv/spi_host_sim_cfg.hjson').read_text())
data = here / 'data/spi_host_tb'
data.mkdir(parents=True, exist_ok=True)
cases = []
for test in config['tests']:
    if test['name'] == 'spi_host_passthrough_mode':
        continue
    for seed in (1, 2):
        name = f"{test['name']}_seed{seed}"
        cases.append(name)
        directory = data / name
        directory.mkdir(exist_ok=True)
        (directory / 'run.args').write_text('\n'.join([
            f"+UVM_TEST_SEQ={test['uvm_test_seq']}", f'+verilator+seed+{seed}',
            *test.get('run_opts', [])]) + '\n')
(data / 'testcases.txt').write_text('\n'.join(cases) + '\n')
(data / 'README.txt').write_text(
    'OpenTitan: 9f497f6339b4484fc5b7e5dc5d4bc63f55ec3c35 (PULP vendored revision)\n'
    'DUT: exported spi_host_synth, PULP register interface, three chip selects.\n'
    'UVM 1.2; Verilator 08bbef72acdc8f3ec5b27e3275e75475bc974e2b HDL backend.\n'
    'All 11 applicable dedicated sequences; seeds 1 and 2.\n'
    'Functional coverage is disabled.\n'
    'Excluded: passthrough, removed by PULP; TL integrity/alert injection tests '
    'do not apply to the exported register bus.\n')
