#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$script_dir/../../common/tools/build-riscv-gcc.sh" "$@" "${TOOLCHAIN_WORK_DIR:?Pass the toolchain build directory}" \
  https://github.com/pulp-platform/pulp-riscv-gnu-toolchain.git \
  c672266b7199f2d495a72e284af33fc974f42239 \
  --with-arch=rv32im --with-cmodel=medlow --enable-multilib
