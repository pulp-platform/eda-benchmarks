set clk_name clk
set clk_port_name clk_i
set clk_period 500

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]
create_clock -name clk_sl -period $clk_period [get_ports clk_sl_i]
create_clock -name clk_reg -period $clk_period [get_ports clk_reg_i]
create_clock -name slink_rcv_clk -period 8000 [get_ports slink_rcv_clk_i]
create_generated_clock -name slink_tx_clk -source [get_ports clk_sl_i] \
  -divide_by 8 [get_ports slink_rcv_clk_o]

set_clock_groups -asynchronous \
  -group [get_clocks [list $clk_name clk_sl slink_tx_clk]] \
  -group [get_clocks clk_reg] \
  -group [get_clocks slink_rcv_clk]

set non_clock_inputs [get_ports {
  rst_ni
  rst_sl_ni
  rst_reg_ni
  testmode_i
  axi_in_req_i
  axi_out_rsp_i
  apb_req_i
  slink_i
  isolated_i
}]

set_input_delay 100 -clock clk_sl [get_ports {axi_in_req_i axi_out_rsp_i}]
set_output_delay 100 -clock clk_sl [get_ports {axi_in_rsp_o axi_out_req_o}]

set_input_delay 100 -clock clk_reg [get_ports apb_req_i]
set_output_delay 100 -clock clk_reg [get_ports apb_rsp_o]

set_input_delay 100 -clock $clk_name [get_ports isolated_i]
set_output_delay 100 -clock $clk_name [get_ports {isolate_o clk_ena_o reset_no}]

set_input_delay 100 -clock slink_rcv_clk [get_ports slink_i]
set_output_delay 100 -clock slink_tx_clk [get_ports slink_o]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports testmode_i]
set_false_path -from [get_ports {rst_ni rst_sl_ni rst_reg_ni}]
