#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
source_dir="$root/deps/spatz"
compiler=$("$script_dir/tools/llvm.sh")
gcc=$("$root/testbenches/common/tools/pulp-gcc.sh")
if [[ ! -x $script_dir/.venv/bin/python ]]; then
  "${PYTHON:-python3}" -m venv "$script_dir/.venv"
fi
"$script_dir/.venv/bin/pip" install hjson==3.1.0 jstyleson==0.0.2 jsonref==1.1.0 \
  jsonschema==4.25.1 mako==1.3.10 scipy==1.15.3
"$script_dir/.venv/bin/pip" install 'torch==2.5.1+cpu' --index-url https://download.pytorch.org/whl/cpu
export PATH="$script_dir/.venv/bin:$PATH"
mkdir -p "$script_dir/downloads" "$script_dir/data/host" "$script_dir/data/tb_bin"
fetch() {
  local name=$1 checksum=$2 url=$3
  if [[ ! -f $script_dir/downloads/$name ]]; then
    curl -fL --retry 3 "$url" -o "$script_dir/downloads/$name.part"
    mv "$script_dir/downloads/$name.part" "$script_dir/downloads/$name"
  fi
  (cd "$script_dir/downloads" && printf '%s  %s\n' "$checksum" "$name" | sha256sum -c - >&2)
}
fesvr_revision=c663ea20a53f4316db8cb4d591b1c8e437f4a0c4
fetch fesvr.tar.gz 3896bb8ac7b78edb7bbfa5f9b86070d4e145a802e670e7f113dcd462ad5dd166 \
  "https://codeload.github.com/riscv/riscv-isa-sim/tar.gz/$fesvr_revision"
mkdir -p "$script_dir/build/fesvr"
tar xf "$script_dir/downloads/fesvr.tar.gz" --strip-components=1 -C "$script_dir/build/fesvr"
cp -a "$script_dir/build/fesvr/fesvr" "$script_dir/data/host/"
cp "$script_dir/build/fesvr/riscv/"{encoding,platform}.h "$script_dir/data/host/fesvr/"
cp "$script_dir/fesvr_config.h" "$script_dir/data/host/fesvr/config.h"
cluster="$source_dir/hw/system/spatz_cluster"
config="$cluster/cfg/spatz_cluster.default.dram.hjson"
python "$source_dir/util/clustergen.py" -c "$config" -o "$cluster/src"
cp "$cluster/src/generated/bootdata.cc" "$script_dir/data/host/"
build="$source_dir"
opcodes_revision=4bb9eebfc2cb97bd4d27a43880c8fe684cee242e
fetch opcodes.tar.gz a2f0795fb8a6edf1ef08bb2e5fd5639cfcbc395dab4c9a0a433a65da8e6bc446 \
  "https://codeload.github.com/pulp-platform/riscv-opcodes/tar.gz/$opcodes_revision"
mkdir -p "$build/sw/toolchain/riscv-opcodes"
tar xf "$script_dir/downloads/opcodes.tar.gz" --strip-components=1 -C "$build/sw/toolchain/riscv-opcodes"
mapfile -t config_args < <(python "$script_dir/config-to-cmake.py" "$config")
for benchmark in "$build/sw/spatzBenchmarks/"*/; do
  for config_file in "$benchmark/script/"*.json; do
    [[ -f $config_file ]] || continue
    (cd "$benchmark" && python script/gen_data.py -c "$config_file")
  done
done
software="$script_dir/build/software"
cmake --fresh -S "$build/hw/system/spatz_cluster/sw" -B "$software" \
  -DLLVM_PATH="$compiler" -DGCC_PATH="$gcc" -DBUILD_TESTS=ON -DPYTHON="$script_dir/.venv/bin/python" \
  -DSPATZ_CLUSTER_CFG=spatz_cluster.default.dram.hjson "${config_args[@]}"
cmake --build "$software" -j"${JOBS:-1}"
: > "$script_dir/data/tb_bin/testcases.txt"
for suite in snRuntime riscvTests spatzBenchmarks; do
  for program in "$software/$suite/"test-*; do
    [[ -f $program && -x $program ]] || continue
    name=$(basename "$program")
    case_dir="$script_dir/data/tb_bin/$name"
    mkdir -p "$case_dir"
    cp "$program" "$case_dir/firmware.elf"
    printf '+PRELOAD=${DATA_DIR}/%s/firmware.elf\n' "$name" > "$case_dir/run.args"
    if [[ $name == test-riscvTests-invalid ]]; then
      printf '+EXPECTED_EXIT_CODE=2989\n' >> "$case_dir/run.args"
    fi
    printf '%s\n' "$name" >> "$script_dir/data/tb_bin/testcases.txt"
  done
done
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/tb_bin/"
cp "$source_dir/LICENSE" "$script_dir/data/tb_bin/LICENSE.Spatz"
sed -n '1,/^#include/p' "$source_dir/sw/snRuntime/vendor/printf.c" > "$script_dir/data/tb_bin/LICENSE.printf"
cp "$gcc/share/licenses/COPYING.NEWLIB" "$script_dir/data/tb_bin/LICENSE.NEWLIB"
cp "$gcc/share/licenses/COPYING.RUNTIME" "$script_dir/data/tb_bin/LICENSE.GCC-RUNTIME"
cp "$gcc/share/licenses/COPYING3" "$script_dir/data/tb_bin/LICENSE.GPL3"
cp "$script_dir/build/fesvr/LICENSE" "$script_dir/data/tb_bin/LICENSE.FESVR"
printf '%s\n' "Spatz: $(git -C "$source_dir" rev-parse HEAD)" \
  'Configuration: spatz_cluster.default.dram.hjson; two cores, VLEN=512, ELEN=64' \
  'Compiler: upstream LLVM c6ee94de5c422d40a344e049481b62f5b47ca395 and PULP GCC 70acebe256fc49114b5f068fa79f03eb9affed09' \
  'Runtime includes stdarg.h and selects the hardware DMA core' \
  "FESVR: $fesvr_revision; riscv-opcodes: $opcodes_revision" \
  'DMA test selects the hardware DMA core rather than hard-coded hart 8' \
  > "$script_dir/data/tb_bin/README.txt"
