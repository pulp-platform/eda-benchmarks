# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

# Shared Yosys-Slang elaboration flow.

source [file join [file dirname [info script]] yosys.tcl]

if {$env(BENCH_AST) eq "1"} {
    lappend slang_args --ast-compilation-only
    read_rtl
    exit
}

read_rtl
yosys hierarchy -check -top $top
yosys stat -tech cmos
