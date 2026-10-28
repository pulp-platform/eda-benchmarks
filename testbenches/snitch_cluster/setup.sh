#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
source "$root/testbenches/common/fetch-archive.sh"
rm -rf -- "$script_dir/data" "$script_dir"/variants/*/data
source_dir="$root/deps/snitch_cluster"
git -C "$source_dir" submodule update --init --recursive --depth 1 -- \
  sw/deps/riscv-opcodes sw/deps/printf sw/deps/riscv-tests
mkdir -p "$script_dir/downloads" "$script_dir/data/host"
compiler_version=22.1.7-pulp-0.1.0
compiler=$("$script_dir/tools/llvm.sh")
if [[ ! -x $script_dir/.venv/bin/python ]]; then
  "${PYTHON:-python3}" -m venv "$script_dir/.venv"
fi
"$script_dir/.venv/bin/pip" install json5==0.12.1 jsonref==1.1.0 jsonschema==4.25.1 \
  mako==1.3.10 PyYAML==6.0.2 peakrdl==1.5.0 peakrdl-rawheader==0.1.1 \
  peakrdl-cheader==1.0.0 peakrdl-regblock==1.1.1 pymakeutils==1.5.0
"$script_dir/.venv/bin/pip" install -r "$script_dir/requirements.txt"
"$script_dir/.venv/bin/pip" install --no-deps -e "$source_dir"
export PATH="$script_dir/.venv/bin:$PATH"
fesvr_revision=35d50bc40e59ea1d5566fbd3d9226023821b1bb6
fetch_archive "https://codeload.github.com/riscv-software-src/riscv-isa-sim/tar.gz/$fesvr_revision" \
  f502c50a5e8fbed8073627c999c3c2a8f09d9240db79ef8e9f1d43bf1818cab2 "$script_dir/downloads/fesvr.tar.gz"
extract_archive "$script_dir/downloads/fesvr.tar.gz" "$script_dir/build/fesvr"
patch "$script_dir/build/fesvr/fesvr/context.h" < "$source_dir/target/sim/patches/context.h.diff"
patch "$script_dir/build/fesvr/fesvr/device.h" < "$source_dir/target/sim/patches/device.h.diff"
cp -a "$script_dir/build/fesvr/fesvr" "$script_dir/data/host/"
cp "$script_dir/build/fesvr/riscv/encoding.h" "$script_dir/data/host/fesvr/"
cp "$script_dir/fesvr_config.h" "$script_dir/data/host/fesvr/config.h"
for variant in minimal default; do
  build="$source_dir"
  host="$script_dir/variants/$variant/data/host"
  data="$script_dir/variants/$variant/data/tb_bin"
  mkdir -p "$build" "$host" "$data"
  mkdir -p "$data/python/snitch/util/sim"
  cp "$script_dir/requirements.txt" "$data/"
  cp "$script_dir/simulator.py" "$data/"
  cp "$script_dir/run.py" "$data/"
  for module in __init__ SnitchSim Elf data_utils verif_utils; do
    cp "$source_dir/util/sim/$module.py" "$data/python/snitch/util/sim/"
  done
  config=cfg/default.json
  selection_args=()
  if [[ $variant == minimal ]]; then
    config=cfg/yosys-ci.json
    selection_args+=(--no-fp-divsqrt)
  fi
  python "$script_dir/select-programs.py" "$source_dir" "${selection_args[@]}" \
    --verifiers-dir "$script_dir/build/verifiers" > "$script_dir/build/programs.txt"
  tests=()
  isa_tests=()
  apps=()
  while read -r kind program expected; do
    if [[ $kind == isa ]]; then
      isa_tests+=("${program##*/}")
    else
      tests+=("$build/sw/$program")
    fi
    [[ $kind != kernel* ]] || apps+=("$build/sw/${program%/build/*}")
  done < "$script_dir/build/programs.txt"
  SN_APPS="${apps[*]}" make -C "$build" -j"${JOBS:-1}" -B "${tests[@]}" "${isa_tests[@]}" \
    "$build/hw/generated/snitch_cluster_addrmap.svh" "$build/hw/generated/bootdata.cc" \
    CFG_OVERRIDE="$config" SN_LLVM_BINROOT="$compiler/bin" SN_BUILD_APPS=OFF SN_VLT_BIN=
  cp "$build/hw/generated/bootdata.cc" "$host/"
  cp "$build/hw/generated/snitch_cluster_addrmap.svh" "$host/"
  : > "$data/testcases.txt"
  while read -r kind program expected; do
    name=${program##*/}
    name=${name%.elf}
    case_dir="$data/$name"
    mkdir -p "$case_dir"
    cp "$build/sw/$program" "$case_dir/firmware.elf"
    if [[ $kind == kernel ]]; then
      cp "$build/sw/${program%/build/*}/scripts/"{verify,datagen}.py "$case_dir/"
      cp "$script_dir/build/verifiers/$name/verify.args" "$case_dir/"
      if [[ $program == kernels/dnn/* ]]; then
        module_dir="$data/python/snitch/dnn/$name/scripts"
        mkdir -p "$module_dir"
        cp "$case_dir/datagen.py" "$module_dir/"
      fi
    fi
    if [[ $variant == minimal && $name == non_null_exitcode ]]; then expected=28; fi
    printf '+PRELOAD=${DATA_DIR}/%s/firmware.elf\n+EXPECTED_EXIT_CODE=%s\n' \
      "$name" "$expected" > "$case_dir/run.args"
    printf '%s\n' "$name" >> "$data/testcases.txt"
  done < "$script_dir/build/programs.txt"
  cp "$root/LICENSE.Apache-2.0" "$data/"
  cp "$root/LICENSE.SHL-0.51" "$data/"
  cp "$script_dir/"LICENSE.* "$data/"
  cp "$script_dir/build/fesvr/LICENSE" "$data/LICENSE.FESVR"
  cp "$source_dir/sw/deps/printf/LICENSE" "$data/LICENSE.printf"
  cp "$source_dir/sw/deps/riscv-tests/LICENSE" "$data/LICENSE.riscv-tests"
  {
    printf '%s\n' "Snitch: $(git -C "$source_dir" rev-parse HEAD)" \
      "Configuration: $config" "Compiler: $compiler_version" \
      "FESVR: $fesvr_revision; upstream context/device patches; empty executable prefix" \
      'Selection: active Verilator entries from upstream test/run.yaml and test/riscv_tests_isa.yaml' \
      'Verification: Python verifier when defined in the upstream manifest; firmware exit checks for all cases' \
      'Patch: fix sorting kernel bucket copy-back when a compute core handles multiple buckets'
    if [[ $variant == minimal ]]; then
      printf '%s\n' 'Excluded: GELU, correlation, K-means (require floating-point divide/square-root)'
    fi
  } > "$data/README.txt"
done

ln -sfn default "$script_dir/variants/default_latch"
