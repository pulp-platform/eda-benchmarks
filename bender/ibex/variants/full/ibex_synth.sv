// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

package pulp_benchmark_ibex_pkg;
  typedef struct packed {
    logic instr_gnt_i;
    logic instr_rvalid_i;
    logic [31:0] instr_rdata_i;
    logic [6:0] instr_rdata_intg_i;
    logic instr_err_i;
    logic data_gnt_i;
    logic data_rvalid_i;
    logic [31:0] data_rdata_i;
    logic [6:0] data_rdata_intg_i;
    logic data_err_i;
  } ibex_inputs_t;

  typedef struct packed {
    prim_ram_1p_pkg::ram_1p_cfg_rsp_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_tag_o;
    prim_ram_1p_pkg::ram_1p_cfg_rsp_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_data_o;
    logic instr_req_o;
    logic [31:0] instr_addr_o;
    logic data_req_o;
    logic data_we_o;
    logic [3:0] data_be_o;
    logic [31:0] data_addr_o;
    logic [31:0] data_wdata_o;
    logic [6:0] data_wdata_intg_o;
    logic scramble_req_o;
    ibex_pkg::crash_dump_t crash_dump_o;
    logic double_fault_seen_o;
    logic alert_minor_o;
    logic alert_major_internal_o;
    logic alert_major_bus_o;
    logic core_sleep_o;
    ibex_pkg::ibex_mubi_t lockstep_cmp_en_o;
    logic data_req_shadow_o;
    logic data_we_shadow_o;
    logic [3:0] data_be_shadow_o;
    logic [31:0] data_addr_shadow_o;
    logic [31:0] data_wdata_shadow_o;
    logic [6:0] data_wdata_intg_shadow_o;
    logic instr_req_shadow_o;
    logic [31:0] instr_addr_shadow_o;
  } ibex_outputs_t;
endpackage

module ibex_synth
  import pulp_benchmark_ibex_pkg::*;
#(
  parameter bit PMPEnable = 1'b0,
  parameter int unsigned PMPGranularity = 0,
  parameter int unsigned PMPNumRegions = 4,
  parameter int unsigned MHPMCounterNum = 0,
  parameter int unsigned MHPMCounterWidth = 40,
  parameter ibex_pkg::rv32m_e RV32M = ibex_pkg::RV32MFast,
  parameter ibex_pkg::rv32b_e RV32B = ibex_pkg::RV32BNone,
  parameter ibex_pkg::rv32zc_e RV32ZC = ibex_pkg::RV32ZcaZcbZcmp,
  parameter bit BranchTargetALU = 1'b0,
  parameter bit WritebackStage = 1'b0,
  parameter bit ICache = 1'b0,
  parameter bit ICacheECC = 1'b0,
  parameter bit BranchPredictor = 1'b0,
  parameter bit DbgTriggerEn = 1'b0,
  parameter int unsigned DbgHwBreakNum = 1,
  parameter bit SecureIbex = 1'b0,
  parameter int unsigned LockstepOffset = 1,
  parameter bit MemECC = SecureIbex,
  parameter bit ICacheScramble = 1'b0,
  parameter bit ICacheTweakInfection = SecureIbex
) (
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic          test_en_i,
  input  prim_ram_1p_pkg::ram_1p_cfg_req_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_tag_i,
  input  prim_ram_1p_pkg::ram_1p_cfg_req_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_data_i,
  input  logic [31:0]   hart_id_i,
  input  logic [31:0]   boot_addr_i,
  input  logic          irq_software_i,
  input  logic          irq_timer_i,
  input  logic          irq_external_i,
  input  logic [14:0]   irq_fast_i,
  input  logic          irq_nm_i,
  input  logic          scramble_key_valid_i,
  input  logic [ibex_pkg::SCRAMBLE_KEY_W-1:0] scramble_key_i,
  input  logic [ibex_pkg::SCRAMBLE_NONCE_W-1:0] scramble_nonce_i,
  input  logic          debug_req_i,
  input  ibex_pkg::ibex_mubi_t fetch_enable_i,
  input  ibex_pkg::ibex_mubi_t mcounteren_writable_i,
  input  logic          scan_rst_ni,
  input  ibex_inputs_t  inputs_i,
  output ibex_outputs_t outputs_o
);

  ibex_top #(
    .PMPEnable(PMPEnable),
    .PMPGranularity(PMPGranularity),
    .PMPNumRegions(PMPNumRegions),
    .MHPMCounterNum(MHPMCounterNum),
    .MHPMCounterWidth(MHPMCounterWidth),
    .RV32E(1'b0),
    .RV32M(RV32M),
    .RV32B(RV32B),
    .RV32ZC(RV32ZC),
    .RegFile(ibex_pkg::RegFileFF),
    .BranchTargetALU(BranchTargetALU),
    .WritebackStage(WritebackStage),
    .ICache(ICache),
    .ICacheECC(ICacheECC),
    .BranchPredictor(BranchPredictor),
    .DbgTriggerEn(DbgTriggerEn),
    .DbgHwBreakNum(DbgHwBreakNum),
    .SecureIbex(SecureIbex),
    .LockstepOffset(LockstepOffset),
    .MemECC(MemECC),
    .ICacheScramble(ICacheScramble),
    .ICacheTweakInfection(ICacheTweakInfection),
    .DmBaseAddr(32'h0000_0000),
    .DmAddrMask(32'h0000_0fff),
    .DmHaltAddr(32'h0000_0800),
    .DmExceptionAddr(32'h0000_0f00)
  ) i_ibex_top (
    .clk_i,
    .rst_ni,
    .test_en_i,
    .ram_cfg_icache_tag_i,
    .ram_cfg_icache_tag_o(outputs_o.ram_cfg_icache_tag_o),
    .ram_cfg_icache_data_i,
    .ram_cfg_icache_data_o(outputs_o.ram_cfg_icache_data_o),
    .hart_id_i,
    .boot_addr_i,
    .instr_req_o(outputs_o.instr_req_o),
    .instr_gnt_i(inputs_i.instr_gnt_i),
    .instr_rvalid_i(inputs_i.instr_rvalid_i),
    .instr_addr_o(outputs_o.instr_addr_o),
    .instr_rdata_i(inputs_i.instr_rdata_i),
    .instr_rdata_intg_i(inputs_i.instr_rdata_intg_i),
    .instr_err_i(inputs_i.instr_err_i),
    .data_req_o(outputs_o.data_req_o),
    .data_gnt_i(inputs_i.data_gnt_i),
    .data_rvalid_i(inputs_i.data_rvalid_i),
    .data_we_o(outputs_o.data_we_o),
    .data_be_o(outputs_o.data_be_o),
    .data_addr_o(outputs_o.data_addr_o),
    .data_wdata_o(outputs_o.data_wdata_o),
    .data_wdata_intg_o(outputs_o.data_wdata_intg_o),
    .data_rdata_i(inputs_i.data_rdata_i),
    .data_rdata_intg_i(inputs_i.data_rdata_intg_i),
    .data_err_i(inputs_i.data_err_i),
    .irq_software_i,
    .irq_timer_i,
    .irq_external_i,
    .irq_fast_i,
    .irq_nm_i,
    .scramble_key_valid_i,
    .scramble_key_i,
    .scramble_nonce_i,
    .scramble_req_o(outputs_o.scramble_req_o),
    .debug_req_i,
    .crash_dump_o(outputs_o.crash_dump_o),
    .double_fault_seen_o(outputs_o.double_fault_seen_o),
    .fetch_enable_i,
    .mcounteren_writable_i,
    .alert_minor_o(outputs_o.alert_minor_o),
    .alert_major_internal_o(outputs_o.alert_major_internal_o),
    .alert_major_bus_o(outputs_o.alert_major_bus_o),
    .core_sleep_o(outputs_o.core_sleep_o),
    .scan_rst_ni,
    .lockstep_cmp_en_o(outputs_o.lockstep_cmp_en_o),
    .data_req_shadow_o(outputs_o.data_req_shadow_o),
    .data_we_shadow_o(outputs_o.data_we_shadow_o),
    .data_be_shadow_o(outputs_o.data_be_shadow_o),
    .data_addr_shadow_o(outputs_o.data_addr_shadow_o),
    .data_wdata_shadow_o(outputs_o.data_wdata_shadow_o),
    .data_wdata_intg_shadow_o(outputs_o.data_wdata_intg_shadow_o),
    .instr_req_shadow_o(outputs_o.instr_req_shadow_o),
    .instr_addr_shadow_o(outputs_o.instr_addr_shadow_o)
  );

endmodule
