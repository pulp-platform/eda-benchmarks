// Copyright (c) 2026 ETH Zurich and University of Bologna.
// SPDX-License-Identifier: SHL-0.51

// Synthesis-only SRAM declarations matching tech_cells_generic. The public
// wrapper preserves parameters as metadata and instantiates a blackbox leaf.
module tc_sram #(
  parameter int unsigned NumWords     = 32'd1024,
  parameter int unsigned DataWidth    = 32'd128,
  parameter int unsigned ByteWidth    = 32'd8,
  parameter int unsigned NumPorts     = 32'd2,
  parameter int unsigned Latency      = 32'd1,
  parameter              SimInit      = "none",
  parameter bit          PrintSimCfg  = 1'b0,
  parameter              ImplKey      = "none",
  parameter              FPGAImplKey  = "auto",
  parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth,
  parameter type         addr_t    = logic [AddrWidth-1:0],
  parameter type         data_t    = logic [DataWidth-1:0],
  parameter type         be_t      = logic [BeWidth-1:0]
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic  [NumPorts-1:0] req_i,
  input  logic  [NumPorts-1:0] we_i,
  input  addr_t [NumPorts-1:0] addr_i,
  input  data_t [NumPorts-1:0] wdata_i,
  input  be_t   [NumPorts-1:0] be_i,
  output data_t [NumPorts-1:0] rdata_o
);

  (* sram_num_words = NumWords, sram_data_width = DataWidth,
     sram_byte_width = ByteWidth, sram_num_ports = NumPorts,
     sram_latency = Latency, sram_impl_key = ImplKey *)
  tc_sram_blackbox #(
    .NumWords    (NumWords),
    .DataWidth   (DataWidth),
    .ByteWidth   (ByteWidth),
    .NumPorts    (NumPorts),
    .Latency     (Latency),
    .SimInit     (SimInit),
    .PrintSimCfg (PrintSimCfg),
    .ImplKey     (ImplKey),
    .FPGAImplKey (FPGAImplKey)
  ) i_tc_sram_blackbox (.*);

endmodule

// The leaf uses value-parameter widths because yosys-slang blackboxes cannot
// carry type parameters. The public wrapper retains the exact type interface.
(* black_box, syn_black_box = 1 *)
module tc_sram_blackbox #(
  parameter int unsigned NumWords     = 32'd1024,
  parameter int unsigned DataWidth    = 32'd128,
  parameter int unsigned ByteWidth    = 32'd8,
  parameter int unsigned NumPorts     = 32'd2,
  parameter int unsigned Latency      = 32'd1,
  parameter              SimInit      = "none",
  parameter bit          PrintSimCfg  = 1'b0,
  parameter              ImplKey      = "none",
  parameter              FPGAImplKey  = "auto",
  parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth
) (
  input  logic                                 clk_i,
  input  logic                                 rst_ni,
  input  logic [NumPorts-1:0]                  req_i,
  input  logic [NumPorts-1:0]                  we_i,
  input  logic [NumPorts-1:0][AddrWidth-1:0]   addr_i,
  input  logic [NumPorts-1:0][DataWidth-1:0]   wdata_i,
  input  logic [NumPorts-1:0][BeWidth-1:0]     be_i,
  output logic [NumPorts-1:0][DataWidth-1:0]   rdata_o
);
endmodule

// Generic implementation-I/O wrapper used by Snitch and Spatz.
module tc_sram_impl #(
  parameter int unsigned NumWords     = 32'd1024,
  parameter int unsigned DataWidth    = 32'd128,
  parameter int unsigned ByteWidth    = 32'd8,
  parameter int unsigned NumPorts     = 32'd2,
  parameter int unsigned Latency      = 32'd1,
  parameter              SimInit      = "none",
  parameter bit          PrintSimCfg  = 1'b0,
  parameter              ImplKey      = "none",
  parameter type         impl_in_t    = logic,
  parameter type         impl_out_t   = logic,
  // Synthesis metadata defaults to a deterministic tie-off; overrides remain supported.
  parameter impl_out_t   ImplOutSim   = '0,
  parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth,
  parameter type         addr_t    = logic [AddrWidth-1:0],
  parameter type         data_t    = logic [DataWidth-1:0],
  parameter type         be_t      = logic [BeWidth-1:0]
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  impl_in_t             impl_i,
  output impl_out_t            impl_o,
  input  logic  [NumPorts-1:0] req_i,
  input  logic  [NumPorts-1:0] we_i,
  input  addr_t [NumPorts-1:0] addr_i,
  input  data_t [NumPorts-1:0] wdata_i,
  input  be_t   [NumPorts-1:0] be_i,
  output data_t [NumPorts-1:0] rdata_o
);

  assign impl_o = ImplOutSim;

  tc_sram #(
    .NumWords    (NumWords),
    .DataWidth   (DataWidth),
    .ByteWidth   (ByteWidth),
    .NumPorts    (NumPorts),
    .Latency     (Latency),
    .SimInit     (SimInit),
    .PrintSimCfg (PrintSimCfg),
    .ImplKey     (ImplKey),
    .AddrWidth   (AddrWidth),
    .BeWidth     (BeWidth),
    .addr_t      (addr_t),
    .data_t      (data_t),
    .be_t        (be_t)
  ) i_tc_sram (
    .clk_i,
    .rst_ni,
    .req_i,
    .we_i,
    .addr_i,
    .wdata_i,
    .be_i,
    .rdata_o
  );

endmodule
