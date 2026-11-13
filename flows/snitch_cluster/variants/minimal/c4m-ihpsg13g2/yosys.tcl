# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

read_rtl
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
yosys dfflegalize -cell {$_DFF_PN0_} 01 -cell {$_DFF_P_} 01 -cell {$_SR_NN_} 01 {t:$_ALDFF*} {t:$_DFFSR*} {t:$_SR_*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]
check_results
