#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
name=xuantie-gcc-2.6.1-20220906
if [[ ${1:-} == --name ]]; then
  printf '%s\n' "$name"
  exit 0
fi
existing=$(command -v "$name" || true)
if [[ -n $existing && -x $existing ]]; then
  dirname "$(dirname "$(realpath -e -- "$existing")")"
  exit 0
fi
install="$script_dir/install/xuantie"
archive=Xuantie-900-gcc-elf-newlib-x86_64-V2.6.1-20220906.tar.gz
checksum=cdff169b09e9424f127a71300ce2e62ab059291a1b3fbc56c115dfb91c29b991
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'The Xuantie compiler binary requires Linux x86-64.\n' >&2; exit 1;
}
setup_key=$(sha256sum "$script_dir/gcc.sh" | cut -d ' ' -f1)
if [[ ! -f $install/.setup-key || $(cat "$install/.setup-key") != "$setup_key" ]]; then
  mkdir -p "$script_dir/downloads" "$install"
  if [[ ! -f $script_dir/downloads/$archive ]]; then
    curl -fL --retry 3 "https://occ-oss-prod.oss-cn-hangzhou.aliyuncs.com/resource//1663142243961/$archive" \
      -o "$script_dir/downloads/$archive.part"
    mv "$script_dir/downloads/$archive.part" "$script_dir/downloads/$archive"
  fi
  (cd "$script_dir/downloads" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >&2)
  tar -xzf "$script_dir/downloads/$archive" --strip-components=1 -C "$install"
  "$install/bin/riscv64-unknown-elf-gcc" --version >&2
  printf '%s\n' "$setup_key" > "$install/.setup-key"
fi
if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
  rm -f -- "$script_dir/downloads/$archive"
fi
printf '%s\n' "$install"
