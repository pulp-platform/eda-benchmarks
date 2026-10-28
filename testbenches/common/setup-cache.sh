#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

testbench_recipe_key() {
  local root=$1 family=$2 source=$3 python=$4 file variable
  (
    set -e
    cd "$root"
    while IFS= read -r -d '' file; do
      [[ -f $file ]] && sha256sum "$file"
    done < <(git ls-files -z --cached --others --exclude-standard -- \
      setup.sh testbenches/setup.sh "testbenches/$family" testbenches/common \
      "patches/$family" "bender/$family")
    git -C "$source" rev-parse HEAD
    "$python" --version
    for variable in CC CXX CFLAGS CXXFLAGS CPPFLAGS LDFLAGS AR AS LD RANLIB CMAKE_GENERATOR TOOLCHAIN_NAME; do
      printf '%s=%s\n' "$variable" "${!variable-}"
    done
  ) | sha256sum | cut -d ' ' -f1
}
