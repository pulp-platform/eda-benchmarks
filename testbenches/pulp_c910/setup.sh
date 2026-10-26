#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
mkdir -p "$script_dir/data/host"
cp "$script_dir/elfloader.cpp" "$script_dir/data/host/"
source_dir="$root/deps/pulp_c910"
tests="$source_dir/vendor/thead_openc910/smart_run/tests"
toolchain=$("$script_dir/tools/gcc.sh")
assembler="$toolchain/bin/riscv64-unknown-elf-as"
mkdir -p "$script_dir/build/software" "$script_dir/data/tb"
: > "$script_dir/data/tb/testcases.txt"
programs=(hello_world coremark)
for directory in ISA MMU cache csr exception smoke; do
  while IFS= read -r source; do programs+=("$source"); done < <(
    find "$tests/cases/$directory" -name '*.s' -type f | sort)
done
for source in "${programs[@]}"; do
  name=$(basename "${source%.s}")
  build="$script_dir/build/software/$name"
  mkdir -p "$build"
  find "$tests/lib" -maxdepth 1 -type f -exec cp {} "$build/" \;
  cp "$tests/lib/clib/"* "$tests/lib/newlib_wrap/"* "$build/"
  skip=()
  extra_flags=
  if [[ $name == hello_world ]]; then
    cp "$tests/cases/hello_world/hello_world.c" "$build/"
  elif [[ $name == coremark ]]; then
    cp "$tests/cases/coremark/"* "$build/"
    extra_flags=-DFUNCTIONAL_TEST
  else
    cp "$source" "$build/"
    (cd "$build" && "$assembler" -march=rv64imafdc_zfh_xtheadc -mabi=lp64d \
      -o "$name.o" "$name.s")
    skip=(-o "$name.o")
  fi
  make -C "$build" -B "${skip[@]}" "$name.elf" FILE="$name" \
    CC="$toolchain/bin/riscv64-unknown-elf-gcc" \
    FLAG_MARCH=-march=rv64imafdcxtheadc FLAG_ABI=-mabi=lp64d \
    CFLAGS="-march=rv64imafdcxtheadc -mabi=lp64d -O2 $extra_flags"
  case_dir="$script_dir/data/tb/$name"
  mkdir -p "$case_dir"
  cp "$build/$name.elf" "$case_dir/firmware.elf"
  printf '+PRELOAD=${DATA_DIR}/%s/firmware.elf\n' "$name" > "$case_dir/run.args"
  printf '%s\n' "$name" >> "$script_dir/data/tb/testcases.txt"
done
cp "$script_dir/LICENSE.CoreMark" "$script_dir/data/tb/"
sed -n '1,/^#include/p' "$tests/lib/newlib_wrap/printf.c" > "$script_dir/data/tb/LICENSE.printf"
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/tb/"
cp "$root/testbenches/common/licenses/LICENSE.NEWLIB-3.2.0" "$script_dir/data/tb/LICENSE.NEWLIB"
cp "$root/testbenches/common/licenses/LICENSE.GCC-RUNTIME" "$script_dir/data/tb/LICENSE.GCC-RUNTIME"
cp "$root/testbenches/common/licenses/LICENSE.GPL3" "$script_dir/data/tb/LICENSE.GPL3"
printf '%s\n' "PULP C910: $(git -C "$source_dir" rev-parse HEAD)" \
  'Programs: vendor hello_world, CoreMark (upstream two-iteration functional check), ISA/MMU/cache/CSR/exception/bus tests' \
  'Firmware: reset-ROM code at 0x02000000; cached-SPM data/stack at 0x10040000/0x100ee000' \
  'Startup omits MSMPR/MCCR2 accesses to the removed internal L2 controller' \
  'CoreMark license: EEMBC LICENSE.md, vendored by Ibex at 0c91314d1a4fdfc157d623ad5cb6ac5aef746db1' \
  'Assembly: Xuantie 2.6.1; archive MD5 matches vendor release notes, pinned SHA256 checked' \
  'Compiler: upstream Xuantie V2.6.1-20220906 (GCC 10.2.0); RV64IMAFDC/XtheadC, lp64d' \
  > "$script_dir/data/tb/README.txt"
