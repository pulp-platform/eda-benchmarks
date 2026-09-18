# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

# Common Yosys synthesis procedures.

if {$env(BENCH_EXTERNAL_SLANG) eq "1"} {
    yosys plugin -i slang.so
}

set top $env(BENCH_TOP)

set slang_args {}
if {[file exists $env(BENCH_SLANG_ARGS_FILE)]} {
    set args_file [open $env(BENCH_SLANG_ARGS_FILE) r]
    while {[gets $args_file arg] >= 0} {
        set arg [string trim $arg]
        if {$arg eq "" || [string match "#*" $arg]} continue
        lappend slang_args $arg
    }
    close $args_file
}

proc read_rtl {{read_top ""} {extra_args {}}} {
    global top slang_args

    if {$read_top eq ""} {
        set read_top $top
    }

    set read_args [list --top $read_top -f filelist.f --compat-mode --compat=vcs \
                        --allow-use-before-declare --error-limit=10000 \
                        --best-effort-hierarchy]
    foreach arg $slang_args {
        lappend read_args $arg
    }
    if {$::env(BENCH_INTRA_THREADS) ne ""} {
        lappend read_args -j $::env(BENCH_INTRA_THREADS)
    }
    foreach arg $extra_args {
        lappend read_args $arg
    }
    yosys read_slang {*}$read_args
}

proc synthesize_rtl {} {
    global top

    yosys hierarchy -check -top $top
    yosys proc -noopt
    yosys opt_clean
    yosys memory_collect
    yosys setattr -mod -set keep_hierarchy 1 =A:blackbox
    yosys keep_hierarchy -min_cost 5000
    yosys flatten
    yosys opt -noff -hier
    yosys check
    yosys memory_map
    yosys techmap
    yosys opt -noff
}

proc convert_async_registers {} {
    yosys select -clear
    yosys select t:\$_ALDFF_* t:\$_ALDFFE_*
    yosys async2sync
    yosys select -clear
}

proc map_cells {{report_label ""} {truncate_report true}} {
    global tech_cell_args liberty_args

    set report_dir $::env(BENCH_REPORT_DIR)
    set report_path "$report_dir/synthesis.rpt"

    yosys dfflibmap {*}$tech_cell_args
    yosys abc {*}$tech_cell_args -script "+strash;&get,-n;&nf;&put"
    yosys check

    set report_mode [expr {$truncate_report ? "w" : "a"}]
    set report_file [open $report_path $report_mode]
    if {$report_label ne ""} {
        puts $report_file "===== $report_label ====="
        puts "===== $report_label ====="
    }
    close $report_file
    yosys tee -a $report_path stat {*}$liberty_args
}

proc write_results {} {
    global top

    set results_dir $::env(BENCH_RESULTS_DIR)

    yosys write_verilog -noattr "$results_dir/$top.v"
}

proc write_blackboxes {patterns} {
    global top

    set results_dir $::env(BENCH_RESULTS_DIR)

    yosys select -clear
    yosys select {*}$patterns
    yosys write_verilog -selected -blackboxes "$results_dir/$top.blackboxes.v"
}

proc check_results {} {
    global liberty_args

    if {![info exists ::env(BENCH_CHECK)] || $::env(BENCH_CHECK) ne "1"} {
        puts "Skipping final netlist readback check (enable with CHECK=1)."
        return
    }

    yosys design -reset
    yosys logger -werror {Resizing cell port}
    source [file join $::env(BENCH_PACKAGE_ROOT) technologies $::env(BENCH_TECH) yosys setup.tcl]

    set netlists [lsort [glob -nocomplain [file join $::env(BENCH_RESULTS_DIR) *.v]]]
    if {[llength $netlists] == 0} {
        error "No synthesized netlists found in $::env(BENCH_RESULTS_DIR)"
    }
    foreach netlist $netlists {
        yosys read_verilog $netlist
    }
    yosys hierarchy -check -top $::env(BENCH_TOP)
    yosys check -mapped -assert
    yosys tee -o [file join $::env(BENCH_REPORT_DIR) linked.rpt] stat {*}$liberty_args
}
