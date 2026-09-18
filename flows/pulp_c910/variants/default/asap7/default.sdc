set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

create_clock -name rtc_clk -period 30517578.125 [get_ports rtc_i]
create_clock -name jtag_tck -period 50000 [get_ports jtag_tck_i]

set_clock_groups -asynchronous \
  -group [get_clocks $clk_name] \
  -group [get_clocks rtc_clk] \
  -group [get_clocks jtag_tck]

set non_clock_inputs [get_ports {
  rst_ni
  ipi_i
  time_irq_i
  plic_hartx_mint_req_i
  plic_hartx_sint_req_i
  debug_req_i
  ext_int_i
  jtag_tdi_i
  jtag_tms_i
  jtag_trst_ni
  axi_rsp_i
}]

set_input_delay 100 -clock $clk_name [get_ports {
  ipi_i
  time_irq_i
  plic_hartx_mint_req_i
  plic_hartx_sint_req_i
  ext_int_i
  axi_rsp_i
}]
set_output_delay 100 -clock $clk_name [get_ports axi_req_o]

set_input_delay 100 -clock jtag_tck [get_ports {jtag_tdi_i jtag_tms_i}]
set_output_delay 100 -clock jtag_tck [get_ports {jtag_tdo_o jtag_tdo_en_o}]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_false_path -from [get_ports {rst_ni jtag_trst_ni debug_req_i}]
