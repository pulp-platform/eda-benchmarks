#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
toolchain=$("$script_dir/tools/gcc.sh")
if [[ ! -x $script_dir/.venv/bin/python ]]; then
  "${PYTHON:-python3}" -m venv "$script_dir/.venv"
fi
"$script_dir/.venv/bin/pip" install numpy==1.26.4 PyYAML==6.0.2
"$script_dir/.venv/bin/pip" install torch==2.5.1+cpu --index-url https://download.pytorch.org/whl/cpu
mkdir -p "$script_dir/build" "$script_dir/data/redmule_tb"
"$script_dir/.venv/bin/python" "$script_dir/prepare-regression.py" "$root/deps/redmule" "$toolchain"
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/redmule_tb/"
sed -n '1,/^#ifndef/p' "$root/deps/redmule/sw/utils/tinyprintf.h" > "$script_dir/data/redmule_tb/LICENSE.tinyprintf"
printf '%s\n' "RedMulE: $(git -C "$root/deps/redmule" rev-parse HEAD)" \
  'Programs: all cases from upstream scripts/regression.yml, FP16, memory-mapped HWPE interface' \
  'Compiler: upstream riscv32-elf nightly 2024.08.28 (GCC 13.2.0); freestanding, no linked runtime libraries' \
  'Generator: numpy 1.26.4, torch 2.5.1+cpu' > "$script_dir/data/redmule_tb/README.txt"
