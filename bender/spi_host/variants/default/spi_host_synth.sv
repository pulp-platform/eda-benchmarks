// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

`include "register_interface/typedef.svh"

package pulp_benchmark_spi_host_pkg;
  typedef logic [31:0] addr_t;
  typedef logic [31:0] data_t;
  typedef logic [3:0]  strb_t;
  `REG_BUS_TYPEDEF_ALL(reg, addr_t, data_t, strb_t)
endpackage

module spi_host_synth
  import pulp_benchmark_spi_host_pkg::*;
(
  input  logic       clk_i,
  input  logic       rst_ni,
  input  reg_req_t   reg_req_i,
  output reg_rsp_t   reg_rsp_o,
  output logic       cio_sck_o,
  output logic       cio_sck_en_o,
  output logic [2:0] cio_csb_o,
  output logic [2:0] cio_csb_en_o,
  output logic [3:0] cio_sd_o,
  output logic [3:0] cio_sd_en_o,
  input  logic [3:0] cio_sd_i,
  output logic       intr_error_o,
  output logic       intr_spi_event_o
);

  spi_host #(
    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t)
  ) i_spi_host (
    .clk_i,
    .rst_ni,
    .reg_req_i,
    .reg_rsp_o,
    .cio_sck_o,
    .cio_sck_en_o,
    .cio_csb_o,
    .cio_csb_en_o,
    .cio_sd_o,
    .cio_sd_en_o,
    .cio_sd_i,
    .intr_error_o,
    .intr_spi_event_o
  );

endmodule
