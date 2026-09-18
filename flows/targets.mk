# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

TARGETS := \
  ara.default \
  cheshire.default \
  cv32e40p.default \
  cva6.default \
  cvfpu.fp32_fma \
  cvfpu.full \
  ibex.minimal \
  ibex.full \
  ita.default \
  mempool.minpool \
  mempool.mempool \
  mempool.terapool \
  nvdla.top \
  opope.default \
  pulp_c910.default \
  redmule.default \
  serial_link.default \
  snitch_cluster.minimal \
  snitch_cluster.default \
  snitch_cluster.default_latch \
  snitch_cluster.occamy \
  spatz.default \
  spi_host.default

ara.default.TOP := ara_synth

cheshire.default.TOP := cheshire_synth

cv32e40p.default.TOP := cv32e40p_core

cva6.default.TOP := cva6

cvfpu.fp32_fma.TOP := cvfpu_fp32_fma_synth

cvfpu.full.TOP := cvfpu_full_synth

ibex.minimal.TOP := ibex_minimal_synth

ibex.full.TOP := ibex_full_synth

ita.default.TOP := ita

mempool.minpool.TOP := mempool_system

mempool.mempool.TOP := mempool_system

mempool.terapool.TOP := mempool_system

nvdla.top.TOP := NV_nvdla

opope.default.TOP := opope_wrap

pulp_c910.default.TOP := pulp_c910_synth

redmule.default.TOP := redmule_synth

serial_link.default.TOP := serial_link_synth

snitch_cluster.minimal.TOP := snitch_cluster_wrapper

snitch_cluster.default.TOP := snitch_cluster_default_synth

snitch_cluster.default_latch.TOP := snitch_cluster_default_synth

snitch_cluster.occamy.TOP := snitch_cluster_occamy_synth

spatz.default.TOP := spatz_cluster_wrapper

spi_host.default.TOP := spi_host_synth
