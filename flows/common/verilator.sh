#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

common_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
package_root=$(cd -- "$common_dir/.." && pwd)
[[ $# -ge 3 && $1 =~ ^(list|build|run)$ && $2 =~ ^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$ && $3 =~ ^[a-zA-Z0-9_]+$ ]] || {
  printf 'Usage: %s <list|build|run> <design.variant> <test> [testcase]\n' "$0" >&2
  exit 2
}
mode=$1
target=$2
test_name=$3
variant_dir="$package_root/${target%%.*}/variants/${target#*.}"
test_dir="$variant_dir/verilator/$test_name"
data_dir="$package_root/${target%%.*}/data/$test_name"
[[ ! -d $variant_dir/data/$test_name ]] || data_dir="$variant_dir/data/$test_name"
if [[ $mode == list ]]; then
  if [[ -f $data_dir/testcases.txt ]]; then
    mapfile -t testcases < "$data_dir/testcases.txt"
    (( ${#testcases[@]} > 0 )) || { printf 'No simulation testcases listed\n' >&2; exit 1; }
    declare -A seen_testcases=()
    for testcase in "${testcases[@]}"; do
      [[ $testcase =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ && -z ${seen_testcases[$testcase]:-} ]] || {
        printf 'Invalid or duplicate simulation testcase: %s\n' "$testcase" >&2; exit 1;
      }
      seen_testcases[$testcase]=1
    done
    printf '%s\n' "${testcases[@]}"
  else
    printf '@default\n'
  fi
  exit
fi
if [[ $mode == build && -z ${VERILATOR_COMMAND:-} ]]; then
  printf 'Set VERILATOR_COMMAND to a Verilator executable compatible with the selected design.\n' >&2
  exit 2
fi
make_flags=${MAKEFLAGS:-}
if [[ $mode == build && ${make_flags%% *} == *n* ]]; then
  printf 'Would build %s/%s\n' "$target" "$test_name"
  exit
fi
[[ -s $test_dir/filelist.f ]] || {
  printf 'Missing Verilator input: %s/filelist.f\n' "$test_dir" >&2
  exit 2
}
top=${BENCH_TOP:-}
[[ $top =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
  printf 'Invalid Verilator top: %s\n' "$top" >&2
  exit 2
}
timeout_seconds=${TIMEOUT:-0}
seed=${SEED:-1}
[[ $seed =~ ^[1-9][0-9]*$ ]] || {
  printf 'SEED must be a positive integer\n' >&2
  exit 2
}
[[ $timeout_seconds =~ ^[0-9]+$ ]] || {
  printf 'TIMEOUT must be a nonnegative integer (0 disables the limit)\n' >&2
  exit 2
}
command -v timeout >/dev/null

build_dir="$variant_dir/build/verilator/$test_name"
log_dir="$variant_dir/logs/verilator/$test_name"
if [[ $mode == build ]]; then
  verilator_executable=$(command -v -- "$VERILATOR_COMMAND") || {
    printf 'Verilator not found: %s\n' "$VERILATOR_COMMAND" >&2
    exit 127
  }
  [[ $verilator_executable == /* ]] || verilator_executable=$PWD/$verilator_executable
  if [[ ${verilator_executable##*/} == verilator-cli ]]; then
    export PATH="${verilator_executable%/*}:$PATH"
    verilator_root=$("$verilator_executable" --getenv VERILATOR_ROOT)
    verilator_executable="$verilator_root/bin/verilator"
    export VERILATOR_ROOT="$verilator_root"
    export MAKEFLAGS="${MAKEFLAGS:-} CFG_CXXFLAGS_PCH_I=-include"
    if [[ -z ${CXXFLAGS+x} ]]; then
      export CXXFLAGS='--std=c++20'
    fi
  fi
  extra_args=()
  if [[ -f $test_dir/verilator.vlt ]]; then
    extra_args+=("$test_dir/verilator.vlt")
  fi
  if [[ -f $test_dir/verilator.args ]]; then
    while IFS= read -r arg || [[ -n $arg ]]; do
      [[ -z $arg || $arg == \#* ]] || extra_args+=("$arg")
    done < "$test_dir/verilator.args"
  fi

  if [[ -f $test_dir/cpp_include_dirs.txt ]]; then
    while IFS= read -r directory || [[ -n $directory ]]; do
      [[ -n $directory ]] || continue
      extra_args+=(-CFLAGS "-I$variant_dir/$directory")
    done < "$test_dir/cpp_include_dirs.txt"
  fi

  if [[ -f $test_dir/pkg_config.txt ]]; then
    mapfile -t host_packages < "$test_dir/pkg_config.txt"
    command -v pkg-config >/dev/null
    pkg-config --exists "${host_packages[@]}" || {
      printf 'Missing host libraries: %s. Set PKG_CONFIG_PATH to their lib/pkgconfig directory.\n' "${host_packages[*]}" >&2
      exit 1
    }
    host_cflags=$(pkg-config --cflags "${host_packages[@]}")
    host_ldflags=$(pkg-config --libs "${host_packages[@]}")
    [[ -z $host_cflags ]] || extra_args+=(-CFLAGS "$host_cflags")
    [[ -z $host_ldflags ]] || extra_args+=(-LDFLAGS "$host_ldflags")
  fi

  cpp_sources=()

  if [[ -f $test_dir/cpp_files.txt ]]; then
    while IFS= read -r source || [[ -n $source ]]; do
      [[ -n $source ]] || continue
      cpp_sources+=("$variant_dir/$source")
    done < "$test_dir/cpp_files.txt"
  fi

  "$common_dir/backup.sh" "$build_dir" "$log_dir"
  mkdir -p "$build_dir" "$log_dir"
  cd -- "$variant_dir"
  ulimit -c 0
  printf 'Building %s/%s (top %s)\n' "$target" "$test_name" "$top"
  verilator_filelist="$test_dir/filelist.f"
  for arg in "${extra_args[@]}"; do
    if [[ $arg == --hierarchical ]]; then
      verilator_filelist="$build_dir/sources.f"
      : > "$verilator_filelist"
      while IFS= read -r entry || [[ -n $entry ]]; do
        if [[ $entry == +* ]]; then
          extra_args+=("$entry")
        else
          printf '%s\n' "$entry" >> "$verilator_filelist"
        fi
      done < "$test_dir/filelist.f"
      break
    fi
  done
  MAKE="$common_dir/verilator-make.sh" timeout --kill-after=5s "${timeout_seconds}s" "$verilator_executable" \
    -Wno-fatal \
    --top-module "$top" --Mdir "$build_dir" \
    "${extra_args[@]}" -f "$verilator_filelist" "${cpp_sources[@]}" 2>&1 | tee "$log_dir/build.log"

  exit
fi
ulimit -c 0
run_args=()
if [[ -f $test_dir/run.args ]]; then
  while IFS= read -r arg || [[ -n $arg ]]; do
    [[ -z $arg || $arg == \#* ]] || run_args+=("${arg//'${DATA_DIR}'/$data_dir}")
  done < "$test_dir/run.args"
fi

verilator_seed() {
  local selected=$seed arg
  for arg in "${run_args[@]}" "$@"; do
    [[ $arg != +verilator+seed+* ]] || selected=${arg#+verilator+seed+}
  done
  printf '%s' "$selected"
}

run_simulation() {
  local run_log=$1
  shift
  if ! timeout --kill-after=5s "${timeout_seconds}s" "${simulation_command[@]}" \
    "+verilator+seed+$seed" "${run_args[@]}" "$@" 2>&1 | tee "$run_log"; then
    printf 'Simulation failed: %s\n' "$run_log" >&2
    return 1
  fi
  grep -Fxq -- 'TEST PASSED' "$run_log" || {
    printf 'Simulation exited without its success message: %s\n' "$run_log" >&2
    return 1
  }
}

run_in_directory() {
  local directory=$1 result=0
  shift
  mkdir -p "$directory/logs"
  ln -sfn "$variant_dir/verilator" "$directory/verilator"
  (cd "$directory" && run_simulation "$directory/run.log" "$@") || result=$?
  rm -- "$directory/verilator"
  return "$result"
}

testcase=${4:-@default}
case_data_dir=$data_dir
if [[ $testcase == @default ]]; then
  directory="$log_dir"
else
  [[ $testcase =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]] || {
    printf 'Invalid simulation testcase: %s\n' "$testcase" >&2; exit 2;
  }
  directory="$log_dir/$testcase"
  case_data_dir="$data_dir/$testcase"
  if [[ -f $data_dir/$testcase/run.args ]]; then
    while IFS= read -r arg || [[ -n $arg ]]; do
      [[ -z $arg || $arg == \#* ]] || run_args+=("${arg//'${DATA_DIR}'/$data_dir}")
    done < "$data_dir/$testcase/run.args"
  fi
fi
simulation_command=("$build_dir/V$top")
if [[ -f $data_dir/run.py ]]; then
  python_command=${PYTHON:-python3}
  python_key=$(
    {
      sha256sum "$data_dir/requirements.txt"
      "$python_command" -c 'import os, sys; print(os.path.realpath(sys.executable)); print(sys.version)'
    } | sha256sum | cut -d ' ' -f1
  )
  python_cache="$variant_dir/build/python/$test_name"
  python_venv="$python_cache/$python_key"
  mkdir -p "$python_cache" "$log_dir"
  (
    flock 9
    if [[ ! -f $python_venv/.ready || ! -x $python_venv/bin/python ]]; then
      printf 'Preparing Python environment for %s/%s\n' "$target" "$test_name"
      "$python_command" -m venv --clear "$python_venv"
      "$python_venv/bin/python" -m pip install --disable-pip-version-check --no-cache-dir \
        -r "$data_dir/requirements.txt" 2>&1 | tee "$log_dir/python-setup.log"
      touch "$python_venv/.ready"
    fi
  ) 9> "$python_cache/.lock"
  simulation_command=("$python_venv/bin/python" "$data_dir/run.py" "$case_data_dir" "$build_dir/V$top")
fi
printf 'Running %s/%s/%s (seed %s)\n' "$target" "$test_name" "$testcase" "$(verilator_seed)"
run_in_directory "$directory"
