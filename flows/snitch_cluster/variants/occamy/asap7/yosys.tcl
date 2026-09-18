# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

# Synthesize the implementation shared by all 48 Occamy cluster instances.
set parent_top $top
set top snitch_cluster_synth
puts "\n===== Synthesizing $top ====="
read_rtl $top
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
convert_async_registers
map_cells $top true
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]

# Release the child implementation before elaborating and mapping the parent.
yosys design -reset
source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
set top $parent_top
puts "\n===== Synthesizing $top ====="
read_rtl $top [list +define+OSEDA_SNITCH_CLUSTER_PARENT_ONLY]
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
convert_async_registers
map_cells $top false
write_results
check_results
