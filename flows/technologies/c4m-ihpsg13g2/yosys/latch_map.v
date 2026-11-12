// SPDX-License-Identifier: SHL-0.51

module \$_DLATCH_P_ (
  input  wire E,
  input  wire D,
  output wire Q
);
  nsnrlatch_x1 _TECHMAP_REPLACE_ (.nset(~(E & D)), .nrst(~(E & ~D)), .q(Q), .nq());
endmodule

module \$_DLATCH_N_ (
  input  wire E,
  input  wire D,
  output wire Q
);
  nsnrlatch_x1 _TECHMAP_REPLACE_ (.nset(~(~E & D)), .nrst(~(~E & ~D)), .q(Q), .nq());
endmodule

module \$_SR_NN_ (
  input  wire S,
  input  wire R,
  output wire Q
);
  nsnrlatch_x1 _TECHMAP_REPLACE_ (.nset(S), .nrst(R), .q(Q), .nq());
endmodule
