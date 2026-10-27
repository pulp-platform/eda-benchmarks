#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/.." && pwd)
family=${1:?Pass the design family}
source_dir=$(realpath -e -- "${2:?Pass the design source directory}")
[[ $family =~ ^[a-zA-Z0-9_]+$ && -f $script_dir/$family/setup.sh ]] || {
  printf 'Unknown testbench family: %s\n' "$family" >&2
  exit 2
}
design_dir="$script_dir/$family"
source "$script_dir/common/setup-cache.sh"
cache_key=$(testbench_recipe_key "$root" "$family" "$source_dir" "${PYTHON:-python3}")
cache_stamp="$design_dir/.preparation-key"
if [[ ! -f $cache_stamp || $(cat "$cache_stamp") != "$cache_key" ]]; then
  rm -rf -- "$design_dir/build" "$design_dir/data" "$design_dir/.venv" \
    "$design_dir"/variants/*/data
fi
rm -f -- "$cache_stamp"
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
printf '%s\n' "$cache_key" > "$cache_stamp"
