// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

`include "hci_helpers.svh"

package pulp_benchmark_redmule_pkg;
  localparam hci_package::hci_size_parameter_t HCI_SIZE_tcdm = '{
    DW:  redmule_pkg::MaxDataW,
    AW:  hci_package::DEFAULT_AW,
    BW:  hci_package::DEFAULT_BW,
    UW:  hci_package::DEFAULT_UW,
    IW:  hci_package::DEFAULT_IW,
    EW:  hci_package::DEFAULT_EW,
    EHW: hci_package::DEFAULT_EHW
  };

  typedef struct packed {
    logic test_mode;
    logic w_stream_valid;
    logic [redmule_pkg::MaxDataW-1:0] w_stream_data;
    logic [redmule_pkg::MaxDataW/8-1:0] w_stream_strb;
    logic x_stream_valid;
    logic [redmule_pkg::MaxDataW-1:0] x_stream_data;
    logic [redmule_pkg::MaxDataW/8-1:0] x_stream_strb;
    logic w_stream_ready;
    logic x_stream_ready;
    logic x_issue_req;
    logic x_issue_valid;
    logic x_register;
    logic x_register_valid;
    logic x_commit;
    logic x_commit_valid;
    logic x_result_ready;
    logic sync;
    logic tcdm_gnt;
    logic [HCI_SIZE_tcdm.DW-1:0] tcdm_r_data;
    logic tcdm_r_valid;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.UW):0] tcdm_r_user;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.IW):0] tcdm_r_id;
    logic tcdm_r_opc;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.EW):0] tcdm_r_ecc;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.EHW):0] tcdm_egnt;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.EHW):0] tcdm_r_evalid;
    logic target_req;
    logic [31:0] target_add;
    logic target_wen;
    logic [3:0] target_be;
    logic [31:0] target_data;
    logic [1:0] target_id;
  } redmule_inputs_t;

  typedef struct packed {
    logic busy;
    logic evt;
    logic w_stream_ready;
    logic x_stream_ready;
    logic w_stream_valid;
    logic [redmule_pkg::MaxDataW-1:0] w_stream_data;
    logic [redmule_pkg::MaxDataW/8-1:0] w_stream_strb;
    logic x_stream_valid;
    logic [redmule_pkg::MaxDataW-1:0] x_stream_data;
    logic [redmule_pkg::MaxDataW/8-1:0] x_stream_strb;
    logic x_issue_resp;
    logic x_issue_ready;
    logic x_register_ready;
    logic x_result;
    logic x_result_valid;
    logic sync;
    logic tcdm_req;
    logic [HCI_SIZE_tcdm.AW-1:0] tcdm_add;
    logic tcdm_wen;
    logic [HCI_SIZE_tcdm.DW-1:0] tcdm_data;
    logic [HCI_SIZE_tcdm.DW/HCI_SIZE_tcdm.BW-1:0] tcdm_be;
    logic tcdm_r_ready;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.UW):0] tcdm_user;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.IW):0] tcdm_id;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.EW):0] tcdm_ecc;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.EHW):0] tcdm_ereq;
    logic [hci_package::iomsb(HCI_SIZE_tcdm.EHW):0] tcdm_r_eready;
    logic target_gnt;
    logic [31:0] target_r_data;
    logic target_r_valid;
    logic [1:0] target_r_id;
  } redmule_outputs_t;
endpackage

module redmule_synth
  import pulp_benchmark_redmule_pkg::*;
  import hwpe_ctrl_package::*;
(
  input  logic             clk_i,
  input  logic             rst_ni,
  input  redmule_inputs_t  inputs_i,
  output redmule_outputs_t outputs_o
);

  hwpe_stream_intf_stream #(.DATA_WIDTH(redmule_pkg::MaxDataW)) w_stream_i (.clk(clk_i));
  hwpe_stream_intf_stream #(.DATA_WIDTH(redmule_pkg::MaxDataW)) x_stream_i (.clk(clk_i));
  hwpe_stream_intf_stream #(.DATA_WIDTH(redmule_pkg::MaxDataW)) w_stream_o (.clk(clk_i));
  hwpe_stream_intf_stream #(.DATA_WIDTH(redmule_pkg::MaxDataW)) x_stream_o (.clk(clk_i));
  hci_core_intf #(
    .DW(HCI_SIZE_tcdm.DW),
    .AW(HCI_SIZE_tcdm.AW),
    .BW(HCI_SIZE_tcdm.BW),
    .UW(HCI_SIZE_tcdm.UW),
    .IW(HCI_SIZE_tcdm.IW),
    .EW(HCI_SIZE_tcdm.EW),
    .EHW(HCI_SIZE_tcdm.EHW)
  ) tcdm (.clk(clk_i));
  hwpe_ctrl_intf_periph #(.ID_WIDTH(0)) target (.clk(clk_i));

  assign w_stream_i.valid = inputs_i.w_stream_valid;
  assign w_stream_i.data = inputs_i.w_stream_data;
  assign w_stream_i.strb = inputs_i.w_stream_strb;
  assign outputs_o.w_stream_ready = w_stream_i.ready;
  assign x_stream_i.valid = inputs_i.x_stream_valid;
  assign x_stream_i.data = inputs_i.x_stream_data;
  assign x_stream_i.strb = inputs_i.x_stream_strb;
  assign outputs_o.x_stream_ready = x_stream_i.ready;
  assign w_stream_o.ready = inputs_i.w_stream_ready;
  assign outputs_o.w_stream_valid = w_stream_o.valid;
  assign outputs_o.w_stream_data = w_stream_o.data;
  assign outputs_o.w_stream_strb = w_stream_o.strb;
  assign x_stream_o.ready = inputs_i.x_stream_ready;
  assign outputs_o.x_stream_valid = x_stream_o.valid;
  assign outputs_o.x_stream_data = x_stream_o.data;
  assign outputs_o.x_stream_strb = x_stream_o.strb;

  assign tcdm.gnt = inputs_i.tcdm_gnt;
  assign tcdm.r_data = inputs_i.tcdm_r_data;
  assign tcdm.r_valid = inputs_i.tcdm_r_valid;
  assign tcdm.r_user = inputs_i.tcdm_r_user;
  assign tcdm.r_id = inputs_i.tcdm_r_id;
  assign tcdm.r_opc = inputs_i.tcdm_r_opc;
  assign tcdm.r_ecc = inputs_i.tcdm_r_ecc;
  assign tcdm.egnt = inputs_i.tcdm_egnt;
  assign tcdm.r_evalid = inputs_i.tcdm_r_evalid;
  assign outputs_o.tcdm_req = tcdm.req;
  assign outputs_o.tcdm_add = tcdm.add;
  assign outputs_o.tcdm_wen = tcdm.wen;
  assign outputs_o.tcdm_data = tcdm.data;
  assign outputs_o.tcdm_be = tcdm.be;
  assign outputs_o.tcdm_r_ready = tcdm.r_ready;
  assign outputs_o.tcdm_user = tcdm.user;
  assign outputs_o.tcdm_id = tcdm.id;
  assign outputs_o.tcdm_ecc = tcdm.ecc;
  assign outputs_o.tcdm_ereq = tcdm.ereq;
  assign outputs_o.tcdm_r_eready = tcdm.r_eready;

  assign target.req = inputs_i.target_req;
  assign target.add = inputs_i.target_add;
  assign target.wen = inputs_i.target_wen;
  assign target.be = inputs_i.target_be;
  assign target.data = inputs_i.target_data;
  assign target.id = inputs_i.target_id;
  assign outputs_o.target_gnt = target.gnt;
  assign outputs_o.target_r_data = target.r_data;
  assign outputs_o.target_r_valid = target.r_valid;
  assign outputs_o.target_r_id = target.r_id;

  redmule_top #(
    .CtrlIntfConfig(redmule_pkg::HWPE_TARGET),
    .HCI_SIZE_tcdm(HCI_SIZE_tcdm)
  ) i_redmule_top (
    .clk_i,
    .rst_ni,
    .test_mode_i(inputs_i.test_mode),
    .busy_o(outputs_o.busy),
    .evt_o(outputs_o.evt),
    .w_stream_i,
    .x_stream_i,
    .w_stream_o,
    .x_stream_o,
    .x_issue_req_i(inputs_i.x_issue_req),
    .x_issue_resp_o(outputs_o.x_issue_resp),
    .x_issue_valid_i(inputs_i.x_issue_valid),
    .x_issue_ready_o(outputs_o.x_issue_ready),
    .x_register_i(inputs_i.x_register),
    .x_register_valid_i(inputs_i.x_register_valid),
    .x_register_ready_o(outputs_o.x_register_ready),
    .x_commit_i(inputs_i.x_commit),
    .x_commit_valid_i(inputs_i.x_commit_valid),
    .x_result_o(outputs_o.x_result),
    .x_result_valid_o(outputs_o.x_result_valid),
    .x_result_ready_i(inputs_i.x_result_ready),
    .sync_o(outputs_o.sync),
    .sync_i(inputs_i.sync),
    .tcdm,
    .target
  );

endmodule
