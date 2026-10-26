#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
design_dir="$script_dir/$1"
bash "$design_dir/setup.sh"
for variant in "$design_dir"/variants/*; do
  for list in "$variant"/verilator/*/cpp_files.txt "$variant"/verilator/*/cpp_include_dirs.txt; do
    [[ -f $list ]] || continue
    while IFS= read -r path || [[ -n $path ]]; do
      [[ -n $path ]] || continue
      if [[ $list == */cpp_include_dirs.txt ]]; then
        [[ -d $variant/$path ]] && continue
      else
        [[ -f $variant/$path ]] && continue
      fi
      printf 'Missing or invalid C++ path in %s: %s\n' "$list" "$path" >&2
      exit 1
    done < "$list"
  done
done
