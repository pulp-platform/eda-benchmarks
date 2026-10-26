#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$script_dir/../../common/tools/build-riscv-gcc.sh" "${TOOLCHAIN_WORK_DIR:?Pass the toolchain build directory}" \
  https://github.com/riscv/riscv-gnu-toolchain.git \
  5842fde8ee5bb3371643b60ed34906eff7a5fa31 \
  --with-arch=rv64gcv --with-cmodel=medlow --enable-multilib
