#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

common_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
package_root=$(cd -- "$common_dir/.." && pwd)

: "${BENCH_DESIGN:?BENCH_DESIGN is required}"
: "${BENCH_TECH:?BENCH_TECH is required}"
: "${BENCH_TOP:?BENCH_TOP is required}"

export BENCH_CHECK=${BENCH_CHECK:-0}
[[ $BENCH_CHECK == 0 || $BENCH_CHECK == 1 ]] || {
  printf 'CHECK must be 0 or 1\n' >&2
  exit 2
}

threads=${BENCH_INTRA_THREADS:-}
[[ -z $threads || $threads =~ ^[1-9][0-9]*$ ]] || {
  printf 'intra-target threads must be a positive integer: %s\n' "$threads" >&2
  exit 2
}

family=${BENCH_DESIGN%%.*}
variant=${BENCH_DESIGN#*.}
variant_dir=$package_root/$family/variants/$variant
flow=$variant_dir/$BENCH_TECH/yosys.tcl
results_dir=$variant_dir/$BENCH_TECH/results/yosys
report_dir=$variant_dir/$BENCH_TECH/reports/yosys
logs_dir=$variant_dir/$BENCH_TECH/logs

[[ -f $variant_dir/filelist.f ]] || {
  printf 'missing variant file list: %s\n' "$variant_dir/filelist.f" >&2
  exit 1
}
[[ -f $flow ]] || {
  printf 'missing variant Yosys flow: %s\n' "$flow" >&2
  exit 1
}

if command -v -- "${YOSYS_COMMAND:-yosys}" >/dev/null 2>&1; then
  yosys_command=("${YOSYS_COMMAND:-yosys}")
else
  read -r -a yosys_command <<<"${YOSYS_COMMAND:-yosys}"
fi
yosys_executable=$(command -v -- "${yosys_command[0]}") || {
  printf 'Yosys launcher not found: %s\n' "${yosys_command[0]}" >&2
  exit 127
}
# Preserve wrapper symlink names; some launchers dispatch using their basename.
if [[ $yosys_executable != /* ]]; then
  yosys_executable=$PWD/$yosys_executable
fi
yosys_command[0]=$yosys_executable
if version_output=$("${yosys_command[@]}" -V 2>&1); then
  :
else
  version_status=$?
  printf 'Yosys version check failed (exit %s): %s -V\n' \
    "$version_status" "${YOSYS_COMMAND:-yosys}" >&2
  printf '%s\n' "$version_output" >&2
  exit "$version_status"
fi
if [[ $version_output =~ Yosys[[:space:]]+([0-9]+)\.([0-9]+) ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
else
  printf 'cannot determine Yosys version from: %s -V\n' "${YOSYS_COMMAND:-yosys}" >&2
  exit 1
fi

external_slang=0
if (( major == 0 && minor < 67 )); then
  external_slang=1
fi

# Preserve previous outputs while keeping readback validation free of stale files.
log_file=$logs_dir/yosys.log
"$common_dir/backup.sh" "$results_dir" "$report_dir" "$log_file"
mkdir -p "$results_dir" "$report_dir" "$logs_dir"
export BENCH_PACKAGE_ROOT=$package_root
export BENCH_VARIANT_DIR=$variant_dir
export BENCH_RESULTS_DIR=$results_dir
export BENCH_REPORT_DIR=$report_dir
export BENCH_EXTERNAL_SLANG=$external_slang
export BENCH_INTRA_THREADS=$threads
export BENCH_SLANG_ARGS_FILE=$variant_dir/yosys-slang.args

cd -- "$variant_dir"
"${yosys_command[@]}" -c "$flow" 2>&1 | tee "$logs_dir/yosys.log"
