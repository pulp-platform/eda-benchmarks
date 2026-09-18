// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

`include "axi/typedef.svh"

typedef logic [39:0]  c910_axi_addr_t;
typedef logic [127:0] c910_axi_data_t;
typedef logic [15:0]  c910_axi_strb_t;
typedef logic [7:0]   c910_axi_id_t;
typedef logic         c910_axi_user_t;

`AXI_TYPEDEF_AW_CHAN_T(c910_axi_aw_chan_t, c910_axi_addr_t, c910_axi_id_t, c910_axi_user_t)
`AXI_TYPEDEF_W_CHAN_T(c910_axi_w_chan_t, c910_axi_data_t, c910_axi_strb_t, c910_axi_user_t)
`AXI_TYPEDEF_B_CHAN_T(c910_axi_b_chan_t, c910_axi_id_t, c910_axi_user_t)
`AXI_TYPEDEF_AR_CHAN_T(c910_axi_ar_chan_t, c910_axi_addr_t, c910_axi_id_t, c910_axi_user_t)
`AXI_TYPEDEF_R_CHAN_T(c910_axi_r_chan_t, c910_axi_data_t, c910_axi_id_t, c910_axi_user_t)
`AXI_TYPEDEF_REQ_T(c910_axi_req_t, c910_axi_aw_chan_t, c910_axi_w_chan_t, c910_axi_ar_chan_t)
`AXI_TYPEDEF_RESP_T(c910_axi_rsp_t, c910_axi_b_chan_t, c910_axi_r_chan_t)

module pulp_c910_synth (
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic          rtc_i,
  input  logic          ipi_i,
  input  logic          time_irq_i,
  input  logic [1:0]    plic_hartx_mint_req_i,
  input  logic [1:0]    plic_hartx_sint_req_i,
  input  logic          debug_req_i,
  input  logic [39:0]   ext_int_i,
  input  logic          jtag_tck_i,
  input  logic          jtag_tdi_i,
  input  logic          jtag_tms_i,
  output logic          jtag_tdo_o,
  output logic          jtag_tdo_en_o,
  input  logic          jtag_trst_ni,
  output c910_axi_req_t axi_req_o,
  input  c910_axi_rsp_t axi_rsp_i
);

  c910_axi_wrap #(
    .AddrWidth (40),
    .DataWidth (128),
    .IdWidth   (8),
    .UserWidth (1),
    .aw_chan_t (c910_axi_aw_chan_t),
    .w_chan_t  (c910_axi_w_chan_t),
    .b_chan_t  (c910_axi_b_chan_t),
    .ar_chan_t (c910_axi_ar_chan_t),
    .r_chan_t  (c910_axi_r_chan_t),
    .axi_req_t (c910_axi_req_t),
    .axi_rsp_t (c910_axi_rsp_t)
  ) i_c910_axi_wrap (
    .clk_i,
    .rst_ni,
    .rtc_i,
    .ipi_i,
    .time_irq_i,
    .plic_hartx_mint_req_i,
    .plic_hartx_sint_req_i,
    .debug_req_i,
    .ext_int_i,
    .jtag_tck_i,
    .jtag_tdi_i,
    .jtag_tms_i,
    .jtag_tdo_o,
    .jtag_tdo_en_o,
    .jtag_trst_ni,
    .axi_req_o,
    .axi_rsp_i
  );

endmodule
