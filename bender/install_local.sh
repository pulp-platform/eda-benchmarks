#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

bender_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bender_version=${BENDER_VERSION:-0.32.1}

if [[ -v BENDER ]]; then
  bender=$BENDER
  [[ -x $bender ]] || {
    printf 'Bender executable not found: %s\n' "$bender" >&2
    exit 1
  }
  bender_action='Continuing with the selected executable.'
else
  bender="$bender_root/bin/bender"
  bender_action="Replacing it with bender $bender_version."
fi

# Keep stdout reserved for the executable path consumed by setup.sh.
if [[ -x $bender ]]; then
  if bender_installed_version=$("$bender" --version 2>/dev/null); then
    if [[ $bender_installed_version == "bender $bender_version" ]]; then
      printf '%s\n' "$bender"
      exit 0
    fi
    printf 'Warning: %s reports "%s"; expected bender %s. %s\n' \
      "$bender" "$bender_installed_version" "$bender_version" "$bender_action" >&2
  else
    printf 'Warning: could not determine the version of %s; expected bender %s. %s\n' \
      "$bender" "$bender_version" "$bender_action" >&2
  fi
fi

if [[ -v BENDER ]]; then
  printf '%s\n' "$bender"
  exit 0
fi

case "$(uname -s):$(uname -m)" in
  Linux:x86_64|Linux:amd64) bender_target=x86_64-unknown-linux-gnu ;;
  Linux:aarch64|Linux:arm64) bender_target=aarch64-unknown-linux-gnu ;;
  Darwin:x86_64) bender_target=x86_64-apple-darwin ;;
  Darwin:arm64) bender_target=aarch64-apple-darwin ;;
  *)
    printf 'Unsupported Bender platform: %s %s\n' "$(uname -s)" "$(uname -m)" >&2
    exit 2
    ;;
esac

bender_asset="bender-$bender_target.tar.xz"
bender_release="https://github.com/pulp-platform/bender/releases/download/v$bender_version"
bender_temporary=$(mktemp -d)
trap 'find "$bender_temporary" -depth -delete' EXIT

curl --fail --location --silent --show-error \
  "$bender_release/$bender_asset" --output "$bender_temporary/$bender_asset"
curl --fail --location --silent --show-error \
  "$bender_release/$bender_asset.sha256" \
  --output "$bender_temporary/$bender_asset.sha256"

bender_expected=$(awk 'NR == 1 { print $1 }' "$bender_temporary/$bender_asset.sha256")
if command -v sha256sum >/dev/null; then
  bender_actual=$(sha256sum "$bender_temporary/$bender_asset" | awk '{ print $1 }')
elif command -v shasum >/dev/null; then
  bender_actual=$(shasum -a 256 "$bender_temporary/$bender_asset" | awk '{ print $1 }')
else
  printf 'Bender setup requires sha256sum or shasum\n' >&2
  exit 1
fi
[[ $bender_actual == "$bender_expected" ]] || {
  printf 'Bender checksum mismatch for %s\n' "$bender_asset" >&2
  exit 1
}

tar -xJf "$bender_temporary/$bender_asset" -C "$bender_temporary"
bender_binary=$(find "$bender_temporary" -type f -name bender -print -quit)
[[ -n $bender_binary ]] || {
  printf 'Bender binary missing from %s\n' "$bender_asset" >&2
  exit 1
}
mkdir -p "$bender_root/bin"
install -m 0755 "$bender_binary" "$bender"
printf '%s\n' "$bender"
