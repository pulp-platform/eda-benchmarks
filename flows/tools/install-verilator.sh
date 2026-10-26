#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
print_pin=0
if [[ ${1:-} == --pin ]]; then
  print_pin=1
  shift
fi
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  printf 'Usage: %s [--pin] <design.variant> [installation-directory]\n' "$0"
  exit 0
fi
[[ $# -ge 1 && $# -le 2 ]] || {
  printf 'Usage: %s [--pin] <design.variant> [installation-directory]\n' "$0" >&2
  exit 2
}
design=$1
mode=source
cc=clang-18
cxx=clang++-18
case "$design" in
  ara.default)
    pin=06263ec724e7bf1fb0a0366b3aec54cd431c51d6 ;;
  nvdla.top|mempool.minpool|mempool.mempool|mempool.terapool)
    pin=746c7ea8f786e1183f15c28727cbc0c44e9b556e
    cc=gcc
    cxx=g++ ;;
  ita.default|ibex.minimal|ibex.full|serial_link.default)
    pin=ea338be98e1e838d3518809ce8899f85a009963c ;;
  cvfpu.full|cvfpu.fp32_fma|spi_host.default)
    pin=08bbef72acdc8f3ec5b27e3275e75475bc974e2b ;;
  cv32e40p.default|cva6.default|cheshire.default|opope.default|pulp_c910.default|redmule.default|snitch_cluster.minimal|snitch_cluster.default|snitch_cluster.default_latch|spatz.default)
    mode=python
    pin=5.48.0 ;;
  *) printf 'No pinned simulator for design: %s\n' "$design" >&2; exit 2 ;;
esac
if [[ $print_pin == 1 ]]; then
  printf '%s\n' "$pin"
  exit 0
fi
install_root=${2:-$here/install/verilator}
mkdir -p "$install_root"
install_root=$(cd "$install_root" && pwd)
prefix="$install_root/$pin"
printf 'Preparing Verilator %s for %s.\n' "$pin" "$design" >&2
if [[ $mode == python ]]; then
  command="$prefix/bin/verilator-cli"
  if [[ ! -x $command || ! -f $prefix/.complete ]]; then
    "${PYTHON:-python3}" -m venv "$prefix" >&2
    "$prefix/bin/python" -m pip install "verilator==$pin" >&2
    touch "$prefix/.complete"
  fi
else
  command="$prefix/bin/verilator"
  if [[ ! -x $command || ! -f $prefix/.complete ]]; then
    source_dir="$here/build/verilator/$pin"
    if [[ ! -d $source_dir/.git ]]; then
      mkdir -p "$source_dir"
      git -C "$source_dir" init -q >&2
      git -C "$source_dir" remote add origin https://github.com/verilator/verilator.git >&2
    fi
    if ! git -C "$source_dir" cat-file -e "$pin^{commit}" 2>/dev/null; then
      git -C "$source_dir" fetch --depth 1 origin "$pin" >&2
    fi
    git -C "$source_dir" checkout --detach --force "$pin" >&2
    (
      cd "$source_dir"
      autoconf
      CC=${CC:-$cc} CXX=${CXX:-$cxx} ./configure --prefix="$prefix"
      make -j"${JOBS:-1}"
      make install
    ) >&2
    touch "$prefix/.complete"
  fi
fi
printf '%s\n' "$command"
