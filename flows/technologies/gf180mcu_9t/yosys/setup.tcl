# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set yosys_dir [file dirname [file normalize [info script]]]
set technology_dir [file join [file dirname $yosys_dir] technology]
set liberty_dir [file join $technology_dir liberty]
set latch_map_file [file join $yosys_dir latch_map.v]

set liberty_header [file join $liberty_dir gf180mcu_fd_sc_mcu9t5v0__tt_025C_5v00.lib]
set cell_files [lsort [glob -nocomplain -types f \
    [file join $technology_dir cells * gf180mcu_fd_sc_mcu9t5v0__*__tt_025C_5v00.lib]]]
if {![file isfile $liberty_header] || [llength $cell_files] == 0} {
    error "Missing GF180MCU 9-track TT 5 V library header or cell files; populate $technology_dir"
}

set source_file [open $liberty_header r]
set library_header [read $source_file]
close $source_file
if {![regsub {\}\s*$} $library_header {} library_header]} {
    error "Invalid Liberty header: $liberty_header"
}

set liberty_file [file join $::env(BENCH_REPORT_DIR) gf180mcu_fd_sc_mcu9t5v0__tt_025C_5v00.lib]
set merged_file [open $liberty_file w]
puts $merged_file $library_header
foreach cell_file $cell_files {
    set source_file [open $cell_file r]
    puts $merged_file [read $source_file]
    close $source_file
}
puts $merged_file "\}"
close $merged_file
set tech_cells [list $liberty_file]

foreach liberty_file $tech_cells {
    yosys read_liberty -lib $liberty_file
}

set tech_cell_args {}
foreach liberty_file $tech_cells {
    lappend tech_cell_args -liberty $liberty_file
}
set liberty_args $tech_cell_args
