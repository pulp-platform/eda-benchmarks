# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set package_root [file normalize [file join [file dirname [info script]] .. .. .. ..]]


source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
source [file join $package_root common yosys.tcl]

# Synthesize one tile, shared by every tile instance in the design.
set parent_top $top
set top mempool_tile
puts "\n===== Synthesizing $top ====="
read_rtl $top [list -G BootAddr=0]
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
convert_async_registers
yosys techmap -map $latch_map_file
map_cells $top true
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]

# Map the group interconnect with the already-mapped tile as its boundary.
yosys design -reset
source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
set top mempool_group
puts "\n===== Synthesizing $top ====="
read_rtl $top [list -G BootAddr=0 +define+OSEDA_MEMPOOL_GROUP_ONLY]
# Check the child specialization before removing its RTL parameter overrides.
foreach {parameter value} {TCDMBaseAddr 0 BootAddr 0 NumCaches 1 NumCoresPerDivsqrt 4} {
    yosys select -assert-none t:mempool_tile r:$parameter=$value %d
    yosys setparam -unset $parameter t:mempool_tile
}
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
convert_async_registers
yosys techmap -map $latch_map_file
map_cells $top false
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]

# Release the group implementation before elaborating and mapping the parent.
yosys design -reset
source [file join $package_root technologies $env(BENCH_TECH) yosys setup.tcl]
set top $parent_top
puts "\n===== Synthesizing $top ====="
read_rtl $top [list +define+OSEDA_MEMPOOL_PARENT_ONLY]
# Check the child specialization before removing its RTL parameter overrides.
foreach parameter {TCDMBaseAddr BootAddr GroupId} {
    yosys select -assert-none t:mempool_group r:$parameter=0 %d
    yosys setparam -unset $parameter t:mempool_group
}
yosys blackbox N:tc_sram_blackbox\$*
synthesize_rtl
convert_async_registers
yosys techmap -map $latch_map_file
map_cells $top false
write_results
write_blackboxes [list =N:tc_sram_blackbox\$*]
check_results
