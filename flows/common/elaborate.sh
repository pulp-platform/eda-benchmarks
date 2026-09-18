#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

common_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
package_root=$(cd -- "$common_dir/.." && pwd)

usage() {
  printf 'Usage: %s [--intra-threads count] <design.variant>\n' "$0" >&2
  exit 2
}

threads=${BENCH_INTRA_THREADS:-}
case ${1:-} in
  --intra-threads)
    [[ ${2:-} =~ ^[1-9][0-9]*$ ]] || usage
    threads=$2
    shift 2
    ;;
esac
[[ -z $threads || $threads =~ ^[1-9][0-9]*$ ]] || {
  printf 'intra-target threads must be a positive integer: %s\n' "$threads" >&2
  exit 2
}
[[ $# == 1 ]] || usage
target=$1

family=${target%%.*}
variant=${target#*.}
variant_dir=$package_root/$family/variants/$variant
[[ -f $variant_dir/filelist.f ]] || {
  printf 'missing variant file list: %s\n' "$variant_dir/filelist.f" >&2
  exit 1
}
[[ -f $common_dir/elaborate.tcl ]] || {
  printf 'missing common elaboration flow: %s\n' "$common_dir/elaborate.tcl" >&2
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

logs_dir=$variant_dir/logs
log_file=$logs_dir/elaborate.log
"$common_dir/backup.sh" "$log_file"
mkdir -p "$logs_dir"

export BENCH_INTRA_THREADS=$threads
export BENCH_EXTERNAL_SLANG=$external_slang
export BENCH_AST=${BENCH_AST:-0}
export BENCH_SLANG_ARGS_FILE=$variant_dir/yosys-slang.args

cd -- "$variant_dir"
"${yosys_command[@]}" -c "$common_dir/elaborate.tcl" 2>&1 | tee "$log_file"
