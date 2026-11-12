set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set non_clock_inputs [get_ports {
  rst_ni
  pulp_clock_en_i
  scan_cg_en_i
  boot_addr_i
  mtvec_addr_i
  dm_halt_addr_i
  hart_id_i
  dm_exception_addr_i
  instr_gnt_i
  instr_rvalid_i
  instr_rdata_i
  data_gnt_i
  data_rvalid_i
  data_rdata_i
  apu_gnt_i
  apu_rvalid_i
  apu_result_i
  apu_flags_i
  irq_i
  debug_req_i
  fetch_enable_i
}]

set_input_delay 100 -clock $clk_name [get_ports {
  instr_gnt_i
  instr_rvalid_i
  instr_rdata_i
  data_gnt_i
  data_rvalid_i
  data_rdata_i
  apu_gnt_i
  apu_rvalid_i
  apu_result_i
  apu_flags_i
  irq_i
  debug_req_i
  fetch_enable_i
}]
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports {pulp_clock_en_i scan_cg_en_i}]
set_false_path -from [get_ports {
  rst_ni
  boot_addr_i
  mtvec_addr_i
  dm_halt_addr_i
  hart_id_i
  dm_exception_addr_i
}]
