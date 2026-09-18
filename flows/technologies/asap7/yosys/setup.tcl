# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

# ASAP7 setup for the shared Yosys synthesis flow.

set yosys_dir [file dirname [file normalize [info script]]]
set technology_dir [file join [file dirname $yosys_dir] technology]
set liberty_dir [file join $technology_dir LIB NLDM]
set latch_map_file [file join $yosys_dir latch_map.v]

set tech_cells [lsort [glob -nocomplain \
    [file join $liberty_dir asap7sc7p5t_*_RVT_TT_nldm_*.lib]]]
if {[llength $tech_cells] == 0} {
    set tech_cell_archives [glob -nocomplain \
        [file join $liberty_dir asap7sc7p5t_*_RVT_TT_nldm_*.lib.7z]]
    if {[llength $tech_cell_archives] != 0} {
        error "ASAP7 RVT TT NLDM Liberty archives must be extracted in $liberty_dir"
    }
    error "No ASAP7 RVT TT NLDM Liberty files found in $liberty_dir"
}

foreach liberty_file $tech_cells {
    yosys read_liberty -lib $liberty_file
}

set tech_cell_args {}
foreach liberty_file $tech_cells {
    lappend tech_cell_args -liberty $liberty_file
}
set liberty_args $tech_cell_args
