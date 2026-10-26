#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
toolchain=$("$root/testbenches/common/tools/pulp-gcc.sh" rv32imc)
mkdir -p "$script_dir/data/tb_top"
software="$root/deps/cv32e40p/example_tb/core"
: > "$script_dir/data/tb_top/testcases.txt"
for selection in hello_world:custom/hello_world interrupt:interrupt/interrupt; do
  name=${selection%%:*}
  program=${selection#*:}
  make -C "$software" -B "$program.hex" RISCV="$toolchain" \
    RISCV_EXE_PREFIX="$toolchain/bin/riscv32-unknown-elf-"
  mkdir -p "$script_dir/data/tb_top/$name"
  cp "$software/$program.hex" "$script_dir/data/tb_top/$name/firmware.txt"
  printf '+firmware=${DATA_DIR}/%s/firmware.txt\n' "$name" \
    > "$script_dir/data/tb_top/$name/run.args"
  printf '%s\n' "$name" >> "$script_dir/data/tb_top/testcases.txt"
done
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/tb_top/LICENSE.Apache-2.0"
licenses="$toolchain/share/licenses"
cp "$licenses/COPYING.NEWLIB" "$script_dir/data/tb_top/LICENSE.Newlib"
cp "$licenses/COPYING3" "$script_dir/data/tb_top/LICENSE.GPL-3.0"
cp "$licenses/COPYING.RUNTIME" "$script_dir/data/tb_top/LICENSE.GCC-runtime-exception"
sed -n '1,/^ \*\//p' "$software/custom/syscalls.c" > "$script_dir/data/tb_top/LICENSE.syscalls"
sed -n '1,/^ \*\//p' "$software/custom/crt0.S" > "$script_dir/data/tb_top/LICENSE.crt0"
sed -n '1,/notice and this notice are preserved/p' "$software/custom/link.ld" > "$script_dir/data/tb_top/LICENSE.linker"
printf '%s\n' \
  "CV32E40P: $(git -C "$root/deps/cv32e40p" rev-parse HEAD)" \
  'Programs: example_tb/core custom/hello_world and interrupt/interrupt (RV32IMC, ILP32)' \
  'Toolchain: shared PULP GCC source 70acebe256fc49114b5f068fa79f03eb9affed09 (upstream recommends PULP GCC without a release pin)' > "$script_dir/data/tb_top/README.txt"
