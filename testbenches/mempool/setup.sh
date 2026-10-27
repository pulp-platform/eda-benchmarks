#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data" "$script_dir"/variants/*/data
toolchain=$("$script_dir/tools/gcc.sh")
source_dir="$root/deps/mempool"
mapfile -t isa_programs < "$script_dir/isa-tests.txt"
for configuration in minpool mempool terapool; do
  extra_flags=
  [[ $configuration == minpool ]] || extra_flags=-DPULP_BENCHMARK_QUIET_HELLO
  data="$script_dir/variants/$configuration/data/mempool_tb_verilator"
  mkdir -p "$data"
  : > "$data/testcases.txt"
  for program in hello_world tests; do
    make -C "$source_dir/software/apps/baremetal" -j"${JOBS:-1}" -B "$program" \
      MEMPOOL_DIR="$source_dir" config="$configuration" RISCV_PREFIX="$toolchain/bin/riscv32-unknown-elf-" \
      RISCV_CC="$toolchain/bin/riscv32-unknown-elf-gcc $extra_flags" \
      -o update-opcodes -o "data_$program.h"
    case_dir="$data/$program"
    mkdir -p "$case_dir"
    cp "$source_dir/software/bin/apps/baremetal/$program" "$case_dir/firmware.elf"
    printf -- '--meminit=ram,${DATA_DIR}/%s/firmware.elf\n' "$program" > "$case_dir/run.args"
    printf '%s\n' "$program" >> "$data/testcases.txt"
  done
  isa_flags=(MEMPOOL_DIR="$source_dir" config="$configuration"
    RISCV_PREFIX="$toolchain/bin/riscv32-unknown-elf-")
  make -C "$source_dir/software" -j"${JOBS:-1}" -B "${isa_programs[@]/#/bin/}" \
    "${isa_flags[@]}" -o update-opcodes
  for program in "${isa_programs[@]}"; do
    case_dir="$data/$program"
    mkdir -p "$case_dir"
    cp "$source_dir/software/bin/$program" "$case_dir/firmware.elf"
    printf -- '--meminit=ram,${DATA_DIR}/%s/firmware.elf\n' "$program" > "$case_dir/run.args"
    printf '%s\n' "$program" >> "$data/testcases.txt"
  done
  cp "$root/LICENSE.Apache-2.0" "$data/LICENSE.Apache-2.0"
  cp "$root/deps/mempool/software/riscv-tests/LICENSE" "$data/LICENSE.RISCV-TESTS"
  cp "$toolchain/share/licenses/COPYING.NEWLIB" "$data/LICENSE.NEWLIB"
  cp "$toolchain/share/licenses/COPYING.RUNTIME" "$data/LICENSE.GCC-RUNTIME"
  cp "$toolchain/share/licenses/COPYING3" "$data/LICENSE.GPL3"
  # Runtime sources include the MIT-licensed tiny printf implementation.
  sed -n '1,/^#include/p' "$source_dir/software/runtime/printf.c" > "$data/LICENSE.printf"
  printf '%s\n' "MemPool: $(git -C "$root/deps/mempool" rev-parse HEAD)" \
    "Programs: upstream baremetal/hello_world, CI baremetal/tests, and RTL ISA selection; configuration: $configuration" \
    "Large configurations print only first/last core; all cores execute wake-up and barrier" \
    'Compiler: upstream PULP toolchain c672266b7199f2d495a72e284af33fc974f42239 (GCC 7.1.1); upstream ISA and tuning flags' \
    'Hardware retains XPULPIMG=1, ZFINX=1, ZQUARTERINX=0, XDIVSQRT=0' \
    > "$data/README.txt"
done
