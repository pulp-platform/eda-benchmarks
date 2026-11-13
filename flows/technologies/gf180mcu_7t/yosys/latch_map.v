// SPDX-License-Identifier: SHL-0.51

module \$_DLATCH_P_ (
  input  wire E,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latq_1 _TECHMAP_REPLACE_ (.E(E), .D(D), .Q(Q));
endmodule

module \$_DLATCH_N_ (
  input  wire E,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latq_1 _TECHMAP_REPLACE_ (.E(~E), .D(D), .Q(Q));
endmodule

module \$_DLATCH_PN0_ (
  input  wire E,
  input  wire R,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latrnq_1 _TECHMAP_REPLACE_ (.E(E), .D(D), .RN(R), .Q(Q));
endmodule

module \$_DLATCH_PN1_ (
  input  wire E,
  input  wire R,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latsnq_1 _TECHMAP_REPLACE_ (.E(E), .D(D), .SETN(R), .Q(Q));
endmodule

module \$_DLATCHSR_PNN_ (
  input  wire E,
  input  wire S,
  input  wire R,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latrsnq_1 _TECHMAP_REPLACE_ (.E(E), .D(D), .RN(R), .SETN(S | ~R), .Q(Q));
endmodule

module \$_DLATCH_NN0_ (
  input  wire E,
  input  wire R,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latrnq_1 _TECHMAP_REPLACE_ (.E(~E), .D(D), .RN(R), .Q(Q));
endmodule

module \$_DLATCH_NN1_ (
  input  wire E,
  input  wire R,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latsnq_1 _TECHMAP_REPLACE_ (.E(~E), .D(D), .SETN(R), .Q(Q));
endmodule

module \$_DLATCHSR_NNN_ (
  input  wire E,
  input  wire S,
  input  wire R,
  input  wire D,
  output wire Q
);
  gf180mcu_fd_sc_mcu7t5v0__latrsnq_1 _TECHMAP_REPLACE_ (.E(~E), .D(D), .RN(R), .SETN(S | ~R), .Q(Q));
endmodule
