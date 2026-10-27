#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/../toolchain-cache.sh"
check_install=
if [[ ${1:-} == --check ]]; then
  check_install=${2:?Pass the installation directory}
  shift 2
fi
print_name=0
if [[ ${1:-} == --name ]]; then
  print_name=1
  shift
fi
case ${1:-rv32imafd} in
  rv32imafd) name=pulp-gcc-7.1.1-70acebe-rv32imafd ;;
  rv32imc) name=pulp-gcc-7.1.1-70acebe-rv32imc ;;
  *) printf 'Unsupported PULP GCC architecture: %s\n' "$1" >&2; exit 1 ;;
esac
if [[ $print_name == 1 ]]; then
  printf '%s\n' "$name"
  exit 0
fi
work=${TOOLCHAIN_WORK_DIR:-$script_dir/build/$name}
install="$work/install/riscv-gcc"
setup_key=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-pulp-gcc.sh" --key "${1:-rv32imafd}")
if [[ -n $check_install ]]; then
  toolchain_keys_match "$check_install" .setup-key "$setup_key"
  exit
fi
compiler=$(command -v "$name" || true)
if [[ -n $compiler ]] && toolchain_cache_matches "$compiler" .setup-key "$setup_key"; then
  dirname "$(dirname "$(realpath -e -- "$compiler")")"
  exit 0
fi
built_install=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-pulp-gcc.sh" "${1:-rv32imafd}")
[[ $built_install == "$install" ]] || {
  printf 'GCC installation path mismatch: expected %s, got %s\n' "$install" "$built_install" >&2
  exit 1
}
ln -sfn riscv32-unknown-elf-gcc "$install/bin/$name"
printf '%s\n' "$install"
