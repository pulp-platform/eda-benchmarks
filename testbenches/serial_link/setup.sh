#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
mkdir -p "$script_dir/data/tb_axi_slink"
: > "$script_dir/data/tb_axi_slink/testcases.txt"
for reads1 in 0 100; do
  for writes1 in 0 100; do
    for reads2 in 0 100; do
      for writes2 in 0 100; do
        name="r${reads1}_w${writes1}_r${reads2}_w${writes2}"
        mkdir -p "$script_dir/data/tb_axi_slink/$name"
        printf '%s\n' "+NUM_READS_1=$reads1" "+NUM_WRITES_1=$writes1" \
          "+NUM_READS_2=$reads2" "+NUM_WRITES_2=$writes2" > "$script_dir/data/tb_axi_slink/$name/run.args"
        printf '%s\n' "$name" >> "$script_dir/data/tb_axi_slink/testcases.txt"
      done
    done
  done
done
printf '%s\n' "Serial Link: $(git -C "$root/deps/serial_link" rev-parse HEAD)" \
  'Upstream .gitlab-ci.yml: tb_axi_slink, NUM_CHANNELS=1, all 16 0/100 transaction combinations' \
  > "$script_dir/data/tb_axi_slink/README.txt"
