// SPDX-License-Identifier: SHL-0.51

module \$_DLATCH_P_ (
  input  wire E,
  input  wire D,
  output wire Q
);
  DHLx1_ASAP7_75t_R i_latch (.CLK(E), .D(D), .Q(Q));
endmodule

module \$_DLATCH_N_ (
  input  wire E,
  input  wire D,
  output wire Q
);
  DLLx1_ASAP7_75t_R i_latch (.CLK(E), .D(D), .Q(Q));
endmodule
