set clk_name virtual_clk
set clk_period 1500

create_clock -name $clk_name -period $clk_period

set data_inputs [get_ports {
  operands_i
  is_boxed_i
  rnd_mode_i
  op_i
  op_mod_i
  tag_i
  mask_i
  aux_i
  in_valid_i
  flush_i
  out_ready_i
}]

set_input_delay 100 -clock $clk_name $data_inputs
set_output_delay 100 -clock $clk_name [all_outputs]

set_driving_cell -lib_cell INVx1_ASAP7_75t_R -pin Y $data_inputs
set_load 1.0 [all_outputs]

set_false_path -from [get_ports {clk_i rst_ni}]
