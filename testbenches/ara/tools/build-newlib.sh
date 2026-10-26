#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=${TOOLCHAIN_WORK_DIR:?Pass the toolchain build directory}
install=${1:?Pass the LLVM installation directory}
build="$script_dir/build"
jobs=${JOBS:-1}
[[ $jobs =~ ^[1-9][0-9]*$ ]] || {
  printf 'JOBS must be a positive integer.\n' >&2
  exit 1
}
newlib_commit=2e4ecbb3f0d574d18eddb97eff9421db45fb0da7
setup_key=$(cat "${BASH_SOURCE[0]}" "$install/.llvm-key" | sha256sum | cut -d ' ' -f1)
if [[ ! -f $install/.newlib-key || $(cat "$install/.newlib-key") != "$setup_key" ]]; then
  {
  if [[ ! -d $build/src/newlib/.git ]]; then
    git init -q "$build/src/newlib"
  fi
  if [[ $(git -C "$build/src/newlib" rev-parse HEAD 2>/dev/null || true) != "$newlib_commit" ]]; then
    git -C "$build/src/newlib" fetch --depth 1 \
      https://sourceware.org/git/newlib-cygwin.git "$newlib_commit"
    git -C "$build/src/newlib" checkout --detach FETCH_HEAD
  fi

  target_flags='--target=riscv64-unknown-elf -march=rv64gc -mabi=lp64d -mno-relax -mcmodel=medany'
  mkdir -p "$build/newlib"
  (
    cd "$build/newlib"
    "$build/src/newlib/configure" --prefix="$install" --target=riscv64-unknown-elf \
      CC_FOR_TARGET="$install/bin/clang $target_flags -Wno-error-implicit-function-declaration -Wno-error=int-conversion" \
      AS_FOR_TARGET="$install/bin/llvm-as" AR_FOR_TARGET="$install/bin/llvm-ar" \
      LD_FOR_TARGET="$install/bin/ld.lld" RANLIB_FOR_TARGET="$install/bin/llvm-ranlib"
    make -j"$jobs" MAKEINFO=true
    make MAKEINFO=true install
  )
  mkdir -p "$install/share/ara-testbench"
  cp "$build/src/newlib/COPYING.NEWLIB" "$install/share/ara-testbench/LICENSE.newlib"
  printf '%s\n' "$newlib_commit" > "$install/share/ara-testbench/NEWLIB_REVISION"
  printf '%s\n' "$setup_key" > "$install/.newlib-key"
  } >&2
fi
printf '%s\n' "$install"
