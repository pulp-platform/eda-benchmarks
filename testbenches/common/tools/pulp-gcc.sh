#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
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
compiler=$(command -v "$name" || true)
if [[ -n $compiler && -x $compiler ]]; then
  dirname "$(dirname "$(realpath -e -- "$compiler")")"
  exit 0
fi
work=${TOOLCHAIN_WORK_DIR:-$script_dir/build/$name}
install="$work/install/riscv-gcc"
if [[ ! -x $install/bin/$name ]]; then
  built_install=$(TOOLCHAIN_WORK_DIR="$work" "$script_dir/build-pulp-gcc.sh" "${1:-rv32imafd}")
  [[ $built_install == "$install" ]] || {
    printf 'GCC installation path mismatch: expected %s, got %s\n' "$install" "$built_install" >&2
    exit 1
  }
  ln -sfn riscv32-unknown-elf-gcc "$install/bin/$name"
fi
printf '%s\n' "$install"
