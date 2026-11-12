# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

set yosys_dir [file dirname [file normalize [info script]]]
set technology_dir [file join [file dirname $yosys_dir] technology]
set liberty_dir [file join $technology_dir liberty]
set latch_map_file [file join $yosys_dir latch_map.v]

set liberty_file [file join $liberty_dir gf180mcu_fd_sc_mcu7t5v0__tt_025C_5v00.lib]
set tech_cells [glob -nocomplain -types f $liberty_file]
if {[llength $tech_cells] == 0} {
    error "Missing Liberty file: $liberty_file; populate $technology_dir"
}

foreach liberty_file $tech_cells {
    yosys read_liberty -lib $liberty_file
}

set tech_cell_args {}
foreach liberty_file $tech_cells {
    lappend tech_cell_args -liberty $liberty_file
}
set liberty_args $tech_cell_args
