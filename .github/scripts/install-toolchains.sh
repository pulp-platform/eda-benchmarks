#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

selection=${1:?Pass the design variant or all}
directory=${2:?Pass the installation directory}
mkdir -p "$directory"
directory=$(cd "$directory" && pwd)
case ${selection%%.*} in
  all) installers=(ara/tools/gcc.sh ara/tools/llvm.sh cva6/tools/gcc.sh mempool/tools/gcc.sh
    common/tools/pulp-gcc.sh 'common/tools/pulp-gcc.sh rv32imc' spatz/tools/llvm.sh
    cheshire/tools/gcc.sh ibex/tools/gcc.sh redmule/tools/gcc.sh pulp_c910/tools/gcc.sh snitch_cluster/tools/llvm.sh) ;;
  ara) installers=(ara/tools/gcc.sh ara/tools/llvm.sh) ;;
  cva6|mempool|cheshire|ibex|redmule|pulp_c910) installers=("${selection%%.*}/tools/gcc.sh") ;;
  opope) installers=(common/tools/pulp-gcc.sh) ;;
  cv32e40p) installers=('common/tools/pulp-gcc.sh rv32imc') ;;
  spatz) installers=(spatz/tools/llvm.sh common/tools/pulp-gcc.sh) ;;
  snitch_cluster) installers=(snitch_cluster/tools/llvm.sh) ;;
  *) installers=() ;;
esac
for entry in "${installers[@]}"; do
  read -r installer argument <<< "$entry"
  installer=$(realpath -e -- "$script_dir/../../testbenches/$installer")
  args=()
  [[ -z $argument ]] || args=("$argument")
  name=$("$installer" --name "${args[@]}")
  install="$directory/$name"
  if [[ -f ${installer%/*}/build-${installer##*/} ]]; then
    repository=${TOOLCHAIN_REPOSITORY:-pulp-platform/eda-benchmarks}
    tag="toolchain-$name"
    if [[ $(gh release view "$tag" --repo "$repository" --json isDraft --jq '.isDraft') != true ]]; then
      printf 'Compiler release %s must remain a draft.\n' "$tag" >&2
      exit 1
    fi
    artifact=$(mktemp -d "$directory/toolchain.XXXXXX")
    trap 'rm -rf -- "$artifact"' EXIT
    asset_names=$(gh release view "$tag" --repo "$repository" --json assets --jq '.assets[].name')
    archive="$name-linux-x86_64.tar.xz"
    if ! grep -Fxq "$archive" <<< "$asset_names" || ! grep -Fxq "$archive.sha256" <<< "$asset_names"; then
      archive="$name-linux-x86_64.tar.gz"
    fi
    gh release download "$tag" --repo "$repository" --dir "$artifact" \
      --pattern "$archive" --pattern "$archive.sha256"
    (cd "$artifact" && sha256sum -c "$archive.sha256" >&2)
    rm -rf -- "$install"
    mkdir -p "$install"
    tar -xf "$artifact/$archive" -C "$install"
    [[ -x $install/bin/$name ]]
    "$installer" --check "$install" "${args[@]}" || {
      printf 'Compiler release %s does not match the current build recipe; prepare it again.\n' "$tag" >&2
      exit 1
    }
    rm -rf -- "$artifact"
    trap - EXIT
    printf '%s\n' "$install/bin"
    continue
  fi
  install=$(TOOLCHAIN_WORK_DIR="$directory/build/$name" "$installer" "${args[@]}")
  if [[ ${installer##*/} == llvm.sh ]]; then
    compiler=clang
  else
    compilers=("$install/bin/"*-gcc)
    compiler=${compilers[0]##*/}
  fi
  ln -sfn "$compiler" "$install/bin/$name"
  printf '%s\n' "$install/bin"
done
