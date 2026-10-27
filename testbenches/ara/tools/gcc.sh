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
name=riscv-gcc-9.2.0-5842fde
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
work=${TOOLCHAIN_WORK_DIR:-$script_dir}
install="$work/install/riscv-gcc"
setup_key=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-gcc.sh" --key)
if [[ -n $check_install ]]; then
  toolchain_keys_match "$check_install" .setup-key "$setup_key"
  exit
fi
compiler=$(command -v "$name" || true)
if [[ -n $compiler ]] && toolchain_cache_matches "$compiler" .setup-key "$setup_key"; then
  dirname "$(dirname "$(realpath -e -- "$compiler")")"
  exit 0
fi
built_install=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-gcc.sh")
[[ $built_install == "$install" ]] || {
  printf 'Compiler installation path mismatch: expected %s, got %s\n' "$install" "$built_install" >&2
  exit 1
}
ln -sfn riscv64-unknown-elf-gcc "$install/bin/$name"
printf '%s\n' "$install"
