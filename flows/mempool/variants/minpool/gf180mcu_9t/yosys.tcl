# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

read_rtl
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
yosys dfflegalize -cell {$_DFFSR_NNN_} 01 -cell {$_DFFSR_PNN_} 01 -cell {$_DFF_NN0_} 01 -cell {$_DFF_NN1_} 01 -cell {$_DFF_N_} 01 -cell {$_DFF_PN0_} 01 -cell {$_DFF_PN1_} 01 -cell {$_DFF_P_} 01 -cell {$_DLATCH_?_} 01 -cell {$_DLATCH_?N0_} 01 -cell {$_DLATCH_?N1_} 01 -cell {$_DLATCHSR_?NN_} 01 {t:$_ALDFF*} {t:$_SR_*} {t:$_DLATCH*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]
check_results
