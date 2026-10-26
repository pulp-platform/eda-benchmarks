#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
copy_licenses() {
  local source_dir=${1:?Pass the source directory}
  local destination=${2:?Pass the license destination}
  local source relative
  [[ -d $source_dir ]] || { printf 'Missing source directory: %s\n' "$source_dir" >&2; return 1; }
  while IFS= read -r -d '' source; do
    relative=${source#"$source_dir"/}
    mkdir -p "$destination/$(dirname "$relative")"
    cp "$source" "$destination/$relative"
  done < <(find "$source_dir" -type d -name .git -prune -o -type f \
    \( -iname 'LICENSE*' -o -iname 'COPYING*' -o -iname 'NOTICE*' -o \
       -iname 'COPYRIGHT*' -o -iname 'README.license*' -o -path '*/LICENSES/*' \) \
    -print0)
}
