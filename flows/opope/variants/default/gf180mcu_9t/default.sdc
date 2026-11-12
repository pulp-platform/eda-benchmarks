set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set non_clock_inputs [get_ports {
  rst_ni
  test_mode_i
  tcdm_gnt_i
  tcdm_r_data_i
  tcdm_r_valid_i
  tcdm_r_opc_i
  tcdm_r_user_i
  tcdm_r_ecc_i
  periph_req_i
  periph_add_i
  periph_wen_i
  periph_be_i
  periph_data_i
  periph_id_i
}]

set_input_delay 100 -clock $clk_name [get_ports {
  tcdm_gnt_i
  tcdm_r_data_i
  tcdm_r_valid_i
  tcdm_r_opc_i
  tcdm_r_user_i
  tcdm_r_ecc_i
  periph_req_i
  periph_add_i
  periph_wen_i
  periph_be_i
  periph_data_i
  periph_id_i
}]
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports test_mode_i]
set_false_path -from [get_ports {rst_ni}]
