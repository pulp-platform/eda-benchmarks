// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

package pulp_benchmark_snitch_cluster_pkg;
  import snitch_cluster_wrapper_pkg::*;

  typedef struct packed {
    logic [NrCores-1:0]                       mxip;
    narrow_in_req_t                           narrow_in_req;
    narrow_out_resp_t                         narrow_out_resp;
    wide_out_resp_t                           wide_out_resp;
    wide_in_req_t                             wide_in_req;
    x_issue_resp_t [NrCores-1:0]              x_issue_resp;
    logic [NrCores-1:0]                       x_issue_ready;
    logic [NrCores-1:0]                       x_register_ready;
    x_result_t [NrCores-1:0]                  x_result;
    logic [NrCores-1:0]                       x_result_valid;
    narrow_out_resp_t                         narrow_ext_resp;
    tcdm_dma_req_t [NumExpWideTcdmPorts-1:0]  tcdm_ext_req;
    dca_req_t                                 dca_req;
  } snitch_cluster_inputs_t;

  typedef struct packed {
    narrow_in_resp_t                          narrow_in_resp;
    narrow_out_req_t                          narrow_out_req;
    wide_out_req_t                            wide_out_req;
    wide_in_resp_t                            wide_in_resp;
    x_issue_req_t [NrCores-1:0]               x_issue_req;
    logic [NrCores-1:0]                       x_issue_valid;
    x_register_t [NrCores-1:0]                x_register;
    logic [NrCores-1:0]                       x_register_valid;
    x_commit_t [NrCores-1:0]                  x_commit;
    logic [NrCores-1:0]                       x_commit_valid;
    logic [NrCores-1:0]                       x_result_ready;
    narrow_out_req_t                          narrow_ext_req;
    tcdm_dma_rsp_t [NumExpWideTcdmPorts-1:0]  tcdm_ext_resp;
    dca_rsp_t                                 dca_rsp;
  } snitch_cluster_outputs_t;
endpackage

`ifndef OSEDA_SNITCH_CLUSTER_PARENT_ONLY

module snitch_cluster_synth
  import pulp_benchmark_snitch_cluster_pkg::*;
  import snitch_cluster_wrapper_pkg::*;
(
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic [NrCores-1:0]       debug_req_i,
  input  logic [NrCores-1:0]       meip_i,
  input  logic [NrCores-1:0]       mtip_i,
  input  logic [NrCores-1:0]       msip_i,
  input  snitch_cluster_pkg::hart_id_t hart_base_id_i,
  input  logic [AddrWidth-1:0]     cluster_base_addr_i,
  input  logic [AddrWidth-1:0]     cluster_base_offset_i,
  input  logic                     clk_d2_bypass_i,
  input  sram_cfg_t                sram_cfg_tcdm_i,
  input  sram_cfg_t [NrHives-1:0] sram_cfg_icache_tag_i,
  input  sram_cfg_t [NrHives-1:0] sram_cfg_icache_data_i,
  input  snitch_cluster_inputs_t   inputs_i,
  output snitch_cluster_outputs_t  outputs_o
);

  snitch_cluster_wrapper i_cluster (
    .clk_i,
    .rst_ni,
    .debug_req_i,
    .meip_i,
    .mtip_i,
    .msip_i,
    .mxip_i                 (inputs_i.mxip),
    .hart_base_id_i,
    .cluster_base_addr_i,
    .cluster_base_offset_i,
    .clk_d2_bypass_i,
    .sram_cfg_tcdm_i,
    .sram_cfg_icache_tag_i,
    .sram_cfg_icache_data_i,
    .narrow_in_req_i        (inputs_i.narrow_in_req),
    .narrow_in_resp_o       (outputs_o.narrow_in_resp),
    .narrow_out_req_o       (outputs_o.narrow_out_req),
    .narrow_out_resp_i      (inputs_i.narrow_out_resp),
    .wide_out_req_o         (outputs_o.wide_out_req),
    .wide_out_resp_i        (inputs_i.wide_out_resp),
    .wide_in_req_i          (inputs_i.wide_in_req),
    .wide_in_resp_o         (outputs_o.wide_in_resp),
    .x_issue_req_o          (outputs_o.x_issue_req),
    .x_issue_resp_i         (inputs_i.x_issue_resp),
    .x_issue_valid_o        (outputs_o.x_issue_valid),
    .x_issue_ready_i        (inputs_i.x_issue_ready),
    .x_register_o           (outputs_o.x_register),
    .x_register_valid_o     (outputs_o.x_register_valid),
    .x_register_ready_i     (inputs_i.x_register_ready),
    .x_commit_o             (outputs_o.x_commit),
    .x_commit_valid_o       (outputs_o.x_commit_valid),
    .x_result_i             (inputs_i.x_result),
    .x_result_valid_i       (inputs_i.x_result_valid),
    .x_result_ready_o       (outputs_o.x_result_ready),
    .narrow_ext_req_o       (outputs_o.narrow_ext_req),
    .narrow_ext_resp_i      (inputs_i.narrow_ext_resp),
    .tcdm_ext_req_i         (inputs_i.tcdm_ext_req),
    .tcdm_ext_resp_o        (outputs_o.tcdm_ext_resp),
    .dca_req_i              (inputs_i.dca_req),
    .dca_rsp_o              (outputs_o.dca_rsp)
  );

endmodule

module snitch_cluster_default_synth
  import pulp_benchmark_snitch_cluster_pkg::*;
  import snitch_cluster_wrapper_pkg::*;
(
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic [NrCores-1:0]       debug_req_i,
  input  logic [NrCores-1:0]       meip_i,
  input  logic [NrCores-1:0]       mtip_i,
  input  logic [NrCores-1:0]       msip_i,
  input  snitch_cluster_pkg::hart_id_t hart_base_id_i,
  input  logic [AddrWidth-1:0]     cluster_base_addr_i,
  input  logic [AddrWidth-1:0]     cluster_base_offset_i,
  input  logic                     clk_d2_bypass_i,
  input  sram_cfg_t                sram_cfg_tcdm_i,
  input  sram_cfg_t [NrHives-1:0] sram_cfg_icache_tag_i,
  input  sram_cfg_t [NrHives-1:0] sram_cfg_icache_data_i,
  input  snitch_cluster_inputs_t   inputs_i,
  output snitch_cluster_outputs_t  outputs_o
);

  snitch_cluster_synth i_cluster (.*);

endmodule

`endif
