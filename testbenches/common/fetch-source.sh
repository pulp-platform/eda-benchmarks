#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
fetch_source() {
  local url=$1 revision=$2 destination=$3
  if [[ ! -d $destination/.git ]]; then
    mkdir -p "$destination"
    git -C "$destination" init -q
    git -C "$destination" remote add origin "$url"
  fi
  if ! git -C "$destination" cat-file -e "$revision^{commit}" 2>/dev/null; then
    git -C "$destination" fetch --depth 1 origin "$revision"
  fi
  git -C "$destination" checkout --detach --force "$revision"
}

mark_testbench_changes() {
  local repository=$1 source
  while IFS= read -r -d '' source; do
    [[ -f $repository/$source ]] || continue
    sed -i '1 {
      /^\/\/ Modified by the PULP benchmark suite\.$/!i\
// Modified by the PULP benchmark suite.
    }' "$repository/$source"
  done < <(git -C "$repository" diff --name-only -z -- '*.sv' '*.svh')
}
