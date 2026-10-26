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
downloads="$script_dir/downloads"
setup_key=$(cat "${BASH_SOURCE[0]}" "$install/.llvm-key" | sha256sum | cut -d ' ' -f1)
if [[ ! -f $install/.compiler-rt-key || $(cat "$install/.compiler-rt-key") != "$setup_key" ]]; then
  {
  mkdir -p "$downloads" "$build/src" "$install"
  release=https://github.com/llvm/llvm-project/releases/download/llvmorg-20.1.0
  for component in compiler-rt cmake; do
    archive="$component-20.1.0.src.tar.xz"
    case "$component" in
      compiler-rt) checksum=85798479b6762433a6fc8a87f4cbdb1dc050926220a8240d9e0e126f08e6f25f ;;
      cmake) checksum=9fcd319c6bb87344673f262ef5a6a01262fc9a0a741f3477b7e47e238441268d ;;
    esac
    if [[ ! -f $downloads/$archive ]]; then
      curl -fL --retry 3 "$release/$archive" -o "$downloads/$archive.part"
      mv "$downloads/$archive.part" "$downloads/$archive"
    fi
    (cd "$downloads" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c -)
    mkdir -p "$build/src/$component"
    tar -xJf "$downloads/$archive" --strip-components=1 -C "$build/src/$component"
    if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
      rm -f -- "$downloads/$archive"
    fi
  done
  cmake -S "$build/src/compiler-rt" -B "$build/compiler-rt" -G 'Unix Makefiles' \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$install" \
    -DCMAKE_C_COMPILER="$install/bin/clang" -DCMAKE_CXX_COMPILER="$install/bin/clang++" \
    -DCMAKE_ASM_COMPILER="$install/bin/clang" \
    -DCMAKE_C_COMPILER_TARGET=riscv64-unknown-elf \
    -DCMAKE_CXX_COMPILER_TARGET=riscv64-unknown-elf \
    -DCMAKE_ASM_COMPILER_TARGET=riscv64-unknown-elf \
    -DCMAKE_C_FLAGS='-march=rv64gc -mabi=lp64d -mno-relax -mcmodel=medany' \
    -DCMAKE_ASM_FLAGS='-march=rv64gc -mabi=lp64d -mno-relax -mcmodel=medany' \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_AR="$install/bin/llvm-ar" -DCMAKE_RANLIB="$install/bin/llvm-ranlib" \
    -DLLVM_CMAKE_DIR="$install/lib/cmake/llvm" \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON -DCOMPILER_RT_BAREMETAL_BUILD=ON \
    -DCOMPILER_RT_BUILD_BUILTINS=ON -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_ORC=OFF -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
    -DCOMPILER_RT_INSTALL_PATH="$install/lib/clang/20" \
    -DCOMPILER_RT_INSTALL_LIBRARY_DIR="$install/lib/clang/20/lib"
  cmake --build "$build/compiler-rt" --parallel "$jobs"
  cmake --install "$build/compiler-rt"
  mkdir -p "$install/share/ara-testbench"
  cp "$build/src/compiler-rt/LICENSE.TXT" "$install/share/ara-testbench/LICENSE.compiler-rt"
  printf '%s\n' "$setup_key" > "$install/.compiler-rt-key"
  } >&2
fi
printf '%s\n' "$install"
