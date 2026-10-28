#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
toolchain=$("$root/testbenches/common/tools/pulp-gcc.sh")
if [[ ! -x $script_dir/.venv/bin/python ]]; then
  "${PYTHON:-python3}" -m venv "$script_dir/.venv"
fi
"$script_dir/.venv/bin/pip" install numpy==1.26.4 PyYAML==6.0.2
"$script_dir/.venv/bin/pip" install torch==2.5.1+cpu --index-url https://download.pytorch.org/whl/cpu
mkdir -p "$script_dir/build" "$script_dir/data/opope_tb"
"$script_dir/.venv/bin/python" "$script_dir/prepare-regression.py" "$root/deps/opope" "$toolchain"
cp "$root/deps/opope/LICENSE_SW" "$script_dir/data/opope_tb/LICENSE.Apache-2.0"
sed -n '1,/^#ifndef/p' "$root/deps/opope/sw/utils/tinyprintf.h" > "$script_dir/data/opope_tb/LICENSE.tinyprintf"
printf '%s\n' \
  "OPOPE: $(git -C "$root/deps/opope" rev-parse HEAD)" \
  'Programs: upstream hwpe-test and complex-test CI matrices; upstream seed 1337' \
  'Compiler: upstream PULP toolchain 70acebe256fc49114b5f068fa79f03eb9affed09; freestanding, no linked runtime libraries' \
  'Generator: numpy 1.26.4, torch 2.5.1+cpu' > "$script_dir/data/opope_tb/README.txt"
