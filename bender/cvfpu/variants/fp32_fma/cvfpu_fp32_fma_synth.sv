// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

module cvfpu_fp32_fma_synth #(
  parameter int unsigned TagWidth = 1
) (
  input  logic                   clk_i,
  input  logic                   rst_ni,
  input  logic [2:0][31:0]       operands_i,
  input  logic [2:0]             is_boxed_i,
  input  logic [2:0]             rnd_mode_i,
  input  logic [4:0]             op_i,
  input  logic                   op_mod_i,
  input  logic [TagWidth-1:0]    tag_i,
  input  logic                   mask_i,
  input  logic                   aux_i,
  input  logic                   in_valid_i,
  output logic                   in_ready_o,
  input  logic                   flush_i,
  output logic [31:0]            result_o,
  output logic [4:0]             status_o,
  output logic                   extension_bit_o,
  output logic [TagWidth-1:0]    tag_o,
  output logic                   mask_o,
  output logic                   aux_o,
  output logic                   out_valid_o,
  input  logic                   out_ready_i,
  output logic                   busy_o
);
  fpnew_pkg::status_t status;
  fpnew_fma #(
    .FpFormat    ( fpnew_pkg::FP32       ),
    .NumPipeRegs ( 0                     ),
    .PipeConfig  ( fpnew_pkg::BEFORE     ),
    .TagType     ( logic [TagWidth-1:0]  ),
    .AuxType     ( logic                 )
  ) i_fpnew_fma (
    .clk_i,
    .rst_ni,
    .operands_i,
    .is_boxed_i,
    .rnd_mode_i     ( fpnew_pkg::roundmode_e'(rnd_mode_i) ),
    .op_i           ( fpnew_pkg::operation_e'(op_i) ),
    .op_mod_i,
    .tag_i,
    .mask_i,
    .aux_i,
    .in_valid_i,
    .in_ready_o,
    .flush_i,
    .result_o,
    .status_o       ( status ),
    .extension_bit_o,
    .tag_o,
    .mask_o,
    .aux_o,
    .out_valid_o,
    .out_ready_i,
    .busy_o
  );

  assign status_o = {status.NV, status.DZ, status.OF, status.UF, status.NX};
endmodule
