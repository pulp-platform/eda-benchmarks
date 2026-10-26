#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import re
import sys

header, output = map(Path, sys.argv[1:])
lines = [
    '// SPDX-License-Identifier: Apache-2.0',
    '#include "dpiheader.h"',
    '#include "Vtop__Dpi.h"',

]
for name, parameters in re.findall(r'\bint\s+(dpi_\w+)\s*\(([^)]*)\)\s*;', header.read_text()):
    declarations, arguments, environments = [], [], []
    for parameter in parameters.split(','):
        parameter = ' '.join(parameter.split())
        argument = re.search(r'(\w+)$', parameter).group(1)
        if parameter.startswith('const env_t* '):
            declarations.append(f'const svBitVecVal* {argument}_bits')
            environments.append(f'  env_t {argument} = {{short({argument}_bits[0] >> 8), char({argument}_bits[0])}};')
            arguments.append(f'&{argument}')
        else:
            declarations.append(parameter)
            arguments.append(argument)
    lines.extend([
        f'extern "C" int {name}_flat({", ".join(declarations)}) {{',
        '  result[0] = 0;',
        '  result[1] = 0;',
        *environments,
        f'  return {name}({", ".join(arguments)});',
        '}',
    ])
output.write_text('\n'.join(lines) + '\n')
