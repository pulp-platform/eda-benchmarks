#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
output="$root/benchmarks"

if [[ -e $output || -L $output ]]; then
  printf 'benchmarks already exists\n'
  exit 1
fi

python_command=${PYTHON:-python3}
cleanup_enabled=0
temporary_output=

targets=(
  ara.default cheshire.default cv32e40p.default cva6.default
  cvfpu.fp32_fma cvfpu.full
  ibex.minimal ibex.full
  ita.default
  mempool.minpool mempool.mempool mempool.terapool
  nvdla.top opope.default pulp_c910.default redmule.default
  serial_link.default
  snitch_cluster.minimal snitch_cluster.default
  snitch_cluster.default_latch snitch_cluster.occamy
  spatz.default spi_host.default
)

# Most design families use a same-named repository. These are the exceptions.
declare -A main_repositories=(
  [nvdla]=nvdla_hw
  [spi_host]=opentitan_peripherals
)

# Add the generic SRAM declarations only to designs whose exported RTL refers
# to tc_sram or tc_sram_impl. Other designs should not carry unused stubs.
declare -A sram_stub_families=(
  [ara]=1
  [cheshire]=1
  [cva6]=1
  [ita]=1
  [mempool]=1
  [pulp_c910]=1
  [redmule]=1
  [snitch_cluster]=1
  [spatz]=1
)

# Track patched sources so exported copies can carry modification notices
# without changing the checkouts used for patch application and reversal.
declare -A modified_sources=()
record_patch_sources() {
  local target=$1 patch=$2 stats added removed path
  stats=$(git -C "$root" apply --numstat "$patch")
  while IFS=$'\t' read -r added removed path; do
    [[ -n $path && -f $target/$path ]] || continue
    modified_sources["$(realpath -e -- "$target/$path")"]=1
  done <<< "$stats"
}

copy_rtl() {
  local source=$1 destination=$2
  if [[ -n ${modified_sources[$source]:-} ]]; then
    {
      printf '// Modified by pulp-benchmarks: benchmark compatibility changes.\n'
      cat "$source"
    } > "$destination"
  else
    cp "$source" "$destination"
  fi
}

# Apply every patch in a directory to a checked-out Git repository.
apply_patch_directory() {
  local target=$1 patch_directory=$2 patch
  [[ -d $patch_directory ]] || return 0
  for patch in "$patch_directory"/*.patch; do
    [[ -f $patch ]] || continue
    if (cd "$target" && git apply --check "$patch"); then
      (cd "$target" && git apply "$patch")
    elif (cd "$target" && git apply --reverse --check "$patch"); then
      : # Already applied to a persistent Bender checkout.
    else
      printf 'Patch does not apply cleanly: %s -> %s\n' "$patch" "$target" >&2
      return 1
    fi
    record_patch_sources "$target" "$patch"
  done
}

# Generated NVDLA files are ignored by Git and need directory-aware patching.
apply_generated_patch_directory() {
  local target=$1 patch_directory=$2 patch git_root relative_target
  [[ -d $patch_directory ]] || return 0
  git_root=$(git -C "$target" rev-parse --show-toplevel)
  relative_target=${target#"$git_root"/}
  for patch in "$patch_directory"/*.patch; do
    [[ -f $patch ]] || continue
    if git -C "$git_root" apply --check --whitespace=nowarn \
        --directory="$relative_target" "$patch"; then
      git -C "$git_root" apply --whitespace=nowarn \
        --directory="$relative_target" "$patch"
    elif git -C "$git_root" apply --reverse --check --whitespace=nowarn \
        --directory="$relative_target" "$patch"; then
      : # Already applied.
    else
      printf 'Patch does not apply cleanly: %s -> %s\n' "$patch" "$target" >&2
      return 1
    fi
    record_patch_sources "$target" "$patch"
  done
}

# Restore selected checkouts and remove generated files on exit.
restore_submodules() {
  local path
  (( cleanup_enabled == 1 )) || return 0
  for path in "${selected_repositories[@]}"; do
    git -C "$root/$path" reset --hard HEAD >/dev/null
    git -C "$root/$path" clean -fdx >/dev/null
  done
}
cleanup() {
  if [[ -n $temporary_output ]]; then
    rm -rf -- "$temporary_output"
  fi
  restore_submodules
}
trap cleanup EXIT

# Copy one Bender file-list entry into the self-contained output hierarchy.
map_entry() {
  local value=$1 directory=$2
  local source destination relative name dependency_root main_root path target
  if [[ $value == /* ]]; then
    source=$(realpath -e -- "$value")
  else
    source=$(realpath -e -- "$recipe/$value")
  fi

  # Place every source according to its origin. This preserves enough of the
  # upstream hierarchy for include paths while omitting unrelated repository
  # contents such as tests, documentation, and Git metadata.
  main_root="$root/deps/${main_repositories[$family]:-$family}"
  if [[ $family == snitch_cluster && \
        $source == "$main_root/hw/generated/snitch_cluster_wrapper_pkg.sv" ]]; then
    destination="$variant_output/snitch_cluster_wrapper_pkg.sv"
  elif [[ $source == "$main_root"/* ]]; then
    relative=${source#"$main_root"/}
    destination="$output/$family/main/$relative"
  elif [[ $source == "$root/support"/* ]]; then
    relative=${source#"$root/support"/}
    destination="$output/$family/support/$relative"
  else
    destination=
    for path in "$root/bender/$family/dependencies"/*; do
      [[ -e $path ]] || continue
      name=$(basename "$path")
      dependency_root=$(realpath -e -- "$path")
      if [[ $source == "$dependency_root" || $source == "$dependency_root"/* ]]; then
        relative=${source#"$dependency_root"/}
        destination="$output/$family/dependencies/$name/$relative"
        break
      fi
    done
    if [[ -z $destination && ($source == "$recipe" || $source == "$recipe"/*) ]]; then
      destination="$variant_output/$(basename "$source")"
    fi
  fi

  [[ -n ${destination:-} ]] || {
    printf 'Filelist entry is outside known roots: %s\n' "$source" >&2
    return 1
  }
  # Include directories may contain non-RTL material, so copy only HDL files.
  # Individual file-list entries are checked separately below.
  if [[ $directory == 1 ]]; then
    mkdir -p "$destination"
    while IFS= read -r -d '' path; do
      relative=${path#"$source"/}
      target="$destination/$relative"
      mkdir -p "$(dirname "$target")"
      copy_rtl "$path" "$target"
    done < <(find "$source" -type f \
      \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' -o -name '*.h' \) \
      -print0)
  else
    case $source in
      *.v|*.sv|*.vh|*.svh|*.h) ;;
      *.vlib) destination=${destination%.vlib}.v ;;
      *) printf 'Non-RTL source in filelist: %s\n' "$source" >&2; return 1 ;;
    esac
    mkdir -p "$(dirname "$destination")"
    copy_rtl "$source" "$destination"
  fi
  realpath --relative-to="$variant_output" -- "$destination"
}

# Select the requested variants and record their design families.
selection=${1:-all}
if [[ $selection == all ]]; then
  selected=("${targets[@]}")
else
  valid=0
  for target in "${targets[@]}"; do
    [[ $selection == "$target" ]] && valid=1
  done
  if (( valid == 0 )); then
    printf 'Usage: %s [all|<design.variant>]\n' "$0" >&2
    exit 2
  fi
  selected=("$selection")
fi

declare -A selected_families=()
selected_repositories=()
for target in "${selected[@]}"; do
  family=${target%%.*}
  [[ -z ${selected_families[$family]:-} ]] || continue
  selected_families[$family]=1
  selected_repositories+=("deps/${main_repositories[$family]:-$family}")
done

# Snitch's generator runs in a fresh, repository-local Python environment.
if [[ -n ${selected_families[snitch_cluster]:-} ]]; then
  command -v "$python_command" >/dev/null || {
    printf 'Snitch generation requires %s\n' "$python_command" >&2
    exit 1
  }
  "$python_command" -c 'import sys; sys.exit(sys.version_info < (3, 10))' || {
    printf 'Snitch generation requires Python 3.10 or newer; select a supported interpreter with PYTHON.\n' >&2
    exit 1
  }
  "$python_command" -c 'import venv' >/dev/null 2>&1 || {
    printf 'Snitch generation requires the Python venv module\n' >&2
    exit 1
  }

  snitch_environment="$root/.venv"
  snitch_python="$snitch_environment/bin/python3"
  "$python_command" -m venv "$snitch_environment"
  "$snitch_python" -m pip --version >/dev/null 2>&1 || {
    printf 'Snitch generation requires pip in the Python virtual environment\n' >&2
    exit 1
  }
  "$snitch_python" -m pip install --disable-pip-version-check \
    'attrs==25.4.0' \
    'json5==0.12.1' \
    'jsonref==1.1.0' \
    'jsonschema==4.25.1' \
    'jsonschema-specifications==2025.9.1' \
    'mako==1.3.10' \
    'markupsafe==3.0.3' \
    'referencing==0.37.0' \
    'rpds-py==0.27.1' \
    'typing-extensions==4.15.0'
fi

# The helper validates BENDER or installs the local release and returns its path.
bender=$("$root/bender/install_local.sh")

# Initialize and validate only the selected designs' pinned repositories.
git -C "$root" submodule update --init -- "${selected_repositories[@]}"
if [[ -n ${selected_families[cva6]:-} ]]; then
  git -C "$root/deps/cva6" submodule update --init --recommend-shallow --depth 1 \
    core/cache_subsystem/hpdcache
fi
for path in "${selected_repositories[@]}"; do
  expected=$(git -C "$root" ls-files -s -- "$path" | awk '{print $2}')
  actual=$(git -C "$root/$path" rev-parse HEAD)
  [[ -n $expected && $actual == "$expected" ]] || {
    printf 'Submodule commit mismatch: %s (expected %s, found %s)\n' \
      "$path" "$expected" "$actual" >&2
    exit 1
  }
  # Cleanup uses clean -fdx, so ignored files must also block preparation.
  status=$(git -C "$root/$path" status --porcelain --untracked-files=all --ignored)
  [[ -z $status ]] || {
    printf 'Submodule has pre-existing changes or ignored files; refusing to continue: %s\n%s\n' \
      "$path" "$status" >&2
    exit 1
  }
done
cleanup_enabled=1

# Prepare each selected design family. Main sources come from Git submodules;
# Bender checks out transitive dependencies into its family-local workspace.
for family_dir in "$root"/bender/*; do
  [[ -d $family_dir/variants ]] || continue
  family=$(basename "$family_dir")
  [[ -n ${selected_families[$family]:-} ]] || continue
  main_repository=${main_repositories[$family]:-$family}
  if [[ $family == nvdla ]]; then
    # Generate NVDLA and replace its simulation RAM models with black boxes.
    nvdla="$root/deps/nvdla_hw"
    out="$nvdla/outdir/nv_small_256_full"

    if [[ -n ${JAVA:-} ]]; then
      java_bin=$JAVA
    elif [[ -n ${JAVA_HOME:-} ]]; then
      java_bin=$JAVA_HOME/bin/java
    else
      java_bin=$(command -v java || true)
    fi
    [[ -n $java_bin && -x $java_bin ]] || {
      printf 'NVDLA generation requires Java; set JAVA or JAVA_HOME\n' >&2
      exit 1
    }

    for prerequisite in cpp gcc g++ perl make; do
      command -v "$prerequisite" >/dev/null || {
        printf 'NVDLA generation requires %s on PATH\n' "$prerequisite" >&2
        exit 1
      }
    done
    command -v "$python_command" >/dev/null || {
      printf 'NVDLA generation requires %s\n' "$python_command" >&2
      exit 1
    }
    perl -MXML::Simple -e 1 >/dev/null 2>&1 || {
      printf 'NVDLA generation requires the Perl XML::Simple module\n' >&2
      exit 1
    }

    cat > "$nvdla/tree.make" <<EOF
PROJECTS := nv_small_256_full
USE_DESIGNWARE := 0
DESIGNWARE_DIR :=
CPP := cpp
GCC := gcc
CXX := g++
PERL := perl
JAVA := $java_bin
SYSTEMC :=
PYTHON := $python_command
VERDI_HOME :=
NOVAS_HOME :=
VCS_HOME :=
CLANG := clang
VERILATOR := verilator
EOF

    # Generate each NVDLA component, including register descriptions and the
    # configuration ROM contents used by the generated RTL.
    for directory in spec/defs spec/manual \
      vmod/include vmod/vlibs vmod/rams/model vmod/rams/synth vmod/fifos \
      vmod/nvdla/{apb2csb,bdma,cacc,car,cbuf,cdma,cdp,cmac,csb_master,csc,glb,nocif,pdp,retiming,rubik,sdp,top,cfgrom}; do
      make -C "$nvdla/$directory"
    done

    mapfile -d '' -t ram_model_files < <(
      find "$out/vmod/rams/model" -maxdepth 1 -type f \
        \( -name 'RAMDP_*.v' -o -name 'RAMPDP_*.v' \) -print0 | sort -z
    )
    if (( ${#ram_model_files[@]} == 0 )); then
      printf 'No NVDLA RAM model files were generated under %s\n' \
        "$out/vmod/rams/model" >&2
      exit 1
    fi
    "$python_command" "$root/patches/nvdla/stub_ram_model.py" \
      "${ram_model_files[@]}"
    find "$out/vmod/rams/model" -maxdepth 1 -type f -name '*.vcp' -delete
    printf 'Stubbed %d NVDLA RAM model outer modules\n' "${#ram_model_files[@]}"

    # Apply patches from the repository root with --directory pointing to the
    # generated output tree.
    apply_generated_patch_directory "$out" "$root/patches/nvdla/main"
    [[ -f $out/vmod/nvdla/top/NV_nvdla.v ]] || {
      printf 'NVDLA top was not generated\n' >&2
      exit 1
    }
  else
    apply_patch_directory \
      "$root/deps/$main_repository" \
      "$root/patches/$family/main"
  fi
  # The manifests use stable local names. Point those names at the pinned main
  # repository and at Bender's shared family dependency checkout.
  ln -sfn "../../deps/$main_repository" "$family_dir/main"
  if [[ -f $family_dir/Bender.lock ]]; then
    "$bender" -d "$family_dir" checkout --force
  fi
  for recipe in "$family_dir"/variants/*; do
    ln -sfn "../../../../deps/$main_repository" "$recipe/main"
    if [[ -f $family_dir/Bender.lock ]]; then
      ln -sfn ../../Bender.lock "$recipe/Bender.lock"
    fi
    if [[ -d $family_dir/.bender ]]; then
      ln -sfn ../../.bender "$recipe/.bender"
    fi
  done
  project=$family_dir
  # Discard generated mappings before resolving dependencies for this run.
  rm -rf -- "$project/dependencies"
  mkdir -p -- "$project/dependencies"
  resolved_dependencies=()
  if [[ -f $project/Bender.yml ]]; then
    dependency_list=$("$bender" -d "$project" packages --flat) || {
      printf 'Could not enumerate dependencies: %s\n' "$family" >&2
      exit 1
    }
    if [[ -n $dependency_list ]]; then
      mapfile -t resolved_dependencies <<< "$dependency_list"
    fi
  fi
  resolved_dependency_paths=()
  for dependency in "${resolved_dependencies[@]}"; do
    path=$("$bender" -d "$project" path "$dependency") || {
      printf 'Could not resolve dependency: %s/%s\n' "$family" "$dependency" >&2
      exit 1
    }
    [[ -n $path && -d $path ]] || {
      printf 'Dependency directory is missing: %s/%s (%s)\n' \
        "$family" "$dependency" "$path" >&2
      exit 1
    }
    resolved_dependency_paths+=("$path")
  done
  for index in "${!resolved_dependencies[@]}"; do
    ln -sfn "${resolved_dependency_paths[index]}" \
      "$project/dependencies/${resolved_dependencies[index]}"
  done
  # Apply benchmark-specific compatibility patches after all dependency paths
  # have been resolved, but before Bender generates any file lists.
  for patch_dependency in "$root/patches/$family/dependencies"/*; do
    [[ -d $patch_dependency ]] || continue
    dependency=$(basename "$patch_dependency")
    path="$project/dependencies/$dependency"
    [[ -d $path ]] || {
      printf 'Patched dependency was not resolved: %s/%s\n' "$family" "$dependency" >&2
      exit 1
    }
    apply_patch_directory "$(realpath -e -- "$path")" "$patch_dependency"
  done
done

# Publish the package only after every export step has succeeded.
temporary_output=$(mktemp -d "$root/.benchmarks.XXXXXX")
output=$temporary_output
# Build the distributable package metadata and flow files.
cp -a "$root/flows/." "$output/"
printf '\nTARGETS := %s\n' "${selected[*]}" >> "$output/targets.mk"
{
  printf '%s\n' \
    '# PULP benchmarks' \
    '' \
    'This is a self-contained collection of the prepared, patched RTL sources. Each variant has an independent file list using paths within this directory.'
  awk '/<!-- BEGIN DISTRIBUTION README -->/ { export_readme = 1; next }
       export_readme { print }' "$root/README.md"
} > "$output/README.md"
cp "$root/LICENSE" "$output/LICENSE"
cp "$root/LICENSE.Apache-2.0" "$output/LICENSE.Apache-2.0"
cp "$root/LICENSE.SHL-0.51" "$output/LICENSE.SHL-0.51"

# Generate each selected variant's independent RTL file list. Variant flow
# files are already present because the complete flows tree was copied above.
for target in "${selected[@]}"; do
  declare -A excluded_sources=()
  family=${target%%.*}
  variant=${target#*.}
  recipe="$root/bender/$family/variants/$variant"
  variant_output="$output/$family/variants/$variant"
  [[ -f $recipe/Bender.yml ]] || {
    printf 'Missing variant recipe: %s\n' "$recipe/Bender.yml" >&2
    exit 1
  }

  if [[ $family == snitch_cluster ]]; then
    config=cfg/default.json
    [[ $variant == minimal ]] && config=cfg/yosys-ci.json
    (
      cd "$root/deps/snitch_cluster"
      "$snitch_python" util/clustergen/clustergen.py \
        --clustercfg "$config" \
        --output hw/generated/snitch_cluster_wrapper_pkg.sv \
        --template hw/snitch_cluster/src/snitch_cluster_wrapper_pkg.sv.tpl
    )
  fi

  # Bender.args records the variant-specific targets and defines. Add the
  # synthesis-wide arguments used by every exported benchmark.
  mapfile -t variant_args < "$recipe/Bender.args"
  synthesis_args=(
    -t synthesis -D SYNTHESIS -D TARGET_SYNTHESIS
    -t tech_cells_generic_exclude_tc_sram
  )
  variant_args+=("${synthesis_args[@]}")
  # Trim unreachable files using the same top as the exported flows.
  top=$(awk -v key="$target.TOP" '$1 == key && $2 == ":=" { print $3 }' \
    "$root/flows/targets.mk")
  [[ -n $top && $top != *$'\n'* ]] || {
    printf 'Missing or ambiguous synthesis top for %s\n' "$target" >&2
    exit 1
  }
  trim_args=(--top "$top")
  # Discover include directories without package/exclusion filters, then ask
  # Bender for the filtered source list. This retains headers required by the
  # selected sources without reintroducing excluded compilation units.
  discovery_args=()
  index=0
  while (( index < ${#variant_args[@]} )); do
    argument=${variant_args[index]}
    case $argument in
      -p|--package|-e|--exclude) index=$((index + 2)) ;;
      *) discovery_args+=("$argument"); index=$((index + 1)) ;;
    esac
  done

  raw=$(mktemp)
  mapped_file=$(mktemp)
  {
    "$bender" -d "$recipe" script flist-plus "${discovery_args[@]}" |
      sed -n 's/^+incdir+//p' | awk '!seen[$0]++' | sed 's|^|+incdir+|'
    # Slang needs headers from filtered packages while trimming, not just in
    # the exported list assembled above.
    "$bender" -d "$recipe" script flist-plus --keep-excluded-incdirs \
      "${variant_args[@]}" "${trim_args[@]}" |
      sed '/^+incdir+/d'
  } > "$raw"
  if [[ -f $recipe/filelist.keep ]]; then
    while IFS= read -r retained_source || [[ -n $retained_source ]]; do
      [[ -n $retained_source && $retained_source != \#* ]] || continue
      retained_source=$(realpath -e -- "$recipe/$retained_source")
      if ! grep -Fxq -- "$retained_source" "$raw"; then
        printf '%s\n' "$retained_source" >> "$raw"
      fi
    done < "$recipe/filelist.keep"
  fi
  if [[ -n ${sram_stub_families[$family]:-} ]] && \
      ! grep -q '/tc_sram_stubs\.sv$' "$raw"; then
    printf '%s\n' "$root/support/tc_sram_stubs.sv" >> "$raw"
  fi
  # Some upstream manifests expose files that cannot be disabled by a Bender
  # target. Translate the documented exclusions to canonical source paths.
  if [[ -f $recipe/filelist.exclude ]]; then
    while IFS= read -r exclusion || [[ -n $exclusion ]]; do
      [[ -n $exclusion && $exclusion != \#* ]] || continue
      dependency=${exclusion%%/*}
      exclusion_path=${exclusion#*/}
      exclusion_path=$(realpath -e -- \
        "$root/bender/$family/dependencies/$dependency/$exclusion_path")
      excluded_sources["$exclusion_path"]=1
    done < "$recipe/filelist.exclude"
  fi
  # Copy every resolved entry into the package and write its new relative path
  # to a file list that no longer refers to deps/, Bender, or the source repos.
  mkdir -p "$variant_output"
  while IFS= read -r line || [[ -n $line ]]; do
    case $line in
      '') printf '\n' >> "$mapped_file" ;;
      +incdir+*)
        mapped=$(map_entry "${line#+incdir+}" 1)
        printf '+incdir+%s\n' "$mapped" >> "$mapped_file"
        ;;
      +*) printf '%s\n' "$line" >> "$mapped_file" ;;
      *)
        if [[ -n ${excluded_sources[$(realpath -e -- "$line")]:-} ]]; then
          continue
        fi
        mapped=$(map_entry "$line" 0)
        printf '%s\n' "$mapped" >> "$mapped_file"
        ;;
    esac
  done < "$raw"
  mv "$mapped_file" "$variant_output/filelist.f"
  rm -f "$raw"
  printf 'Generated %s\n' "$target"
done

# Preserve upstream license and notice files alongside every source tree that
# contributed files to the package. Keep their relative paths so notices in
# vendored subdirectories remain associated with the corresponding RTL.
for family in "${!selected_families[@]}"; do
  main_repository=${main_repositories[$family]:-$family}
  license_roots=(
    "$root/deps/$main_repository"
    "$output/$family/main"
  )
  for dependency_output in "$output/$family/dependencies"/*; do
    [[ -d $dependency_output ]] || continue
    dependency=$(basename "$dependency_output")
    dependency_root=$(realpath -e -- \
      "$root/bender/$family/dependencies/$dependency")
    license_roots+=("$dependency_root" "$dependency_output")
  done

  for ((index = 0; index < ${#license_roots[@]}; index += 2)); do
    source_root=${license_roots[index]}
    destination_root=${license_roots[index + 1]}
    while IFS= read -r -d '' source; do
      relative=${source#"$source_root"/}
      relative_directory=${relative%/*}
      [[ $relative_directory != "$relative" ]] || relative_directory=.
      # Skip notices from unrelated test and tooling subtrees. A directory in
      # the output exists only when exported RTL created it; root notices and
      # a repository's top-level LICENSES directory apply to the whole tree.
      if [[ ! -d $destination_root/$relative_directory && \
            $relative != LICENSES/* ]]; then
        continue
      fi
      destination="$destination_root/$relative"
      mkdir -p "$(dirname "$destination")"
      cp "$source" "$destination"
    done < <(
      find "$source_root" -type f \
        \( -iname 'LICENSE*' -o -iname 'COPYING*' -o \
           -iname 'NOTICE*' -o -iname 'COPYRIGHT*' -o \
           -iname 'README.license*' -o \
           -path "$source_root/LICENSES/*" \) \
        -not -path '*/.git/*' -print0
    )
  done
done

# Python helpers used during setup may leave host-version-specific bytecode.
find "$output" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete
find "$output" -depth -type d -name __pycache__ -exec rmdir {} +

chmod 755 "$output"
mv -T -- "$output" "$root/benchmarks"
temporary_output=
