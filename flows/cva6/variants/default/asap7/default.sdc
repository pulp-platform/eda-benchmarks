set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set non_clock_inputs [get_ports {
  rst_ni
  boot_addr_i
  hart_id_i
  irq_i
  ipi_i
  time_irq_i
  debug_req_i
  clic_irq_valid_i
  clic_irq_id_i
  clic_irq_level_i
  clic_irq_priv_i
  clic_irq_v_i
  clic_irq_vsid_i
  clic_irq_shv_i
  clic_kill_req_i
  cvxif_resp_i
  noc_resp_i
}]

set_input_delay 100 -clock $clk_name [get_ports {
  clic_irq_valid_i
  clic_irq_id_i
  clic_irq_level_i
  clic_irq_priv_i
  clic_irq_v_i
  clic_irq_vsid_i
  clic_irq_shv_i
  clic_kill_req_i
  cvxif_resp_i
  noc_resp_i
}]
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_false_path -from [get_ports {
  rst_ni
  boot_addr_i
  hart_id_i
  irq_i
  ipi_i
  time_irq_i
  debug_req_i
}]
set_false_path -to [get_ports rvfi_probes_o]
