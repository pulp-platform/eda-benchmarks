#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/../../common/toolchain-cache.sh"
check_install=
if [[ ${1:-} == --check ]]; then
  check_install=${2:?Pass the installation directory}
  shift 2
fi
name=ara-clang-20.1.0-newlib-2e4ecbb
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
work=${TOOLCHAIN_WORK_DIR:-$script_dir}
install="$work/install/llvm"
llvm_key=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-llvm.sh" --key)
newlib_key=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-newlib.sh" --key "$install")
runtime_key=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-compiler-rt.sh" --key "$install")
keys=(.llvm-key "$llvm_key" .newlib-key "$newlib_key" .compiler-rt-key "$runtime_key")
if [[ -n $check_install ]]; then
  toolchain_keys_match "$check_install" "${keys[@]}"
  exit
fi
compiler=$(command -v "$name" || true)
if [[ -n $compiler ]] && toolchain_cache_matches "$compiler" "${keys[@]}"; then
  dirname "$(dirname "$(realpath -e -- "$compiler")")"
  exit 0
fi
built_install=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-llvm.sh")
[[ $built_install == "$install" ]] || {
  printf 'LLVM installation path mismatch: expected %s, got %s\n' "$install" "$built_install" >&2
  exit 1
}
TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-newlib.sh" "$install" >&2
TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-compiler-rt.sh" "$install" >&2
ln -sfn clang "$install/bin/$name"
printf '%s\n' "$install"
