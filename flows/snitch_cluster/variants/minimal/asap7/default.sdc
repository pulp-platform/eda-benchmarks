set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set non_clock_inputs [get_ports {
  rst_ni
  debug_req_i
  meip_i
  mtip_i
  msip_i
  mxip_i
  hart_base_id_i
  cluster_base_addr_i
  cluster_base_offset_i
  clk_d2_bypass_i
  sram_cfg_tcdm_i
  sram_cfg_icache_tag_i
  sram_cfg_icache_data_i
  narrow_in_req_i
  narrow_out_resp_i
  wide_out_resp_i
  wide_in_req_i
  x_issue_resp_i
  x_issue_ready_i
  x_register_ready_i
  x_result_i
  x_result_valid_i
  narrow_ext_resp_i
  tcdm_ext_req_i
  dca_req_i
}]

set_input_delay 100 -clock $clk_name [get_ports {
  mxip_i
  narrow_in_req_i
  narrow_out_resp_i
  wide_out_resp_i
  wide_in_req_i
  x_issue_resp_i
  x_issue_ready_i
  x_register_ready_i
  x_result_i
  x_result_valid_i
  narrow_ext_resp_i
  tcdm_ext_req_i
  dca_req_i
}]
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports clk_d2_bypass_i]
set_false_path -from [get_ports {
  rst_ni
  hart_base_id_i
  cluster_base_addr_i
  cluster_base_offset_i
  sram_cfg_tcdm_i
  sram_cfg_icache_tag_i
  sram_cfg_icache_data_i
  debug_req_i
  meip_i
  mtip_i
  msip_i
}]
