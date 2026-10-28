#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

fetch_archive() {
  local url=${1:?Pass the URL} checksum=${2:?Pass the SHA256} archive=${3:?Pass the archive path}
  if [[ -f $archive ]] && printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c --status; then
    return 0
  fi
  mkdir -p "$(dirname "$archive")"
  curl -fL --retry 3 "$url" -o "$archive.part" || return
  if ! printf '%s  %s\n' "$checksum" "$archive.part" | sha256sum -c - >&2; then
    rm -f -- "$archive.part"
    return 1
  fi
  mv "$archive.part" "$archive"
}

extract_archive() {
  local archive=${1:?Pass the archive path} destination=${2:?Pass the extraction directory}
  rm -rf -- "$destination"
  mkdir -p "$destination"
  tar -xf "$archive" --strip-components=1 -C "$destination"
}
