#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

toolchain_build_settings() {
  local variable
  printf '%s\n' "$(uname -s)" "$(uname -m)"
  for variable in CC CXX CFLAGS CXXFLAGS CPPFLAGS LDFLAGS AR AS LD RANLIB CMAKE_GENERATOR TOOLCHAIN_NAME; do
    printf '%s=%s\n' "$variable" "${!variable-}"
  done
}

toolchain_keys_match() {
  local install=$1 key expected
  shift
  while (( $# )); do
    key=$1 expected=$2
    shift 2
    [[ -f $install/$key && $(cat "$install/$key") == "$expected" ]] || return 1
  done
}

toolchain_cache_matches() {
  local compiler=$1 install
  shift
  [[ -x $compiler ]] || return 1
  install=$(dirname "$(dirname "$(realpath -e -- "$compiler")")")
  toolchain_keys_match "$install" "$@"
}
