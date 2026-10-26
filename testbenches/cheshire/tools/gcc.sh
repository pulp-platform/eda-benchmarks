#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
name=riscv-gcc-12.2.0-2023.03.14
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
existing=$(command -v "$name" || true)
if [[ -n $existing && -x $existing ]]; then
  dirname "$(dirname "$(realpath -e -- "$existing")")"
  exit 0
fi
install="$script_dir/install/riscv-gcc"
archive=riscv64-elf-ubuntu-22.04-nightly-2023.03.14-nightly.tar.gz
checksum=49672b86df9750ef6aedcbae89c5e2e64505b1b5e69e598c88e2202145d3f672
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'The prebuilt RISC-V compiler requires Linux x86-64.\n' >&2
  exit 1
}
setup_key=$(sha256sum "$script_dir/gcc.sh" | cut -d ' ' -f1)
if [[ ! -f $install/.setup-key || $(cat "$install/.setup-key") != "$setup_key" ]]; then
  mkdir -p "$script_dir/downloads" "$install"
  if [[ ! -f $script_dir/downloads/$archive ]]; then
    curl -fL --retry 3 "https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2023.03.14/$archive" -o "$script_dir/downloads/$archive.part"
    mv "$script_dir/downloads/$archive.part" "$script_dir/downloads/$archive"
  fi
  (cd "$script_dir/downloads" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >&2)
  tar xf "$script_dir/downloads/$archive" --strip-components=1 -C "$install"
  printf '%s\n' "$setup_key" > "$install/.setup-key"
fi
if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
  rm -f -- "$script_dir/downloads/$archive"
fi
printf '%s\n' "$install"
