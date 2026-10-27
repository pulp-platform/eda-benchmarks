#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data" "$script_dir"/variants/*/data
toolchain=$("$script_dir/tools/gcc.sh")
mkdir -p "$script_dir/build" "$script_dir/data/ibex_simple_system_tb"
software="$root/deps/ibex/examples/sw/simple_system"
make -C "$software/hello_test" -j"${JOBS:-1}" -B hello_test.bin \
  CC="$toolchain/bin/riscv32-unknown-elf-gcc" ARCH=rv32imc_zicsr
"${PYTHON:-python3}" "$script_dir/bin_to_vmem.py" "$software/hello_test/hello_test.bin" \
  "$script_dir/data/ibex_simple_system_tb/firmware.txt"
cp "$root/deps/ibex/LICENSE" "$script_dir/data/ibex_simple_system_tb/LICENSE.Apache-2.0"
printf '%s\n' \
  "Ibex: $(git -C "$root/deps/ibex" rev-parse HEAD)" \
  'Program: examples/sw/simple_system/hello_test (RV32IMC/Zicsr, ILP32)' \
  'Toolchain: lowRISC GCC rv32imcb 20220210-1 (GCC 10.2.0); freestanding, no linked runtime libraries' \
  > "$script_dir/data/ibex_simple_system_tb/README.txt"

compliance_revision=844c6660ef3f0d9b96957991109dfd80cc4938e2
compliance_source="$script_dir/build/compliance"
if [[ ! -d $compliance_source/.git ]]; then
  git init -q "$compliance_source"
fi
if [[ $(git -C "$compliance_source" rev-parse HEAD 2>/dev/null || true) != "$compliance_revision" ]]; then
  git -C "$compliance_source" fetch --depth 1 https://github.com/riscv/riscv-compliance.git "$compliance_revision"
  git -C "$compliance_source" checkout --detach FETCH_HEAD
fi
"${PYTHON:-python3}" "$script_dir/prepare-compliance.py" "$compliance_source" \
  "$script_dir/data/ibex_riscv_compliance_tb" "$toolchain/bin/riscv32-unknown-elf-"

mkdir -p "$script_dir/build/cosim"
coremark="$root/deps/ibex/vendor/eembc_coremark"
port="$root/deps/ibex/examples/sw/benchmarks/coremark/ibex"
"${PYTHON:-python3}" "$script_dir/prepare-coremark.py" "$coremark/core_main.c"
"$toolchain/bin/riscv32-unknown-elf-gcc" -march=rv32im -mabi=ilp32 \
  -static -mcmodel=medlow -O3 -nostdlib -nostartfiles -ffreestanding \
  -DTOTAL_DATA_SIZE=2000 -DMAIN_HAS_NOARGC=1 -DPERFORMANCE_RUN=1 \
  -DITERATIONS=10 -DSUPPRESS_PCOUNT_DUMP \
  -I"$coremark" -I"$port" -I"$software/common" \
  "$coremark/core_main.c" "$coremark/core_list_join.c" \
  "$coremark/core_matrix.c" "$coremark/core_state.c" "$coremark/core_util.c" \
  "$port/core_portme.c" "$port/ee_printf.c" "$coremark/barebones/cvt.c" \
  "$software/common/crt0.S" "$software/common/simple_system_common.c" \
  -T"$software/common/link.ld" -lm -lgcc -o "$script_dir/build/coremark.elf"
"$toolchain/bin/riscv32-unknown-elf-objcopy" -O binary "$script_dir/build/coremark.elf" \
  "$script_dir/build/cosim/firmware.bin"
"${PYTHON:-python3}" "$script_dir/bin_to_vmem.py" "$script_dir/build/cosim/firmware.bin" \
  "$script_dir/build/cosim/firmware.txt"
cp "$coremark/LICENSE.md" "$script_dir/build/cosim/LICENSE.CoreMark"
cp "$script_dir/data/ibex_simple_system_tb/LICENSE.Apache-2.0" "$script_dir/build/cosim/"
printf '%s\n' "Ibex: $(git -C "$root/deps/ibex" rev-parse HEAD)" 'CoreMark, 10 iterations; core_main.c modified to return nonzero on CRC validation failure' > "$script_dir/build/cosim/README.txt"
printf '%s\n' 'Spike co-simulation: lowRISC aadf648 (Ibex CI pin)' >> "$script_dir/build/cosim/README.txt"
cp "$toolchain/share/licenses/newlib/COPYING.NEWLIB" \
  "$script_dir/build/cosim/LICENSE.newlib"
cp "$toolchain/share/licenses/gcc/COPYING.RUNTIME" \
  "$script_dir/build/cosim/LICENSE.GCC-runtime-exception"
cp "$toolchain/share/licenses/gcc/COPYING3" \
  "$script_dir/build/cosim/LICENSE.GPL-3.0"

for program in pmp_smoke_test dit_test; do
  make -C "$software/$program" -j"${JOBS:-1}" -B "$program.bin" \
    CC="$toolchain/bin/riscv32-unknown-elf-gcc" ARCH=rv32imc_zicsr
done
"${PYTHON:-python3}" "$script_dir/prepare-cosim.py" "$script_dir"
