#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
name=ara-clang-20.1.0-newlib-2e4ecbb
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
compiler=$(command -v "$name" || true)
if [[ -n $compiler && -x $compiler ]]; then
  dirname "$(dirname "$(realpath -e -- "$compiler")")"
  exit 0
fi
work=${TOOLCHAIN_WORK_DIR:-$script_dir}
install="$work/install/llvm"
if [[ ! -x $install/bin/$name ]]; then
  built_install=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-llvm.sh")
  [[ $built_install == "$install" ]] || {
    printf 'LLVM installation path mismatch: expected %s, got %s\n' "$install" "$built_install" >&2
    exit 1
  }
  TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-newlib.sh" "$install" >&2
  TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-compiler-rt.sh" "$install" >&2
  ln -sfn clang "$install/bin/$name"
fi
printf '%s\n' "$install"
