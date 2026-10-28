#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
args=()
while (( $# )); do
  case $1 in
    -j|--jobs) shift; [[ ${1:-} != [0-9]* ]] || shift ;;
    -j*|--jobs=*) shift ;;
    *) args+=("$1"); shift ;;
  esac
done
exec "${BENCH_MAKE:-make}" "${args[@]}"
