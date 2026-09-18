// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

package oseda_bench_ara_pkg;
  `include "axi/typedef.svh"
  `include "ara/intf_typedef.svh"

  localparam int unsigned NrLanes = 4;
  localparam int unsigned VLEN = 4096;
  localparam int unsigned AxiDataWidth = 32 * NrLanes;
  localparam int unsigned AxiAddrWidth = 64;
  localparam int unsigned AxiIdWidth = 4;
  localparam int unsigned AxiUserWidth = 1;

  typedef logic [AxiDataWidth-1:0] axi_data_t;
  typedef logic [AxiDataWidth/8-1:0] axi_strb_t;
  typedef logic [AxiAddrWidth-1:0] axi_addr_t;
  typedef logic [AxiIdWidth-1:0] axi_id_t;
  typedef logic [AxiUserWidth-1:0] axi_user_t;

  `AXI_TYPEDEF_ALL(ara_axi, axi_addr_t, axi_id_t, axi_data_t, axi_strb_t, axi_user_t)

  localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  `CVA6_TYPEDEF_EXCEPTION(exception_t, CVA6Cfg)
  `CVA6_INTF_TYPEDEF_ACC_REQ(accelerator_req_t, CVA6Cfg, fpnew_pkg::roundmode_e)
  `CVA6_INTF_TYPEDEF_ACC_RESP(accelerator_resp_t, CVA6Cfg, exception_t)
  `CVA6_INTF_TYPEDEF_MMU_REQ(acc_mmu_req_t, CVA6Cfg)
  `CVA6_INTF_TYPEDEF_MMU_RESP(acc_mmu_resp_t, CVA6Cfg, exception_t)
  `CVA6_INTF_TYPEDEF_CVA6_TO_ACC(cva6_to_acc_t, accelerator_req_t, acc_mmu_resp_t)
  `CVA6_INTF_TYPEDEF_ACC_TO_CVA6(acc_to_cva6_t, accelerator_resp_t, acc_mmu_req_t)
endpackage

module ara_synth
  import oseda_bench_ara_pkg::*;
(
  input  logic         clk_i,
  input  logic         rst_ni,
  input  logic         scan_enable_i,
  input  logic         scan_data_i,
  output logic         scan_data_o,
  input  cva6_to_acc_t acc_req_i,
  output acc_to_cva6_t acc_resp_o,
  output ara_axi_req_t axi_req_o,
  input  ara_axi_resp_t axi_resp_i
);

  ara #(
    .NrLanes(NrLanes),
    .VLEN(VLEN),
    .CVA6Cfg(CVA6Cfg),
    .exception_t(exception_t),
    .accelerator_req_t(accelerator_req_t),
    .accelerator_resp_t(accelerator_resp_t),
    .acc_mmu_req_t(acc_mmu_req_t),
    .acc_mmu_resp_t(acc_mmu_resp_t),
    .cva6_to_acc_t(cva6_to_acc_t),
    .acc_to_cva6_t(acc_to_cva6_t),
    .AxiDataWidth(AxiDataWidth),
    .AxiAddrWidth(AxiAddrWidth),
    .axi_ar_t(ara_axi_ar_chan_t),
    .axi_r_t(ara_axi_r_chan_t),
    .axi_aw_t(ara_axi_aw_chan_t),
    .axi_w_t(ara_axi_w_chan_t),
    .axi_b_t(ara_axi_b_chan_t),
    .axi_req_t(ara_axi_req_t),
    .axi_resp_t(ara_axi_resp_t)
  ) i_ara (
    .clk_i,
    .rst_ni,
    .scan_enable_i,
    .scan_data_i,
    .scan_data_o,
    .acc_req_i,
    .acc_resp_o,
    .axi_req_o,
    .axi_resp_i
  );
endmodule
