set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set non_clock_inputs [get_ports {
  rst_ni
  scan_enable_i
  scan_data_i
  acc_req_i
  axi_resp_i
}]

set_input_delay 100 -clock $clk_name [get_ports {acc_req_i axi_resp_i}]
set_output_delay 100 -clock $clk_name [get_ports {acc_resp_o axi_req_o}]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports scan_enable_i]
set_false_path -from [get_ports scan_data_i]
set_false_path -to [get_ports scan_data_o]
set_false_path -from [get_ports {rst_ni}]
