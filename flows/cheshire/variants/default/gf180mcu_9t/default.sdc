set clk_name clk
set clk_port_name clk_i
set clk_period 1000

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

create_clock -name jtag_tck -period 50000 [get_ports jtag_tck_i]
create_clock -name usb_clk -period 20833.333 [get_ports usb_clk_i]
create_clock -name slink_rcv_clk -period 8000 [get_ports slink_rcv_clk_i]
create_generated_clock -name slink_tx_clk -source [get_ports $clk_port_name] \
  -divide_by 8 [get_ports slink_rcv_clk_o]
create_generated_clock -name spih_sck_clk -source [get_ports $clk_port_name] \
  -divide_by 2 [get_ports spih_sck_o]

set_clock_groups -asynchronous \
  -group [get_clocks [list $clk_name slink_tx_clk spih_sck_clk]] \
  -group [get_clocks jtag_tck] \
  -group [get_clocks usb_clk] \
  -group [get_clocks slink_rcv_clk]

set non_clock_inputs [get_ports {
  rst_ni
  test_mode_i
  boot_mode_i
  rtc_i
  axi_llc_mst_rsp_i
  axi_ext_mst_req_i
  axi_ext_slv_rsp_i
  reg_ext_slv_rsp_i
  intr_ext_i
  dbg_ext_unavail_i
  jtag_trst_ni
  jtag_tms_i
  jtag_tdi_i
  uart_rx_i
  uart_cts_ni
  uart_dsr_ni
  uart_dcd_ni
  uart_rin_ni
  i2c_sda_i
  i2c_scl_i
  spih_sd_i
  gpio_i
  slink_i
  usb_rst_ni
  usb_dm_i
  usb_dp_i
}]

set main_clock_inputs [get_ports {
  axi_llc_mst_rsp_i
  axi_ext_mst_req_i
  axi_ext_slv_rsp_i
  reg_ext_slv_rsp_i
}]

set main_clock_outputs [get_ports {
  axi_llc_mst_req_o
  axi_ext_mst_rsp_o
  axi_ext_slv_req_o
  reg_ext_slv_req_o
  dbg_active_o
  vga_hsync_o
  vga_vsync_o
  vga_red_o
  vga_green_o
  vga_blue_o
}]

set_input_delay 100 -clock $clk_name $main_clock_inputs
set_output_delay 100 -clock $clk_name $main_clock_outputs

set_input_delay 100 -clock jtag_tck [get_ports {jtag_tms_i jtag_tdi_i}]
set_output_delay 100 -clock jtag_tck [get_ports {jtag_tdo_o jtag_tdo_oe_o}]

set_input_delay 100 -clock usb_clk [get_ports {usb_dm_i usb_dp_i}]
set_output_delay 100 -clock usb_clk \
  [get_ports {usb_dm_o usb_dm_oe_o usb_dp_o usb_dp_oe_o}]

set_input_delay 100 -clock slink_rcv_clk [get_ports slink_i]
set_output_delay 100 -clock slink_tx_clk [get_ports slink_o]

set_input_delay 100 -clock spih_sck_clk [get_ports spih_sd_i]
set_output_delay 100 -clock spih_sck_clk \
  [get_ports {spih_sck_en_o spih_csb_o spih_csb_en_o spih_sd_o spih_sd_en_o}]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $non_clock_inputs
set_load 1.0 [all_outputs]

set_case_analysis 0 [get_ports test_mode_i]
set_false_path -from [get_ports {
  rst_ni
  jtag_trst_ni
  usb_rst_ni
  boot_mode_i
  rtc_i
  intr_ext_i
  dbg_ext_unavail_i
  uart_rx_i
  uart_cts_ni
  uart_dsr_ni
  uart_dcd_ni
  uart_rin_ni
  i2c_sda_i
  i2c_scl_i
  gpio_i
}]

set_false_path -to [get_ports {
  intr_ext_o
  xeip_ext_o
  mtip_ext_o
  msip_ext_o
  dbg_ext_req_o
  uart_tx_o
  uart_rts_no
  uart_dtr_no
  i2c_sda_o
  i2c_sda_en_o
  i2c_scl_o
  i2c_scl_en_o
  gpio_o
  gpio_en_o
}]
