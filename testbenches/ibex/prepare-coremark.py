# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
if 'return MAIN_RETURN_VAL;' in s:
    index = s.rindex('return MAIN_RETURN_VAL;')
    s = s[:index] + s[index:].replace('return MAIN_RETURN_VAL;', 'return total_errors != 0;', 1)
    p.write_text(s)
elif 'return total_errors != 0;' not in s:
    raise ValueError('Unrecognized CoreMark return statement')
