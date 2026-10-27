# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

YOSYS_COMMAND ?= yosys
DESIGN ?=
INTRA_THREADS ?=
AST ?= 0
CHECK ?= 0
VERILATOR_COMMAND ?=
VERILATOR_MODE ?= all
ifeq ($(filter $(VERILATOR_MODE),all build run),)
$(error VERILATOR_MODE must be all, build, or run)
endif
TEST ?=
TESTCASE ?=
TIMEOUT ?= 0
SEED ?= 1

include targets.mk
include testbenches.mk

target_family = $(word 1,$(subst ., ,$(1)))
target_variant = $(word 2,$(subst ., ,$(1)))
target_dir = $(call target_family,$(1))/variants/$(call target_variant,$(1))
target_tech_dirs = $(wildcard $(call target_dir,$(1))/*/default.sdc)
target_techs = $(notdir $(patsubst %/,%,$(dir $(call target_tech_dirs,$(1)))))
TECHNOLOGIES := $(sort $(foreach target,$(TARGETS),$(call target_techs,$(target))))
TECH ?=

ELABORATE_GOALS := $(addprefix elaborate-,$(TARGETS))
YOSYS_GOALS := $(foreach target,$(TARGETS),$(foreach tech,$(call target_techs,$(target)),yosys-$(target)-$(tech)))
SELECTED_DESIGNS := $(if $(DESIGN),$(DESIGN),$(TARGETS))
SELECTED_YOSYS_GOALS := $(foreach target,$(SELECTED_DESIGNS),$(foreach tech,$(if $(TECH),$(filter $(TECH),$(call target_techs,$(target))),$(call target_techs,$(target))),yosys-$(target)-$(tech)))
verilator_tests = $(notdir $(patsubst %/,%,$(dir $(wildcard $(call target_dir,$(1))/verilator/*/filelist.f))))
VERILATOR_GOALS := $(foreach target,$(TARGETS),$(foreach test,$(call verilator_tests,$(target)),verilator-$(target)-$(test)))
selected_verilator_cases = $(if $(TESTCASE),$(filter $(verilator_cases_$(1)_$(2)),$(TESTCASE)),$(verilator_cases_$(1)_$(2)))
SELECTED_VERILATOR_GOALS = $(foreach target,$(SELECTED_DESIGNS),$(foreach test,$(if $(TEST),$(filter $(TEST),$(call verilator_tests,$(target))),$(call verilator_tests,$(target))),$(if $(call selected_verilator_cases,$(target),$(test)),verilator-$(target)-$(test))))

.PHONY: help list elaborate yosys check-selection \
        verilator check-verilator-selection \
        $(ELABORATE_GOALS) $(YOSYS_GOALS) $(VERILATOR_GOALS)

help:
	@printf '%s\n' \
	  '  make elaborate [DESIGN=<design.variant>] [AST=1]' \
	  '                 [INTRA_THREADS=<count>]' \
	  '                 [YOSYS_COMMAND=<command>]' \
	  '  make yosys [DESIGN=<design.variant>] [TECH=<technology>]' \
	  '             [INTRA_THREADS=<count>] [YOSYS_COMMAND=<command>] [CHECK=1]' \
	  '  make verilator [DESIGN=<design.variant>] [TEST=<test>] [TESTCASE=<testcase>]' \
	  '                VERILATOR_COMMAND=<path> [-j<count>]' \
	  '                [TIMEOUT=0] [SEED=1]' \
	  '                [VERILATOR_MODE=all|build|run (default: all)]' \
	  '  make list'

list:
	@printf '%-32s %-24s %s\n' DESIGN TECHNOLOGIES TESTS
	@$(foreach target,$(TARGETS),printf '%-32s %-24s %s\n' '$(target)' '$(or $(call target_techs,$(target)),-)' '$(or $(call verilator_tests,$(target)),-)';)

elaborate: $(if $(DESIGN),elaborate-$(DESIGN),$(ELABORATE_GOALS))

yosys: check-selection $(SELECTED_YOSYS_GOALS)

check-verilator-selection:
	@if [[ -n '$(DESIGN)' && -z '$(filter $(DESIGN),$(TARGETS))' ]]; then \
	  printf 'Unknown design: %s\n' '$(DESIGN)' >&2; exit 2; \
	fi
	@if [[ -z '$(strip $(SELECTED_VERILATOR_GOALS))' ]]; then \
	  printf 'No Verilator tests match DESIGN=%s TEST=%s TESTCASE=%s. Run make list.\n' '$(DESIGN)' '$(TEST)' '$(TESTCASE)' >&2; exit 2; \
	fi

ifneq ($(filter verilator verilator-%,$(MAKECMDGOALS)),)
MAKEFLAGS += --keep-going
endif

define declare_verilator_testcase
.PHONY: verilator-$(1)-$(2)-$(3)
verilator-$(1)-$(2)-$(3): verilator-build-$(1)-$(2)
	@BENCH_TOP='$($(1).$(2).TOP)' TIMEOUT='$(TIMEOUT)' SEED='$(SEED)' \
	 ./common/verilator.sh run '$(1)' '$(2)' '$(3)'
endef

define declare_verilator_rule
verilator_cases_$(1)_$(2) := $$(shell ./common/verilator.sh list '$(1)' '$(2)' || printf ' @error')
$$(if $$(filter @error,$$(verilator_cases_$(1)_$(2))),$$(error Invalid testcase list for $(1)/$(2)))
.PHONY: verilator-build-$(1)-$(2)
verilator-build-$(1)-$(2):
	+@BENCH_TOP='$($(1).$(2).TOP)' VERILATOR_COMMAND='$(VERILATOR_COMMAND)' \
	 BENCH_MAKE='$(MAKE)' TIMEOUT='$(TIMEOUT)' \
	 VERILATOR_MODE='$(VERILATOR_MODE)' \
	 ./common/verilator.sh build '$(1)' '$(2)'
verilator-$(1)-$(2): $$(foreach testcase,$$(call selected_verilator_cases,$(1),$(2)),verilator-$(1)-$(2)-$$(testcase))
	@printf 'PASS: %s/%s\n' '$(1)' '$(2)'
$$(foreach testcase,$$(verilator_cases_$(1)_$(2)),$$(eval $$(call declare_verilator_testcase,$(1),$(2),$$(testcase))))
endef

$(foreach target,$(TARGETS),$(foreach test,$(call verilator_tests,$(target)),$(eval $(call declare_verilator_rule,$(target),$(test)))))

verilator: check-verilator-selection $(if $(filter build,$(VERILATOR_MODE)),$(patsubst verilator-%,verilator-build-%,$(SELECTED_VERILATOR_GOALS)),$(SELECTED_VERILATOR_GOALS))

check-selection:
	@if [[ -n '$(DESIGN)' && -z '$(filter $(DESIGN),$(TARGETS))' ]]; then \
	  printf 'Unknown design: %s\n' '$(DESIGN)' >&2; exit 2; \
	fi
	@if [[ -n '$(TECH)' && -z '$(filter $(TECH),$(TECHNOLOGIES))' ]]; then \
	  printf 'Unknown technology: %s\n' '$(TECH)' >&2; exit 2; \
	fi
	@if [[ -n '$(DESIGN)' && -n '$(TECH)' && \
	       -z '$(filter $(TECH),$(call target_techs,$(DESIGN)))' ]]; then \
	  printf '%s does not support technology %s\n' '$(DESIGN)' '$(TECH)' >&2; exit 2; \
	fi

$(ELABORATE_GOALS): elaborate-%:
	@if [[ '$(AST)' != 0 && '$(AST)' != 1 ]]; then \
	  printf 'AST must be 0 or 1: %s\n' '$(AST)' >&2; \
	  exit 2; \
	fi
	@printf '\n===== %s =====\n' '$*'
	@BENCH_TOP='$($*.TOP)' \
	 BENCH_INTRA_THREADS='$(INTRA_THREADS)' \
	 BENCH_AST='$(AST)' \
	 YOSYS_COMMAND='$(YOSYS_COMMAND)' \
	 ./common/elaborate.sh '$*'
	@printf 'PASS: %s\n' '$*'

define declare_yosys_rule
.PHONY: yosys-$(1)-$(2)
yosys-$(1)-$(2):
	@printf '\n===== %s [%s] =====\n' '$(1)' '$(2)'
	@BENCH_DESIGN='$(1)' \
	 BENCH_TECH='$(2)' \
	 BENCH_TOP='$($(1).TOP)' \
	 BENCH_CHECK='$(CHECK)' \
	 BENCH_INTRA_THREADS='$(INTRA_THREADS)' \
	 YOSYS_COMMAND='$(YOSYS_COMMAND)' \
	 ./common/yosys.sh
	@printf 'PASS: %s [%s]\n' '$(1)' '$(2)'
endef

$(foreach target,$(TARGETS),$(foreach tech,$(call target_techs,$(target)),$(eval $(call declare_yosys_rule,$(target),$(tech)))))
