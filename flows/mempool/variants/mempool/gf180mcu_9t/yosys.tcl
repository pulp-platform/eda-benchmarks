# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

set parent_top $top
set top mempool_tile
puts "\n===== Synthesizing $top ====="
read_rtl $top [list -G BootAddr=0]
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
set top mempool_group
puts "\n===== Synthesizing $top ====="
read_rtl $top [list -G BootAddr=0 +define+OSEDA_MEMPOOL_GROUP_ONLY]
foreach {parameter value} {TCDMBaseAddr 0 BootAddr 0 NumCaches 1 NumCoresPerDivsqrt 4} {
    yosys select -assert-none t:mempool_tile r:$parameter=$value %d
    yosys setparam -unset $parameter t:mempool_tile
}
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
yosys dfflegalize -cell {$_DFFSR_NNN_} 01 -cell {$_DFFSR_PNN_} 01 -cell {$_DFF_NN0_} 01 -cell {$_DFF_NN1_} 01 -cell {$_DFF_N_} 01 -cell {$_DFF_PN0_} 01 -cell {$_DFF_PN1_} 01 -cell {$_DFF_P_} 01 -cell {$_DLATCH_?_} 01 -cell {$_DLATCH_?N0_} 01 -cell {$_DLATCH_?N1_} 01 -cell {$_DLATCHSR_?NN_} 01 {t:$_ALDFF*} {t:$_SR_*} {t:$_DLATCH*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells $top false
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]

yosys design -reset
source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
set top $parent_top
puts "\n===== Synthesizing $top ====="
read_rtl $top [list +define+OSEDA_MEMPOOL_PARENT_ONLY]
foreach parameter {TCDMBaseAddr BootAddr GroupId} {
    yosys select -assert-none t:mempool_group r:$parameter=0 %d
    yosys setparam -unset $parameter t:mempool_group
}
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
yosys dfflegalize -cell {$_DFFSR_NNN_} 01 -cell {$_DFFSR_PNN_} 01 -cell {$_DFF_NN0_} 01 -cell {$_DFF_NN1_} 01 -cell {$_DFF_N_} 01 -cell {$_DFF_PN0_} 01 -cell {$_DFF_PN1_} 01 -cell {$_DFF_P_} 01 -cell {$_DLATCH_?_} 01 -cell {$_DLATCH_?N0_} 01 -cell {$_DLATCH_?N1_} 01 -cell {$_DLATCHSR_?NN_} 01 {t:$_ALDFF*} {t:$_SR_*} {t:$_DLATCH*}
yosys techmap -map $latch_map_file
yosys techmap
map_cells $top false
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]
check_results
