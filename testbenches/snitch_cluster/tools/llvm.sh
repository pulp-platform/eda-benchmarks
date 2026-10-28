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
name=pulp-clang-22.1.7-pulp-0.1.0
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
setup_key=$(sha256sum "$script_dir/llvm.sh" | cut -d ' ' -f1)
if [[ -n $check_install ]]; then
  toolchain_keys_match "$check_install" .setup-key "$setup_key"
  exit
fi
existing=$(command -v "$name" || true)
if [[ -n $existing ]] && toolchain_cache_matches "$existing" .setup-key "$setup_key"; then
  dirname "$(dirname "$(realpath -e -- "$existing")")"
  exit 0
fi
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'The prebuilt RISC-V LLVM compiler requires Linux x86-64.\n' >&2; exit 1;
}
version=22.1.7-pulp-0.1.0
checksum=d7e089e3393fd0c8009f9653fe6e2e1204adeb31d605250a29d3f79d70a41bc9
compiler="$script_dir/install/llvm"
archive="riscv32-pulp-llvm-ubuntu2204-$version.tar.gz"
if [[ ! -f $compiler/.setup-key || $(cat "$compiler/.setup-key") != "$setup_key" ]]; then
  rm -rf -- "$compiler"
  mkdir -p "$script_dir/downloads" "$compiler"
  if [[ ! -f $script_dir/downloads/$archive ]]; then
    curl -fL --retry 3 "https://github.com/pulp-platform/llvm-project/releases/download/$version/$archive" -o "$script_dir/downloads/$archive.part"
    mv "$script_dir/downloads/$archive.part" "$script_dir/downloads/$archive"
  fi
  (cd "$script_dir/downloads" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >&2)
  tar xf "$script_dir/downloads/$archive" --strip-components=1 -C "$compiler"
  "$compiler/bin/clang" --version >&2
  printf '%s\n' "$setup_key" > "$compiler/.setup-key"
fi
if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
  rm -f -- "$script_dir/downloads/$archive"
fi
printf '%s\n' "$compiler"
