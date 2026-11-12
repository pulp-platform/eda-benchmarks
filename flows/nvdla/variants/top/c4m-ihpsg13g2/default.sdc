set clk_name clk
set clk_port_name dla_core_clk
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

create_clock -name dla_csb_clk -period $clk_period [get_ports dla_csb_clk]

set_clock_groups -asynchronous \
  -group [get_clocks $clk_name] \
  -group [get_clocks dla_csb_clk]

set non_clock_inputs [get_ports {
  dla_reset_rstn
  direct_reset_
  nvdla_core2dbb_aw_awready
  nvdla_core2dbb_w_wready
  nvdla_core2dbb_ar_arready
  nvdla_core2dbb_b_bvalid
  nvdla_core2dbb_b_bid
  nvdla_core2dbb_r_rvalid
  nvdla_core2dbb_r_rid
  nvdla_core2dbb_r_rlast
  nvdla_core2dbb_r_rdata
  nvdla_core2cvsram_aw_awready
  nvdla_core2cvsram_w_wready
  nvdla_core2cvsram_b_bvalid
  nvdla_core2cvsram_b_bid
  nvdla_core2cvsram_ar_arready
  nvdla_core2cvsram_r_rvalid
  nvdla_core2cvsram_r_rid
  nvdla_core2cvsram_r_rlast
  nvdla_core2cvsram_r_rdata
  nvdla_pwrbus_ram_c_pd
  nvdla_pwrbus_ram_ma_pd
  nvdla_pwrbus_ram_mb_pd
  nvdla_pwrbus_ram_p_pd
  nvdla_pwrbus_ram_o_pd
  nvdla_pwrbus_ram_a_pd
}]

set_input_delay 100 -clock $clk_name [get_ports {
  nvdla_core2dbb_aw_awready
  nvdla_core2dbb_w_wready
  nvdla_core2dbb_ar_arready
  nvdla_core2dbb_b_bvalid
  nvdla_core2dbb_b_bid
  nvdla_core2dbb_r_rvalid
  nvdla_core2dbb_r_rid
  nvdla_core2dbb_r_rlast
  nvdla_core2dbb_r_rdata
  nvdla_core2cvsram_aw_awready
  nvdla_core2cvsram_w_wready
  nvdla_core2cvsram_b_bvalid
  nvdla_core2cvsram_b_bid
  nvdla_core2cvsram_ar_arready
  nvdla_core2cvsram_r_rvalid
  nvdla_core2cvsram_r_rid
  nvdla_core2cvsram_r_rlast
  nvdla_core2cvsram_r_rdata
}]
set_output_delay 100 -clock $clk_name [get_ports {
  nvdla_core2dbb_aw_awvalid
  nvdla_core2dbb_aw_awid
  nvdla_core2dbb_aw_awlen
  nvdla_core2dbb_aw_awaddr
  nvdla_core2dbb_w_wvalid
  nvdla_core2dbb_w_wdata
  nvdla_core2dbb_w_wstrb
  nvdla_core2dbb_w_wlast
  nvdla_core2dbb_ar_arvalid
  nvdla_core2dbb_ar_arid
  nvdla_core2dbb_ar_arlen
  nvdla_core2dbb_ar_araddr
  nvdla_core2dbb_b_bready
  nvdla_core2dbb_r_rready
  nvdla_core2cvsram_aw_awvalid
  nvdla_core2cvsram_aw_awid
  nvdla_core2cvsram_aw_awlen
  nvdla_core2cvsram_aw_awaddr
  nvdla_core2cvsram_w_wvalid
  nvdla_core2cvsram_w_wdata
  nvdla_core2cvsram_w_wstrb
  nvdla_core2cvsram_w_wlast
  nvdla_core2cvsram_b_bready
  nvdla_core2cvsram_ar_arvalid
  nvdla_core2cvsram_ar_arid
  nvdla_core2cvsram_ar_arlen
  nvdla_core2cvsram_ar_araddr
  nvdla_core2cvsram_r_rready
  dla_intr
}]

set_input_delay 100 -clock dla_csb_clk [get_ports {
  csb2nvdla_valid
  csb2nvdla_addr
  csb2nvdla_wdat
  csb2nvdla_write
  csb2nvdla_nposted
}]
set_output_delay 100 -clock dla_csb_clk [get_ports {
  csb2nvdla_ready
  nvdla2csb_valid
  nvdla2csb_data
  nvdla2csb_wr_complete
}]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y [get_ports {
  global_clk_ovr_on
  tmc2slcg_disable_clock_gating
  test_mode
  csb2nvdla_valid
  csb2nvdla_addr
  csb2nvdla_wdat
  csb2nvdla_write
  csb2nvdla_nposted
}]
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports {
  global_clk_ovr_on
  tmc2slcg_disable_clock_gating
  test_mode
  nvdla_pwrbus_ram_c_pd
  nvdla_pwrbus_ram_ma_pd
  nvdla_pwrbus_ram_mb_pd
  nvdla_pwrbus_ram_p_pd
  nvdla_pwrbus_ram_o_pd
  nvdla_pwrbus_ram_a_pd
}]
set_false_path -from [get_ports {dla_reset_rstn direct_reset_}]
