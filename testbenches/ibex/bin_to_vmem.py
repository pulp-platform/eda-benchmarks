# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import sys

def bin_to_vmem(source, output):
    data = Path(source).read_bytes()
    data += bytes((-len(data)) % 4)
    Path(output).write_text('@0\n' + ''.join(
        f'{int.from_bytes(data[i:i+4], "little"):08x}\n'
        for i in range(0, len(data), 4)))


if __name__ == '__main__':
    bin_to_vmem(sys.argv[1], sys.argv[2])
