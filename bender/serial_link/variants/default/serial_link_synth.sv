// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

`include "axi/typedef.svh"
`include "apb/typedef.svh"

package oseda_bench_serial_link_pkg;
  typedef logic [31:0] addr_t;
  typedef logic [63:0] data_t;
  typedef logic [7:0]  strb_t;
  typedef logic [3:0]  id_t;
  typedef logic        user_t;

  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(r_chan_t, data_t, id_t, user_t)
  `AXI_TYPEDEF_REQ_T(axi_req_t, aw_chan_t, w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(axi_rsp_t, b_chan_t, r_chan_t)

  typedef logic [31:0] apb_addr_t;
  typedef logic [31:0] apb_data_t;
  typedef logic [3:0]  apb_strb_t;
  `APB_TYPEDEF_REQ_T(apb_req_t, apb_addr_t, apb_data_t, apb_strb_t)
  `APB_TYPEDEF_RESP_T(apb_rsp_t, apb_data_t)
endpackage

module serial_link_synth
  import oseda_bench_serial_link_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic clk_sl_i,
  input  logic rst_sl_ni,
  input  logic clk_reg_i,
  input  logic rst_reg_ni,
  input  logic testmode_i,
  input  axi_req_t axi_in_req_i,
  output axi_rsp_t axi_in_rsp_o,
  output axi_req_t axi_out_req_o,
  input  axi_rsp_t axi_out_rsp_i,
  input  apb_req_t apb_req_i,
  output apb_rsp_t apb_rsp_o,
  input  logic [slink_reg_pkg::NumChannels-1:0] slink_rcv_clk_i,
  output logic [slink_reg_pkg::NumChannels-1:0] slink_rcv_clk_o,
  input  logic [slink_reg_pkg::NumChannels-1:0][slink_reg_pkg::NumLanes-1:0] slink_i,
  output logic [slink_reg_pkg::NumChannels-1:0][slink_reg_pkg::NumLanes-1:0] slink_o,
  input  logic [1:0] isolated_i,
  output logic [1:0] isolate_o,
  output logic clk_ena_o,
  output logic reset_no
);

  slink #(
    .axi_req_t(axi_req_t),
    .axi_rsp_t(axi_rsp_t),
    .aw_chan_t(aw_chan_t),
    .ar_chan_t(ar_chan_t),
    .r_chan_t(r_chan_t),
    .w_chan_t(w_chan_t),
    .b_chan_t(b_chan_t),
    .apb_req_t(apb_req_t),
    .apb_rsp_t(apb_rsp_t),
    .apb_addr_t(apb_addr_t),
    .apb_data_t(apb_data_t),
    .apb_strb_t(apb_strb_t)
  ) i_slink (
    .clk_i,
    .rst_ni,
    .clk_sl_i,
    .rst_sl_ni,
    .clk_reg_i,
    .rst_reg_ni,
    .testmode_i,
    .axi_in_req_i,
    .axi_in_rsp_o,
    .axi_out_req_o,
    .axi_out_rsp_i,
    .apb_req_i,
    .apb_rsp_o,
    .ddr_rcv_clk_i(slink_rcv_clk_i),
    .ddr_rcv_clk_o(slink_rcv_clk_o),
    .ddr_i(slink_i),
    .ddr_o(slink_o),
    .isolated_i,
    .isolate_o,
    .clk_ena_o,
    .reset_no
  );

endmodule
