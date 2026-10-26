// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

module snitch_cluster_occamy_synth
  import pulp_benchmark_snitch_cluster_pkg::*;
  import snitch_cluster_wrapper_pkg::*;
#(
  parameter int unsigned NumClusters = 48
) (
  input  logic                                      clk_i,
  input  logic                                      rst_ni,
  input  logic [NumClusters-1:0][NrCores-1:0]       debug_req_i,
  input  logic [NumClusters-1:0][NrCores-1:0]       meip_i,
  input  logic [NumClusters-1:0][NrCores-1:0]       mtip_i,
  input  logic [NumClusters-1:0][NrCores-1:0]       msip_i,
  input  snitch_cluster_pkg::hart_id_t [NumClusters-1:0] hart_base_id_i,
  input  logic [NumClusters-1:0][AddrWidth-1:0]     cluster_base_addr_i,
  input  logic [NumClusters-1:0][AddrWidth-1:0]     cluster_base_offset_i,
  input  logic [NumClusters-1:0]                    clk_d2_bypass_i,
  input  sram_cfg_t [NumClusters-1:0]               sram_cfg_tcdm_i,
  input  sram_cfg_t [NumClusters-1:0][NrHives-1:0] sram_cfg_icache_tag_i,
  input  sram_cfg_t [NumClusters-1:0][NrHives-1:0] sram_cfg_icache_data_i,
  input  snitch_cluster_inputs_t [NumClusters-1:0]  cluster_inputs_i,
  output snitch_cluster_outputs_t [NumClusters-1:0] cluster_outputs_o
);

  for (genvar i = 0; i < NumClusters; i++) begin : gen_clusters
    snitch_cluster_synth i_cluster (
      .clk_i,
      .rst_ni,
      .debug_req_i            (debug_req_i[i]),
      .meip_i                 (meip_i[i]),
      .mtip_i                 (mtip_i[i]),
      .msip_i                 (msip_i[i]),
      .hart_base_id_i         (hart_base_id_i[i]),
      .cluster_base_addr_i    (cluster_base_addr_i[i]),
      .cluster_base_offset_i  (cluster_base_offset_i[i]),
      .clk_d2_bypass_i        (clk_d2_bypass_i[i]),
      .sram_cfg_tcdm_i        (sram_cfg_tcdm_i[i]),
      .sram_cfg_icache_tag_i  (sram_cfg_icache_tag_i[i]),
      .sram_cfg_icache_data_i (sram_cfg_icache_data_i[i]),
      .inputs_i  (cluster_inputs_i[i]),
      .outputs_o (cluster_outputs_o[i])
    );
  end

endmodule
