// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

package oseda_bench_cheshire_pkg;
  localparam cheshire_pkg::cheshire_cfg_t Cfg = cheshire_pkg::DefaultCfg;

  `include "cheshire/typedef.svh"
  `CHESHIRE_TYPEDEF_ALL(cheshire_, Cfg)
endpackage

module cheshire_synth
  import oseda_bench_cheshire_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_mode_i,
  input  logic [1:0] boot_mode_i,
  input  logic rtc_i,

  output cheshire_axi_llc_req_t axi_llc_mst_req_o,
  input  cheshire_axi_llc_rsp_t axi_llc_mst_rsp_i,
  input  cheshire_axi_mst_req_t [cheshire_pkg::iomsb(Cfg.AxiExtNumMst):0] axi_ext_mst_req_i,
  output cheshire_axi_mst_rsp_t [cheshire_pkg::iomsb(Cfg.AxiExtNumMst):0] axi_ext_mst_rsp_o,
  output cheshire_axi_slv_req_t [cheshire_pkg::iomsb(Cfg.AxiExtNumSlv):0] axi_ext_slv_req_o,
  input  cheshire_axi_slv_rsp_t [cheshire_pkg::iomsb(Cfg.AxiExtNumSlv):0] axi_ext_slv_rsp_i,
  output cheshire_reg_req_t [cheshire_pkg::iomsb(Cfg.RegExtNumSlv):0] reg_ext_slv_req_o,
  input  cheshire_reg_rsp_t [cheshire_pkg::iomsb(Cfg.RegExtNumSlv):0] reg_ext_slv_rsp_i,

  input  logic [cheshire_pkg::iomsb(Cfg.NumExtInIntrs):0] intr_ext_i,
  output logic [cheshire_pkg::iomsb(Cfg.NumExtOutIntrTgts):0]
               [cheshire_pkg::iomsb(Cfg.NumExtOutIntrs):0] intr_ext_o,
  output logic [cheshire_pkg::iomsb(cheshire_pkg::NumIrqCtxts*Cfg.NumExtIrqHarts):0] xeip_ext_o,
  output logic [cheshire_pkg::iomsb(Cfg.NumExtIrqHarts):0] mtip_ext_o,
  output logic [cheshire_pkg::iomsb(Cfg.NumExtIrqHarts):0] msip_ext_o,
  output logic dbg_active_o,
  output logic [cheshire_pkg::iomsb(Cfg.NumExtDbgHarts):0] dbg_ext_req_o,
  input  logic [cheshire_pkg::iomsb(Cfg.NumExtDbgHarts):0] dbg_ext_unavail_i,

  input  logic jtag_tck_i,
  input  logic jtag_trst_ni,
  input  logic jtag_tms_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o,
  output logic jtag_tdo_oe_o,
  output logic uart_tx_o,
  input  logic uart_rx_i,
  output logic uart_rts_no,
  output logic uart_dtr_no,
  input  logic uart_cts_ni,
  input  logic uart_dsr_ni,
  input  logic uart_dcd_ni,
  input  logic uart_rin_ni,
  output logic i2c_sda_o,
  input  logic i2c_sda_i,
  output logic i2c_sda_en_o,
  output logic i2c_scl_o,
  input  logic i2c_scl_i,
  output logic i2c_scl_en_o,

  output logic spih_sck_o,
  output logic spih_sck_en_o,
  output logic [cheshire_pkg::SpihNumCs-1:0] spih_csb_o,
  output logic [cheshire_pkg::SpihNumCs-1:0] spih_csb_en_o,
  output logic [3:0] spih_sd_o,
  output logic [3:0] spih_sd_en_o,
  input  logic [3:0] spih_sd_i,
  input  logic [31:0] gpio_i,
  output logic [31:0] gpio_o,
  output logic [31:0] gpio_en_o,

  input  logic [cheshire_pkg::SlinkNumChan-1:0] slink_rcv_clk_i,
  output logic [cheshire_pkg::SlinkNumChan-1:0] slink_rcv_clk_o,
  input  logic [cheshire_pkg::SlinkNumChan-1:0]
               [cheshire_pkg::SlinkNumLanes-1:0] slink_i,
  output logic [cheshire_pkg::SlinkNumChan-1:0]
               [cheshire_pkg::SlinkNumLanes-1:0] slink_o,
  output logic vga_hsync_o,
  output logic vga_vsync_o,
  output logic [Cfg.VgaRedWidth-1:0] vga_red_o,
  output logic [Cfg.VgaGreenWidth-1:0] vga_green_o,
  output logic [Cfg.VgaBlueWidth-1:0] vga_blue_o,

  input  logic usb_clk_i,
  input  logic usb_rst_ni,
  input  logic [cheshire_pkg::UsbNumPorts-1:0] usb_dm_i,
  output logic [cheshire_pkg::UsbNumPorts-1:0] usb_dm_o,
  output logic [cheshire_pkg::UsbNumPorts-1:0] usb_dm_oe_o,
  input  logic [cheshire_pkg::UsbNumPorts-1:0] usb_dp_i,
  output logic [cheshire_pkg::UsbNumPorts-1:0] usb_dp_o,
  output logic [cheshire_pkg::UsbNumPorts-1:0] usb_dp_oe_o
);

  cheshire_soc #(
    .Cfg(Cfg),
    .axi_ext_llc_req_t(cheshire_axi_llc_req_t),
    .axi_ext_llc_rsp_t(cheshire_axi_llc_rsp_t),
    .axi_ext_mst_req_t(cheshire_axi_mst_req_t),
    .axi_ext_mst_rsp_t(cheshire_axi_mst_rsp_t),
    .axi_ext_slv_req_t(cheshire_axi_slv_req_t),
    .axi_ext_slv_rsp_t(cheshire_axi_slv_rsp_t),
    .reg_ext_req_t(cheshire_reg_req_t),
    .reg_ext_rsp_t(cheshire_reg_rsp_t)
  ) i_cheshire_soc (.*);

endmodule
