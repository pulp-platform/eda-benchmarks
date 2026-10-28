#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
source_dir="$root/deps/cheshire"
sw="$source_dir/sw"
toolchain=$("$script_dir/tools/gcc.sh")
mkdir -p "$script_dir/data/tb_cheshire_soc"
: > "$script_dir/data/tb_cheshire_soc/testcases.txt"
for program in helloworld dma_1d.spm dma_2d.spm spm_uncached.spm; do
  name=${program//./_}
  case_dir="$script_dir/data/tb_cheshire_soc/$name"
  mkdir -p "$case_dir"
  "$toolchain/bin/riscv64-unknown-elf-gcc" \
    -march=rv64gc_zifencei -mabi=lp64d -mcmodel=medany -O2 \
    -ffunction-sections -fdata-sections -fno-builtin -nostartfiles -DPULP_BENCHMARK_STANDALONE_TEST \
    -I"$sw/include" -Wl,-L"$sw/link" -T"$sw/link/spm.ld" -Wl,--gc-sections \
    "$sw/lib/crt0.S" "$sw/lib/dif/clint.c" "$sw/lib/dif/uart.c" \
    "$sw/tests/$program.c" -o "$case_dir/firmware.elf"
  printf '+BINARY=${DATA_DIR}/%s/firmware.elf\n' "$name" > "$case_dir/run.args"
  printf '%s\n' "$name" >> "$script_dir/data/tb_cheshire_soc/testcases.txt"
done
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/tb_cheshire_soc/"
cp "$root/testbenches/common/licenses/LICENSE.NEWLIB-4.1.0" "$script_dir/data/tb_cheshire_soc/LICENSE.NEWLIB"
cp "$root/testbenches/common/licenses/LICENSE.GCC-RUNTIME" "$script_dir/data/tb_cheshire_soc/LICENSE.GCC-RUNTIME"
cp "$root/testbenches/common/licenses/LICENSE.GPL3" "$script_dir/data/tb_cheshire_soc/LICENSE.GPL3"
printf '%s\n' "Cheshire: $(git -C "$source_dir" rev-parse HEAD)" \
  'Upstream tests linked for SPM; JTAG preload; behavioral AXI memory; external boot peripherals omitted' \
  'Excluded: AXI-RT and CLIC tests (features disabled); serial-link DMA test (no remote device and memory in the testbench)' \
  'Compiler: upstream riscv64-elf nightly 2023.03.14 (GCC 12.2.0); RV64GC/Zifencei, lp64d' \
  > "$script_dir/data/tb_cheshire_soc/README.txt"
