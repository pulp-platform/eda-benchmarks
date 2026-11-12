set clk_name clk
set clk_port_name clk_i
set clk_period 500

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]
create_generated_clock -name spi_clk -source [get_ports $clk_port_name] \
  -divide_by 2 [get_ports cio_sck_o]

set non_clock_inputs [get_ports {
  rst_ni
  reg_req_i
  cio_sd_i
}]

set main_clock_inputs [get_ports reg_req_i]
set main_clock_outputs [get_ports {
  reg_rsp_o
  intr_error_o
  intr_spi_event_o
}]

set_input_delay 100 -clock $clk_name $main_clock_inputs
set_output_delay 100 -clock $clk_name $main_clock_outputs

set_input_delay 100 -clock spi_clk [get_ports cio_sd_i]
set_output_delay 100 -clock spi_clk \
  [get_ports {cio_sck_en_o cio_csb_o cio_csb_en_o cio_sd_o cio_sd_en_o}]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_false_path -from [get_ports {rst_ni}]
