# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

read_rtl
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
convert_async_registers
yosys techmap -map $latch_map_file
map_cells
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]
check_results
