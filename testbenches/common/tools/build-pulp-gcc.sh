#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
key_args=()
if [[ ${1:-} == --key ]]; then
  key_args=(--key)
  shift
fi
flags=(--with-arch=rv32imafd --with-abi=ilp32d --with-cmodel=medlow --enable-multilib)
case ${1:-rv32imafd} in
  rv32imafd) ;;
  rv32imc) flags=(--with-arch=rv32imc --with-abi=ilp32 --with-cmodel=medlow --disable-multilib) ;;
  *) printf 'Unsupported PULP GCC architecture: %s\n' "$1" >&2; exit 1 ;;
esac
exec "$script_dir/build-riscv-gcc.sh" "${key_args[@]}" "${TOOLCHAIN_WORK_DIR:?Pass the toolchain build directory}" \
  https://github.com/pulp-platform/pulp-riscv-gnu-toolchain.git \
  70acebe256fc49114b5f068fa79f03eb9affed09 "${flags[@]}"
