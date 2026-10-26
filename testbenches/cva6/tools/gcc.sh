#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
name=embecosm-gcc-13.2.0-build10
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
existing=$(command -v "$name" || true)
if [[ -n $existing && -x $existing ]]; then
  dirname "$(dirname "$(realpath -e -- "$existing")")"
  exit 0
fi
install="$script_dir/install/embecosm"
archive=riscv32-embecosm-ubuntu2204-gcc13.2.0.tar.gz
checksum=63feda7d4c6f1cd396367f9555da90bc57c9938235b531763fb6424f097dd28d
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'The prebuilt RISC-V compiler requires Linux x86-64.\n' >&2
  exit 1
}
setup_key=$(sha256sum "$script_dir/gcc.sh" | cut -d ' ' -f1)
if [[ ! -f $install/.setup-key || $(cat "$install/.setup-key") != "$setup_key" ]]; then
  mkdir -p "$script_dir/downloads" "$install"
  if [[ ! -f $script_dir/downloads/$archive ]]; then
    curl -fL --retry 3 "https://buildbot.embecosm.com/job/riscv32-gcc-ubuntu2204-release/10/artifact/$archive" -o "$script_dir/downloads/$archive.part"
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
