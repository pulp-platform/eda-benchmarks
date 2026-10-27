#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
ara="$root/deps/ara"
build="$script_dir/build"
jobs=${JOBS:-1}
gcc_root=$("$script_dir/tools/gcc.sh")
install=$("$script_dir/tools/llvm.sh")

mkdir -p "$build"
make -C "$ara/apps" clean ARA_DIR="$ara" config=4_lanes
mapfile -t tests < "$script_dir/isa-tests.txt"
mapfile -t applications < "$script_dir/applications.txt"
tests+=("${applications[@]}")
targets=()
for test in "${tests[@]}"; do
  targets+=("bin/$test")
done
"${PYTHON:-python3}" -m venv "$script_dir/.venv"
"$script_dir/.venv/bin/python3" -m pip install --disable-pip-version-check 'numpy==1.26.4'
make -C "$ara/apps" -j"$jobs" ARA_DIR="$ara" config=4_lanes \
  LLVM_INSTALL_DIR="$install" PYTHON="$script_dir/.venv/bin/python3" \
  RISCV_CC_GCC="$gcc_root/bin/riscv64-unknown-elf-gcc" \
  RISCV_CC="$install/bin/clang --target=riscv64-unknown-elf --sysroot=$install/riscv64-unknown-elf" \
  "${targets[@]}"
mkdir -p "$script_dir/data/ara_tb_verilator"
: > "$script_dir/data/ara_tb_verilator/testcases.txt"
for test in "${tests[@]}"; do
  case_dir="$script_dir/data/ara_tb_verilator/$test"
  mkdir -p "$case_dir"
  cp "$ara/apps/bin/$test" "$case_dir/firmware.elf"
  printf -- '--meminit=ram,${DATA_DIR}/%s/firmware.elf\n' "$test" > "$case_dir/run.args"
  printf '%s\n' "$test" >> "$script_dir/data/ara_tb_verilator/testcases.txt"
done
cp "$gcc_root/share/licenses/COPYING.RUNTIME" "$script_dir/data/ara_tb_verilator/LICENSE.GCC-runtime-exception"
cp "$gcc_root/share/licenses/COPYING3" "$script_dir/data/ara_tb_verilator/LICENSE.GPL-3.0"
cp "$ara/apps/riscv-tests/LICENSE" "$script_dir/data/ara_tb_verilator/LICENSE.riscv-tests"
cp "$ara/LICENSE" "$script_dir/data/ara_tb_verilator/LICENSE.ara"
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/ara_tb_verilator/LICENSE.Apache-2.0"
cp "$install/share/ara-testbench/"LICENSE.* "$script_dir/data/ara_tb_verilator/"
sed -n '1,/^#include/p' "$ara/apps/common/printf.c" > "$script_dir/data/ara_tb_verilator/LICENSE.printf"
sed -n '1,/^\*\//p' "$ara/apps/jacobi2d/kernel/jacobi2d.c" > "$script_dir/data/ara_tb_verilator/LICENSE.jacobi2d"
for directory in "${applications[@]}" common; do
  while IFS= read -r -d '' notice; do
    relative=${notice#"$ara/apps/"}
    destination="$script_dir/data/ara_tb_verilator/LICENSES/ara-apps/$relative"
    mkdir -p "$(dirname "$destination")"
    cp "$notice" "$destination"
  done < <(find "$ara/apps/$directory" -type f \
    \( -iname 'LICENSE*' -o -iname 'COPYING*' -o -iname 'NOTICE*' -o \
       -iname 'COPYRIGHT*' -o -iname 'README.license*' \) -print0)
done
printf '%s\n' \
  "Ara source: $(git -C "$ara" rev-parse HEAD)" \
  'LLVM: official LLVM 20.1.0 Linux x86-64 binary' \
  "Newlib: $(cat "$install/share/ara-testbench/NEWLIB_REVISION")" \
  'Scalar compiler: upstream riscv-gnu-toolchain 5842fde8ee5bb3371643b60ed34906eff7a5fa31' \
  'Selection: upstream ISA make lists and four-lane CI application matrix' \
  'Ara configuration: 4_lanes (4 lanes, VLEN=4096)' \
  "Tests: ${tests[*]}" > "$script_dir/data/ara_tb_verilator/README.txt"
printf 'Prepared %d Ara test programs in %s\n' "${#tests[@]}" "$script_dir/data/ara_tb_verilator"
