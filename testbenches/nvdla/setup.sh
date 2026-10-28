#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
source_dir="$root/deps/nvdla_hw"
out="$source_dir/outdir/nv_small_256_full"
mkdir -p "$script_dir/data/host" "$script_dir/build/trace" "$script_dir/data/trace"
cp "$out/spec/defs/project.h" "$script_dir/data/host/"
: > "$script_dir/data/trace/testcases.txt"
for trace_dir in "$source_dir/verif/tests/trace_tests/nv_small_256_full/"*/; do
  test_name=$(basename "$trace_dir")
  trace_build="$script_dir/build/trace/$test_name"
  mkdir -p "$trace_build" "$script_dir/data/trace/$test_name"
  (
    cd "$trace_build"
    "${PYTHON:-python3}" "$source_dir/verif/tools/nvdla_trace_parser.py" \
      -f "$trace_dir/$test_name.cfg"
    PYTHONPATH="$out/spec/manual" "${PYTHON:-python3}" \
      "$source_dir/verif/verilator/new_trace_to_verilator.py" . "$script_dir/data/trace/$test_name/trace.bin"
  )
  printf '+TRACE=${DATA_DIR}/%s/trace.bin\n' "$test_name" \
    > "$script_dir/data/trace/$test_name/run.args"
  printf '%s\n' "$test_name" >> "$script_dir/data/trace/testcases.txt"
done
cp "$source_dir/LICENSE" "$script_dir/data/trace/LICENSE.NVDLA"
printf '%s\n' "NVDLA: $(git -C "$source_dir" rev-parse HEAD)" \
  'Configuration: nv_small_256_full; all matching upstream trace tests' \
  'Excluded: upstream UVM testbench (UVMConnect interface unsupported by the tested Verilator versions)' \
  > "$script_dir/data/trace/README.txt"
