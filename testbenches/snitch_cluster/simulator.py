#!/usr/bin/env python3
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
import json
import os
import sys


if __name__ == '__main__':
    command = json.loads(os.environ['SNITCH_SIMULATOR_COMMAND'])
    os.execv(command[0], command + sys.argv[1:])
