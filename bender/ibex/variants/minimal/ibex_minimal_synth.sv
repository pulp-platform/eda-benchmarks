// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: Apache-2.0

module ibex_minimal_synth
  import oseda_bench_ibex_pkg::*;
(
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

  ibex_synth #(
    .RV32M(ibex_pkg::RV32MFast)
  ) i_ibex (.*);

endmodule
