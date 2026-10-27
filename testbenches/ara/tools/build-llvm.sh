#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
print_key=0
if [[ ${1:-} == --key ]]; then
  print_key=1
  shift
fi
recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
license_dir="$recipe_dir/licenses"
script_dir=${TOOLCHAIN_WORK_DIR:?Pass the toolchain build directory}
install="$script_dir/install/llvm"
downloads="$script_dir/downloads"
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'The Ara LLVM binary requires Linux x86-64.\n' >&2
  exit 1
}
archive=LLVM-20.1.0-Linux-X64.tar.xz
checksum=954ac51498519f6ed9540714fb04bc401f70039b296a8160dd1559be380788d7
setup_key=$({
  sha256sum "${BASH_SOURCE[0]}"
  (cd "$license_dir" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum)
} | sha256sum | cut -d ' ' -f1)
if [[ $print_key == 1 ]]; then
  printf '%s\n' "$setup_key"
  exit 0
fi
if [[ ! -f $install/.llvm-key || $(cat "$install/.llvm-key") != "$setup_key" ]]; then
  rm -rf -- "$install"
  mkdir -p "$downloads" "$install"
  if [[ ! -f $downloads/$archive ]]; then
    curl -fL --retry 3 "https://github.com/llvm/llvm-project/releases/download/llvmorg-20.1.0/$archive" -o "$downloads/$archive.part" >&2
    mv "$downloads/$archive.part" "$downloads/$archive"
  fi
  (cd "$downloads" && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >&2)
  tar -xJf "$downloads/$archive" --strip-components=1 -C "$install"
  for component in llvm clang clang-tools-extra lld lldb bolt compiler-rt \
      flang libc libcxx libcxxabi libunwind mlir openmp polly pstl; do
    notice="$install/share/licenses/sources/$component/LICENSE.TXT"
    mkdir -p "$(dirname "$notice")"
    curl -fL --retry 3 \
      "https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-20.1.0/$component/LICENSE.TXT" \
      -o "$notice"
  done
  cp -a "$license_dir/." "$install/share/licenses/third-party/"
  "$install/bin/clang" --version >&2
  printf '%s\n' "$setup_key" > "$install/.llvm-key"
fi
if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
  rm -f -- "$downloads/$archive"
fi
printf '%s\n' "$install"
