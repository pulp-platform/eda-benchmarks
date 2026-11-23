# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

read_rtl
if {[info exists ::env(BENCH_PRUNE_RVFI)] && $::env(BENCH_PRUNE_RVFI) eq "1"} {
    yosys select -assert-count 1 cva6/o:rvfi_probes_o
    yosys delete -output cva6/o:rvfi_probes_o
}
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
map_latches
map_cells
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]
check_results
