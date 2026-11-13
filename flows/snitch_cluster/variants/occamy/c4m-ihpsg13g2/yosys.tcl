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
yosys dfflegalize -cell {$_DFF_PN0_} 01 -cell {$_DFF_P_} 01 -cell {$_SR_NN_} 01 {t:$_ALDFF*} {t:$_DFFSR*} {t:$_SR_*}
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
yosys dfflegalize -cell {$_DFF_PN0_} 01 -cell {$_DFF_P_} 01 -cell {$_SR_NN_} 01 {t:$_ALDFF*} {t:$_DFFSR*} {t:$_SR_*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells $top false
write_results
check_results
