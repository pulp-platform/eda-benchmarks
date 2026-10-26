#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
source "$root/testbenches/common/fetch-source.sh"
host="$script_dir/build/host"
fetch_source https://github.com/openhwfoundation/cvfpu-uvm.git \
  2f787402256b76d00e397d72a00b57120db455cf "$host/cvfpu-uvm"
fetch_source https://github.com/openhwgroup/core-v-verif.git \
  1dfa4836868fc2fc8e3754ee5c1c43fb42948aa3 "$host/cvfpu-uvm/modules/core-v-verif"
archive="$script_dir/downloads/uvm-1.1d.tar.gz"
mkdir -p "$script_dir/downloads"
if [[ ! -f $archive ]]; then
  curl -fL --retry 3 https://www.accellera.org/images/downloads/standards/uvm/uvm-1.1d.tar.gz -o "$archive.part"
  mv "$archive.part" "$archive"
fi
printf '%s  %s\n' b6f74e64dda5efa08e86dd15c22e921c404dd7d4eb4334ab62afe61fca0f6369 "$archive" | sha256sum -c - >&2
rm -rf -- "$host/uvm"
mkdir -p "$host/uvm"
tar xf "$archive" --strip-components=1 -C "$host/uvm"
git -C "$host/cvfpu-uvm" apply "$script_dir"/patches/*.patch
mark_testbench_changes "$host/cvfpu-uvm"
"${PYTHON:-python3}" "$script_dir/generate-shim.py" \
  "$host/cvfpu-uvm/ref_model_csim/cpp/include/dpiheader.h" \
  "$host/cvfpu-uvm/ref_model_csim/cpp/src/verilator_shim.cpp"
cp "$script_dir/uvm-support.cpp" "$host/"
"${PYTHON:-python3}" "$script_dir/prepare.py"
