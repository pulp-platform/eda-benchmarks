#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
print_key=0
if [[ ${1:-} == --key ]]; then
  print_key=1
  shift
fi
source "$(dirname "${BASH_SOURCE[0]}")/../../common/copy-licenses.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../common/toolchain-cache.sh"
script_dir=${TOOLCHAIN_WORK_DIR:?Pass the toolchain build directory}
source_dir="$script_dir/build/llvm-source"
build="$script_dir/build/llvm"
install="$script_dir/install/llvm"
revision=c6ee94de5c422d40a344e049481b62f5b47ca395
jobs=${JOBS:-1}
[[ $jobs =~ ^[1-9][0-9]*$ ]] || { printf 'JOBS must be a positive integer.\n' >&2; exit 1; }
setup_key=$({ cat "${BASH_SOURCE[0]}"; declare -f copy_licenses; toolchain_build_settings; } | sha256sum | cut -d ' ' -f1)
if [[ $print_key == 1 ]]; then
  printf '%s\n' "$setup_key"
  exit 0
fi
if [[ ! -f $install/.setup-key || $(cat "$install/.setup-key") != "$setup_key" ]]; then
  {
    rm -rf -- "$build" "$install"
    if [[ ! -d $source_dir/.git ]]; then
      git init -q "$source_dir"
      git -C "$source_dir" remote add origin https://github.com/pulp-platform/llvm-project.git
    fi
    if [[ $(git -C "$source_dir" rev-parse HEAD 2>/dev/null || true) != "$revision" ]]; then
      git -C "$source_dir" fetch --depth 1 origin "$revision"
      git -C "$source_dir" checkout --detach FETCH_HEAD
    fi
    git -C "$source_dir" reset --hard "$revision" >/dev/null
    git -C "$source_dir" clean -fdx >/dev/null
    sed -i '1i // Modified by the PULP benchmark suite: include <cstdint> for GCC 13.' \
      "$source_dir/llvm/include/llvm/Support/Signals.h"
    sed -i '/^#include <string>$/i #include <cstdint>' \
      "$source_dir/llvm/include/llvm/Support/Signals.h"
    cmake -S "$source_dir/llvm" -B "$build" -G 'Unix Makefiles' \
      -DCMAKE_INSTALL_PREFIX="$install" -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_OPTIMIZED_TABLEGEN=ON -DLLVM_ENABLE_PROJECTS='clang;lld' \
      -DLLVM_TARGETS_TO_BUILD=RISCV -DLLVM_DEFAULT_TARGET_TRIPLE=riscv32-unknown-elf \
      -DLLVM_ENABLE_LLD=OFF -DLLVM_APPEND_VC_REV=ON \
      -DLLVM_DISTRIBUTION_COMPONENTS='clang;clang-resource-headers;lld;llvm-ar;llvm-objcopy;llvm-objdump;llvm-ranlib;llvm-strip'
    cmake --build "$build" --target install-distribution --parallel "$jobs"
    copy_licenses "$source_dir" "$install/share/licenses/sources"
    printf '%s\n' "$setup_key" > "$install/.setup-key"
  } >&2
fi
if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
  rm -rf -- "$build" "$source_dir"
fi
printf '%s\n' "$install"
