#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  printf 'Usage: %s [installation-directory]\n' "$0"
  exit 0
fi
[[ $# -le 1 ]] || {
  printf 'Usage: %s [installation-directory]\n' "$0" >&2
  exit 2
}
install=$(realpath -m -- "${1:-$script_dir/install/spike}")
archive=ibex-cosim-aadf648.tar.gz
checksum=439fe242443b594f6b47b3917bc82683127d6ef33726bce4def3c723f53ef384
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'The Ibex CI Spike binary requires Linux x86-64. Build lowRISC Spike aadf648 on other hosts.\n' >&2
  exit 1
}
if [[ ! -f $install/.complete ]]; then
  mkdir -p "$script_dir/downloads" "$install"
  if [[ ! -f $script_dir/downloads/$archive ]]; then
    curl -fL --retry 3 "https://storage.googleapis.com/ibex-cosim-builds/$archive" \
      -o "$script_dir/downloads/$archive.part"
    mv "$script_dir/downloads/$archive.part" "$script_dir/downloads/$archive"
  fi
  (cd "$script_dir/downloads" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >&2)
  tar -xzf "$script_dir/downloads/$archive" --strip-components=1 -C "$install"
  escaped_install=$(printf '%s' "$install" | sed 's/[\\&|]/\\&/g')
  sed -i "s|/tools/riscv-isa-sim|$escaped_install|g" "$install"/lib/pkgconfig/*.pc
  touch "$install/.complete"
fi
printf '%s\n' "$install"
