// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

module cvfpu_full_synth #(
  parameter int unsigned TagWidth = 1
) (
  input  logic                   clk_i,
  input  logic                   rst_ni,
  input  logic [31:0]            hart_id_i,
  input  logic [2:0][63:0]       operands_i,
  input  logic [2:0]             rnd_mode_i,
  input  logic [4:0]             op_i,
  input  logic                   op_mod_i,
  input  logic [3:0]             src_fmt_i,
  input  logic [3:0]             dst_fmt_i,
  input  logic [1:0]             int_fmt_i,
  input  logic                   vectorial_op_i,
  input  logic [7:0]             simd_mask_i,
  input  logic [2079:0]          pace_param_i,
  input  logic [4:0]             pace_mode_i,
  input  logic [TagWidth-1:0]    tag_i,
  input  logic                   in_valid_i,
  output logic                   in_ready_o,
  input  logic                   flush_i,
  output logic [63:0]            result_o,
  output logic [4:0]             status_o,
  output logic [TagWidth-1:0]    tag_o,
  output logic                   out_valid_o,
  input  logic                   out_ready_i,
  output logic                   busy_o
);
  fpnew_pkg::status_t status;

  // RV64D_Xsflt enables PACE and all six operation groups in pulp-v0.3.0.
  // Keep one register in every group to satisfy the PACE feedback-loop
  // requirement with a uniform pipeline configuration.
  localparam fpnew_pkg::fpu_implementation_t FullImplementation = '{
    PipeRegs:   '{default: 1},
    UnitTypes:  '{'{default: fpnew_pkg::MERGED},   // ADDMUL
                  '{default: fpnew_pkg::MERGED},   // DIVSQRT
                  '{default: fpnew_pkg::PARALLEL}, // NONCOMP
                  '{default: fpnew_pkg::MERGED},   // CONV
                  '{default: fpnew_pkg::MERGED},   // DOTP
                  '{default: fpnew_pkg::MERGED}},  // MXDOTP
    PipeConfig: fpnew_pkg::BEFORE
  };

  fpnew_top #(
    .Features       ( fpnew_pkg::RV64D_Xsflt   ),
    .Implementation ( FullImplementation       ),
    .DivSqrtSel     ( fpnew_pkg::THMULTI       ),
    .TagType        ( logic [TagWidth-1:0]      ),
    .EnableSIMDMask ( 1                         )
  ) i_fpnew_top (
    .clk_i,
    .rst_ni,
    .hart_id_i,
    .operands_i,
    .rnd_mode_i     ( fpnew_pkg::roundmode_e'(rnd_mode_i) ),
    .op_i           ( fpnew_pkg::operation_e'(op_i)       ),
    .op_mod_i,
    .src_fmt_i      ( fpnew_pkg::fp_format_e'(src_fmt_i)  ),
    .dst_fmt_i      ( fpnew_pkg::fp_format_e'(dst_fmt_i)  ),
    .int_fmt_i      ( fpnew_pkg::int_format_e'(int_fmt_i) ),
    .vectorial_op_i,
    .tag_i,
    .simd_mask_i,
    .pace_param_i,
    .pace_mode_i    ( fpnew_pkg::pace_mode_t'(pace_mode_i) ),
    .in_valid_i,
    .in_ready_o,
    .flush_i,
    .result_o,
    .status_o       ( status ),
    .tag_o,
    .out_valid_o,
    .out_ready_i,
    .busy_o
  );

  assign status_o = {status.NV, status.DZ, status.OF, status.UF, status.NX};
endmodule
