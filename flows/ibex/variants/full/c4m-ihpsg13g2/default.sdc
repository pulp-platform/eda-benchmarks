set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set non_clock_inputs [get_ports {
  rst_ni
  test_en_i
  ram_cfg_icache_tag_i
  ram_cfg_icache_data_i
  hart_id_i
  boot_addr_i
  irq_software_i
  irq_timer_i
  irq_external_i
  irq_fast_i
  irq_nm_i
  scramble_key_valid_i
  scramble_key_i
  scramble_nonce_i
  debug_req_i
  fetch_enable_i
  mcounteren_writable_i
  scan_rst_ni
  inputs_i
}]

set_input_delay 100 -clock $clk_name [get_ports {
  inputs_i
  irq_software_i
  irq_timer_i
  irq_external_i
  irq_fast_i
  irq_nm_i
  debug_req_i
  fetch_enable_i
}]
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports test_en_i]
set_false_path -from [get_ports {
  rst_ni
  ram_cfg_icache_tag_i
  ram_cfg_icache_data_i
  hart_id_i
  boot_addr_i
  scramble_key_valid_i
  scramble_key_i
  scramble_nonce_i
  mcounteren_writable_i
  scan_rst_ni
}]
