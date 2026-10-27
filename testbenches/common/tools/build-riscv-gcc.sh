#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
print_key=0
if [[ ${1:-} == --key ]]; then
  print_key=1
  shift
fi
source "$(dirname "${BASH_SOURCE[0]}")/../copy-licenses.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../toolchain-cache.sh"
tool_dir=$1
repository=$2
revision=$3
shift 3
name=${TOOLCHAIN_NAME:-gcc}
source_dir="$tool_dir/build/$name-source"
build="$tool_dir/build/$name"
install="$tool_dir/install/riscv-$name"
jobs=${JOBS:-1}
[[ $jobs =~ ^[1-9][0-9]*$ ]] || { printf 'JOBS must be a positive integer.\n' >&2; exit 1; }
setup_key=$({ cat "${BASH_SOURCE[0]}"; declare -f copy_licenses; printf '%s\n' "$repository" "$revision" "$@"; toolchain_build_settings; } | sha256sum | cut -d ' ' -f1)
if [[ $print_key == 1 ]]; then
  printf '%s\n' "$setup_key"
  exit 0
fi
if [[ ! -f $install/.setup-key || $(cat "$install/.setup-key") != "$setup_key" ]]; then
  {
    rm -rf -- "$build" "$install"
    if [[ ! -d $source_dir/.git ]]; then
      git init -q "$source_dir"
      git -C "$source_dir" remote add origin "$repository"
    fi
    git -C "$source_dir" remote set-url origin "$repository"
    if [[ $(git -C "$source_dir" rev-parse HEAD 2>/dev/null || true) != "$revision" ]]; then
      git -C "$source_dir" fetch --depth 1 origin "$revision"
      git -C "$source_dir" checkout --detach FETCH_HEAD
    fi
    mapfile -t components < <(git -C "$source_dir" config --file .gitmodules --get-regexp '^submodule\..*\.path$' | awk '$2 ~ /^(riscv-)?(binutils(-gdb)?|gdb|gcc|newlib)$/ {print $2}')
    git -C "$source_dir" reset --hard "$revision" >/dev/null
    git -C "$source_dir" clean -fdx >/dev/null
    git -C "$source_dir" submodule update --init --force --depth 1 --jobs "$jobs" -- "${components[@]}"
    git -C "$source_dir" submodule foreach --recursive 'git reset --hard HEAD >/dev/null && git clean -fdx >/dev/null' >&2
    mkdir -p "$build" "$install"
    cd "$build"
    "../$name-source/configure" --prefix="$install" "$@"
    make -j"$jobs" MAKEINFO=true \
      MAKE='make -o all-target-libstdc++-v3 -o install-target-libstdc++-v3'
    mkdir -p "$install/share/licenses"
    cp "$source_dir/riscv-gcc/COPYING.RUNTIME" "$source_dir/riscv-gcc/COPYING3" "$source_dir/riscv-newlib/COPYING.NEWLIB" "$install/share/licenses/"
    copy_licenses "$source_dir" "$install/share/licenses/sources"
    printf '%s\n' "$setup_key" > "$install/.setup-key"
  } >&2
fi
if [[ ${KEEP_BUILD_TOOLS:-1} == 0 ]]; then
  rm -rf -- "$build" "$source_dir"
fi
printf '%s\n' "$install"
