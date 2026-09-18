# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

YOSYS_COMMAND ?= yosys
DESIGN ?=
INTRA_THREADS ?=
AST ?= 0
CHECK ?= 0

include targets.mk

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

.PHONY: help list elaborate yosys check-selection \
        $(ELABORATE_GOALS) $(YOSYS_GOALS)

help:
	@printf '%s\n' \
	  '  make elaborate [DESIGN=<design.variant>] [AST=1]' \
	  '                 [INTRA_THREADS=<count>]' \
	  '                 [YOSYS_COMMAND=<command>]' \
	  '  make yosys [DESIGN=<design.variant>] [TECH=<technology>]' \
	  '             [INTRA_THREADS=<count>] [YOSYS_COMMAND=<command>] [CHECK=1]' \
	  '  make list'

list:
	@printf '%-32s %s\n' DESIGN TECHNOLOGIES
	@$(foreach target,$(TARGETS),printf '%-32s %s\n' '$(target)' '$(call target_techs,$(target))';)

elaborate: $(if $(DESIGN),elaborate-$(DESIGN),$(ELABORATE_GOALS))

yosys: check-selection $(SELECTED_YOSYS_GOALS)

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
