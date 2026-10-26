#!/usr/bin/env bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$script_dir/../.." && pwd)
rm -rf -- "$script_dir/data"
python_command=${PYTHON:-python3}
environment="$script_dir/.venv"

"$python_command" -m venv "$environment"
"$environment/bin/python3" -m pip install --disable-pip-version-check \
  'PyYAML==6.0.2' 'numpy==1.26.4' 'onnx==1.17.0' 'protobuf==5.29.5'

"$environment/bin/python3" "$script_dir/prepare-regression.py"
cp "$root/LICENSE.Apache-2.0" "$script_dir/data/ita_tb/"
cp "$root/deps/ita/"LICENSE.* "$script_dir/data/ita_tb/"
printf '%s\n' "ITA: $(git -C "$root/deps/ita" rev-parse HEAD)" \
  'Selection: upstream run_sim matrix plus the original identity activation case; seed 0' \
  > "$script_dir/data/ita_tb/README.txt"
