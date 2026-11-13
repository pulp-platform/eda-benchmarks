# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

set parent_top $top
set top snitch_cluster_synth
puts "\n===== Synthesizing $top ====="
read_rtl $top
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
yosys dfflegalize -cell {$_DFFSR_NNN_} 01 -cell {$_DFFSR_PNN_} 01 -cell {$_DFF_NN0_} 01 -cell {$_DFF_NN1_} 01 -cell {$_DFF_N_} 01 -cell {$_DFF_PN0_} 01 -cell {$_DFF_PN1_} 01 -cell {$_DFF_P_} 01 -cell {$_DLATCH_?_} 01 -cell {$_DLATCH_?N0_} 01 -cell {$_DLATCH_?N1_} 01 -cell {$_DLATCHSR_?NN_} 01 {t:$_ALDFF*} {t:$_SR_*} {t:$_DLATCH*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells $top true
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]

yosys design -reset
source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
set top $parent_top
puts "\n===== Synthesizing $top ====="
read_rtl $top [list +define+OSEDA_SNITCH_CLUSTER_PARENT_ONLY]
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
yosys dfflegalize -cell {$_DFFSR_NNN_} 01 -cell {$_DFFSR_PNN_} 01 -cell {$_DFF_NN0_} 01 -cell {$_DFF_NN1_} 01 -cell {$_DFF_N_} 01 -cell {$_DFF_PN0_} 01 -cell {$_DFF_PN1_} 01 -cell {$_DFF_P_} 01 -cell {$_DLATCH_?_} 01 -cell {$_DLATCH_?N0_} 01 -cell {$_DLATCH_?N1_} 01 -cell {$_DLATCHSR_?NN_} 01 {t:$_ALDFF*} {t:$_SR_*} {t:$_DLATCH*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells $top false
write_results
check_results
