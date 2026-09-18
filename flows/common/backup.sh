#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Back up existing paths with one shared timestamp, taken from the first path.
# Missing paths are skipped. Log suffixes are inserted before the .log extension.
if (( $# == 0 )); then
  printf 'Usage: %s <path> [<path> ...]\n' "$0" >&2
  exit 2
fi

paths=()
for path in "$@"; do
  if [[ -e $path || -L $path ]]; then
    paths+=("$path")
  fi
done
(( ${#paths[@]} > 0 )) || exit 0

timestamp_path=${paths[0]}
backup_epoch=$(stat -c %W -- "$timestamp_path")
if (( backup_epoch <= 0 )); then
  printf 'Creation time unavailable for %s; using modification time for the backup names.\n' "$timestamp_path"
  backup_epoch=$(stat -c %Y -- "$timestamp_path")
fi
backup_time=$(date -u -d "@$backup_epoch" +%Y%m%d-%H%M%S)
backup_suffix=$backup_time
backup_index=0

backup_name() {
  if [[ ! -d $1 && $1 == *.log ]]; then
    printf '%s-%s.log' "${1%.log}" "$backup_suffix"
  else
    printf '%s-%s' "$1" "$backup_suffix"
  fi
}

# A collision for any path advances the suffix for the entire group.
while true; do
  collision=0
  for path in "${paths[@]}"; do
    destination=$(backup_name "$path")
    if [[ -e $destination || -L $destination ]]; then
      collision=1
      break
    fi
  done
  (( collision == 1 )) || break
  backup_index=$((backup_index + 1))
  backup_suffix=$backup_time-$backup_index
done

for path in "${paths[@]}"; do
  destination=$(backup_name "$path")
  printf 'Preserving previous output: %s -> %s\n' "$path" "$destination"
  mv -- "$path" "$destination"
done
