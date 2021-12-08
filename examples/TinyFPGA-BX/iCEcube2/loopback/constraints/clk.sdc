####---- CreateClock list ----
set BIT_SAMPLES 4
set BIT_PERIOD [expr 1000 / 12]
set CLK_PERIOD [expr $BIT_PERIOD / $BIT_SAMPLES]
set BYTE_PERIOD [expr $BIT_PERIOD * 8]

create_clock  -name {clk} -period [expr 1000 / 16] [get_ports {clk}] 
create_clock  -name {clk_pll} -period $CLK_PERIOD  [get_nets {clk_pll}] 
create_generated_clock  -name {clk_1mhz} -source [get_ports {clk}] [get_nets {clk_1mhz}] -divide_by 16
create_generated_clock  -name {clk_app} -source [get_nets {clk_pll}] [get_nets {clk_div4}] -divide_by 4

set_clock_groups -asynchronous -group {clk} -group {clk_1mhz} -group {clk_app} -group {clk_pll}

set path "u_usb_cdc.u_sie.u_phy_tx"
set gated_cells [remove_from_collection -intersect [all_registers] [get_cells "
    ${path}.tx_state_q*
    ${path}.bit_cnt_q*
    ${path}.data_q*
    ${path}.stuffing_cnt_q*
    ${path}.nrzi_q*
    ${path}.tx_valid_q*
    "]]
#c_print -file mylog.txt $gated_cells
set_multicycle_path -setup $BIT_SAMPLES -from $gated_cells
set_multicycle_path -hold [expr $BIT_SAMPLES - 1] -from $gated_cells

set gated_pins [get_pins "
    ${path}.tx_data_i*
    "]
#c_print -file mylog.txt $gated_pins
set_multicycle_path -setup [expr 7 * $BIT_SAMPLES] -through $gated_pins
set_multicycle_path -hold [expr 7 * $BIT_SAMPLES - 1] -through $gated_pins

set path "u_usb_cdc.u_sie.u_phy_rx"
set gated_cells [remove_from_collection -intersect [all_registers] [get_cells "
    ${path}.nrzi_q*
    ${path}.rx_state_q*
    ${path}.data_q*
    ${path}.stuffing_cnt_q*
    ${path}.rx_valid_rq*
    ${path}.rx_valid_fq*
    ${path}.reset_cnt_q*
    "]]
#c_print -file mylog.txt $gated_cells
set_multicycle_path -setup [expr $BIT_SAMPLES / 2] -from $gated_cells
set_multicycle_path -hold [expr ($BIT_SAMPLES / 2) - 1] -from $gated_cells

set path "u_usb_cdc.u_sie"
set gated_pins [get_pins "
    ${path}.out_ready_o
    ${path}.in_ready_o
    "]
#c_print -file mylog.txt $gated_pins
set_multicycle_path -setup [expr 8 * $BIT_SAMPLES] -through $gated_pins
set_multicycle_path -hold [expr 8 * $BIT_SAMPLES - 1] -through $gated_pins

set gated_cells [remove_from_collection -intersect [all_registers] [get_cells -of_objects [all_fanout -from [get_nets "${path}.clk_gate"] -flat -trace_arcs all]]]
#c_print -file mylog.txt $gated_cells
set_multicycle_path -setup [expr 2 * $BIT_SAMPLES] -from $gated_cells
set_multicycle_path -hold [expr 2 * $BIT_SAMPLES - 1] -from $gated_cells

set gated_cells [remove_from_collection -intersect [all_registers] [get_cells "u_usb_cdc.u_ctrl_endp.*"]]
#c_print -file mylog.txt $gated_cells
set_multicycle_path -setup [expr 8 * $BIT_SAMPLES] -from $gated_cells
set_multicycle_path -hold [expr 8 * $BIT_SAMPLES - 1] -from $gated_cells
set_multicycle_path -setup [expr 8 * $BIT_SAMPLES] -to $gated_cells
set_multicycle_path -hold [expr 8 * $BIT_SAMPLES - 1] -to $gated_cells

set gated_pins [get_pins "
    u_usb_cdc.u_ctrl_endp.out_err_i
    u_usb_cdc.u_ctrl_endp.setup_i
    u_usb_cdc.u_ctrl_endp.in_req_i
    u_usb_cdc.u_ctrl_endp.in_ready_i
    u_usb_cdc.u_sie.in_valid_i
    "]
#c_print -file mylog.txt $gated_pins
set_multicycle_path -setup [expr 8 * $BIT_SAMPLES] -through $gated_pins
set_multicycle_path -hold [expr 8 * $BIT_SAMPLES - 1] -through $gated_pins
