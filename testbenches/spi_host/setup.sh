#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
source "$root/testbenches/common/fetch-source.sh"
source "$root/testbenches/common/fetch-archive.sh"
host="$script_dir/build/host"
fetch_source https://github.com/lowRISC/opentitan.git \
  9f497f6339b4484fc5b7e5dc5d4bc63f55ec3c35 "$host/opentitan"
for patch in "$root/testbenches/spi_host/patches/"*.patch; do
  git -C "$host/opentitan" apply "$patch"
done
mark_testbench_changes "$host/opentitan"
"${PYTHON:-python3}" -m venv "$script_dir/.venv"
"$script_dir/.venv/bin/python" -m pip install --disable-pip-version-check \
  'setuptools==80.9.0' 'setuptools_scm==8.3.1' 'wheel==0.45.1'
"$script_dir/.venv/bin/python" -m pip install --disable-pip-version-check \
  --no-cache-dir \
  'fusesoc @ git+https://github.com/lowRISC/fusesoc.git@cf222fa5c9351d09cec13cdaea4602905fa696d0' \
  'edalize @ git+https://github.com/lowRISC/edalize.git@2a70c4421db186b4ec91c770addc89ec83f3818b' \
  'hjson==3.1.0' \
  'Mako==1.3.10' \
  'PyYAML==6.0.2' \
  'tabulate==0.9.0' \
  'mistletoe==1.4.0'
mkdir -p "$script_dir/downloads" "$host/backend"
archive="$script_dir/downloads/uvm-1.2.tar.gz"
fetch_archive https://www.accellera.org/images/downloads/standards/uvm/uvm-1.2.tar.gz \
  502a2e605ce552bfd9767803c7e99a053715b00f7a9c4c511c3fbfddfb30157c "$archive"
extract_archive "$archive" "$host/uvm-1.2"
curl -fL --retry 3 \
  https://raw.githubusercontent.com/verilator/verilator/08bbef72acdc8f3ec5b27e3275e75475bc974e2b/test_regress/t/uvm/v2020_3_1/dpi/uvm_hdl_verilator.c \
  -o "$host/backend/uvm_hdl_verilator.c"
cp "$root/LICENSE.Apache-2.0" "$host/backend/LICENSE"
cp "$host/opentitan/LICENSE" "$host/LICENSE.opentitan"
cp "$script_dir/uvm-support.cpp" "$host/"
(
  cd "$host"
  PATH="$script_dir/.venv/bin:$PATH" fusesoc --cores-root "$host/opentitan" \
    run --target=sim --tool=verilator --setup lowrisc:dv:spi_host_sim
)
"$script_dir/.venv/bin/python" "$script_dir/prepare.py"
