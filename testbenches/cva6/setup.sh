#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
source_dir="$root/deps/cva6"
toolchain=$("$script_dir/tools/gcc.sh")
git -C "$source_dir" submodule update --init --depth 1 -- \
  corev_apu/axi_mem_if corev_apu/fpga/src/apb_timer corev_apu/fpga/src/axi2apb \
  corev_apu/fpga/src/axi_slice corev_apu/register_interface corev_apu/riscv-dbg \
  corev_apu/rv_plic corev_apu/src/axi_riscv_atomics
mkdir -p "$script_dir/downloads" "$script_dir/data/host" "$script_dir/data/ariane_tb"
fesvr_revision=35d50bc40e59ea1d5566fbd3d9226023821b1bb6
archive="$script_dir/downloads/fesvr.tar.gz"
if [[ ! -f $archive ]]; then
  curl -fL --retry 3 "https://codeload.github.com/riscv-software-src/riscv-isa-sim/tar.gz/$fesvr_revision" -o "$archive.part"
  mv "$archive.part" "$archive"
fi
printf '%s  %s\n' f502c50a5e8fbed8073627c999c3c2a8f09d9240db79ef8e9f1d43bf1818cab2 "$archive" | sha256sum -c - >&2
mkdir -p "$script_dir/build/fesvr"
tar xf "$archive" --strip-components=1 -C "$script_dir/build/fesvr"
cp -a "$script_dir/build/fesvr/fesvr" "$script_dir/data/host/"
mv "$script_dir/data/host/fesvr/elfloader.cc" "$script_dir/data/host/fesvr/fesvr_elfloader.cc"
cp "$script_dir/build/fesvr/riscv/encoding.h" "$script_dir/data/host/fesvr/"
cp "$script_dir/fesvr_config.h" "$script_dir/data/host/fesvr/config.h"
tests_revision=eeacd5507db7a0f50ca8c4f27aff220fcbb60bdf
tests="$script_dir/build/riscv-tests"
if [[ ! -d $tests/.git ]]; then
  git init "$tests"
  git -C "$tests" remote add origin https://github.com/riscv/riscv-tests.git
  git -C "$tests" fetch --depth 1 origin "$tests_revision"
  git -C "$tests" checkout --detach FETCH_HEAD
fi
[[ $(git -C "$tests" rev-parse HEAD) == "$tests_revision" ]]
git -C "$tests" submodule update --init --depth 1
programs=()
for group in asm amo mul fp; do
  mapfile -t group_programs < "$source_dir/ci/riscv-$group-tests.list"
  programs+=("${group_programs[@]}")
done
make -C "$tests/isa" -j"${JOBS:-1}" -B "${programs[@]}" RISCV_PREFIX="$toolchain/bin/riscv32-unknown-elf-"
: > "$script_dir/data/ariane_tb/testcases.txt"
for program in "${programs[@]}"; do
  name=${program//-/_}
  case_dir="$script_dir/data/ariane_tb/$name"
  mkdir -p "$case_dir"
  cp "$tests/isa/$program" "$case_dir/firmware.elf"
  printf '+permissive\n+elf_file=${DATA_DIR}/%s/firmware.elf\n+permissive-off\n${DATA_DIR}/%s/firmware.elf\n' \
    "$name" "$name" > "$case_dir/run.args"
  printf '%s\n' "$name" >> "$script_dir/data/ariane_tb/testcases.txt"
done
cp "$tests/LICENSE" "$script_dir/data/ariane_tb/LICENSE.riscv-tests"
cp "$tests/env/LICENSE" "$script_dir/data/ariane_tb/LICENSE.riscv-test-env"
cp "$script_dir/build/fesvr/LICENSE" "$script_dir/data/ariane_tb/LICENSE.FESVR"
printf '%s\n' "CVA6: $(git -C "$source_dir" rev-parse HEAD)" \
  "RISC-V tests: $tests_revision; original environment submodule; complete asm/amo/mul/fp CI lists" \
  "FESVR: $fesvr_revision" 'Compiler: Embecosm GCC 13.2.0, riscv32-gcc-ubuntu2204-release build 10, matching ci/install-toolchain.sh; freestanding RV64G/lp64 tests' \
  > "$script_dir/data/ariane_tb/README.txt"
