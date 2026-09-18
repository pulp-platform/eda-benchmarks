set clk_name clk
set clk_port_name clk_i
set clk_period 2000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set data_inputs [get_ports -quiet cluster_inputs_i]
if {[sizeof_collection $data_inputs] == 0} {
  set data_inputs [get_ports inputs_i]
}

set non_clock_inputs [get_ports {
  rst_ni
  debug_req_i
  meip_i
  mtip_i
  msip_i
  hart_base_id_i
  cluster_base_addr_i
  cluster_base_offset_i
  clk_d2_bypass_i
  sram_cfg_tcdm_i
  sram_cfg_icache_tag_i
  sram_cfg_icache_data_i
}]
set non_clock_inputs [add_to_collection $non_clock_inputs $data_inputs]

set_input_delay 100 -clock $clk_name $data_inputs
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports clk_d2_bypass_i]
set_false_path -from [get_ports {
  rst_ni
  debug_req_i
  meip_i
  mtip_i
  msip_i
  hart_base_id_i
  cluster_base_addr_i
  cluster_base_offset_i
  sram_cfg_tcdm_i
  sram_cfg_icache_tag_i
  sram_cfg_icache_data_i
}]
