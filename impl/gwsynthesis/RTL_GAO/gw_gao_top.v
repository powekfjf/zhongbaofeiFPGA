module gw_gao(
    \theta_out[11] ,
    \theta_out[10] ,
    \theta_out[9] ,
    \theta_out[8] ,
    \theta_out[7] ,
    \theta_out[6] ,
    \theta_out[5] ,
    \theta_out[4] ,
    \theta_out[3] ,
    \theta_out[2] ,
    \theta_out[1] ,
    \theta_out[0] ,
    \theta_r[15] ,
    \theta_r[14] ,
    \theta_r[13] ,
    \theta_r[12] ,
    \theta_r[11] ,
    \theta_r[10] ,
    \theta_r[9] ,
    \theta_r[8] ,
    \theta_r[7] ,
    \theta_r[6] ,
    \theta_r[5] ,
    \theta_r[4] ,
    \theta_r[3] ,
    \theta_r[2] ,
    \theta_r[1] ,
    \theta_r[0] ,
    \theta_out_r[15] ,
    \theta_out_r[14] ,
    \theta_out_r[13] ,
    \theta_out_r[12] ,
    \theta_out_r[11] ,
    \theta_out_r[10] ,
    \theta_out_r[9] ,
    \theta_out_r[8] ,
    \theta_out_r[7] ,
    \theta_out_r[6] ,
    \theta_out_r[5] ,
    \theta_out_r[4] ,
    \theta_out_r[3] ,
    \theta_out_r[2] ,
    \theta_out_r[1] ,
    \theta_out_r[0] ,
    \uart_inst/data_in_reg[15] ,
    \uart_inst/data_in_reg[14] ,
    \uart_inst/data_in_reg[13] ,
    \uart_inst/data_in_reg[12] ,
    \uart_inst/data_in_reg[11] ,
    \uart_inst/data_in_reg[10] ,
    \uart_inst/data_in_reg[9] ,
    \uart_inst/data_in_reg[8] ,
    \uart_inst/data_in_reg[7] ,
    \uart_inst/data_in_reg[6] ,
    \uart_inst/data_in_reg[5] ,
    \uart_inst/data_in_reg[4] ,
    \uart_inst/data_in_reg[3] ,
    \uart_inst/data_in_reg[2] ,
    \uart_inst/data_in_reg[1] ,
    \uart_inst/data_in_reg[0] ,
    \uart_inst/tx_byte_cnt[4] ,
    \uart_inst/tx_byte_cnt[3] ,
    \uart_inst/tx_byte_cnt[2] ,
    \uart_inst/tx_byte_cnt[1] ,
    \uart_inst/tx_byte_cnt[0] ,
    \uart_inst/send_en ,
    \uart_inst/pi_data_r[7] ,
    \uart_inst/pi_data_r[6] ,
    \uart_inst/pi_data_r[5] ,
    \uart_inst/pi_data_r[4] ,
    \uart_inst/pi_data_r[3] ,
    \uart_inst/pi_data_r[2] ,
    \uart_inst/pi_data_r[1] ,
    \uart_inst/pi_data_r[0] ,
    \uart_inst/u_wr_pos ,
    \uart_inst/u_wr_valid ,
    \uart_inst/cnt_delay[31] ,
    \uart_inst/cnt_delay[30] ,
    \uart_inst/cnt_delay[29] ,
    \uart_inst/cnt_delay[28] ,
    \uart_inst/cnt_delay[27] ,
    \uart_inst/cnt_delay[26] ,
    \uart_inst/cnt_delay[25] ,
    \uart_inst/cnt_delay[24] ,
    \uart_inst/cnt_delay[23] ,
    \uart_inst/cnt_delay[22] ,
    \uart_inst/cnt_delay[21] ,
    \uart_inst/cnt_delay[20] ,
    \uart_inst/cnt_delay[19] ,
    \uart_inst/cnt_delay[18] ,
    \uart_inst/cnt_delay[17] ,
    \uart_inst/cnt_delay[16] ,
    \uart_inst/cnt_delay[15] ,
    \uart_inst/cnt_delay[14] ,
    \uart_inst/cnt_delay[13] ,
    \uart_inst/cnt_delay[12] ,
    \uart_inst/cnt_delay[11] ,
    \uart_inst/cnt_delay[10] ,
    \uart_inst/cnt_delay[9] ,
    \uart_inst/cnt_delay[8] ,
    \uart_inst/cnt_delay[7] ,
    \uart_inst/cnt_delay[6] ,
    \uart_inst/cnt_delay[5] ,
    \uart_inst/cnt_delay[4] ,
    \uart_inst/cnt_delay[3] ,
    \uart_inst/cnt_delay[2] ,
    \uart_inst/cnt_delay[1] ,
    \uart_inst/cnt_delay[0] ,
    clk_50m,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \theta_out[11] ;
input \theta_out[10] ;
input \theta_out[9] ;
input \theta_out[8] ;
input \theta_out[7] ;
input \theta_out[6] ;
input \theta_out[5] ;
input \theta_out[4] ;
input \theta_out[3] ;
input \theta_out[2] ;
input \theta_out[1] ;
input \theta_out[0] ;
input \theta_r[15] ;
input \theta_r[14] ;
input \theta_r[13] ;
input \theta_r[12] ;
input \theta_r[11] ;
input \theta_r[10] ;
input \theta_r[9] ;
input \theta_r[8] ;
input \theta_r[7] ;
input \theta_r[6] ;
input \theta_r[5] ;
input \theta_r[4] ;
input \theta_r[3] ;
input \theta_r[2] ;
input \theta_r[1] ;
input \theta_r[0] ;
input \theta_out_r[15] ;
input \theta_out_r[14] ;
input \theta_out_r[13] ;
input \theta_out_r[12] ;
input \theta_out_r[11] ;
input \theta_out_r[10] ;
input \theta_out_r[9] ;
input \theta_out_r[8] ;
input \theta_out_r[7] ;
input \theta_out_r[6] ;
input \theta_out_r[5] ;
input \theta_out_r[4] ;
input \theta_out_r[3] ;
input \theta_out_r[2] ;
input \theta_out_r[1] ;
input \theta_out_r[0] ;
input \uart_inst/data_in_reg[15] ;
input \uart_inst/data_in_reg[14] ;
input \uart_inst/data_in_reg[13] ;
input \uart_inst/data_in_reg[12] ;
input \uart_inst/data_in_reg[11] ;
input \uart_inst/data_in_reg[10] ;
input \uart_inst/data_in_reg[9] ;
input \uart_inst/data_in_reg[8] ;
input \uart_inst/data_in_reg[7] ;
input \uart_inst/data_in_reg[6] ;
input \uart_inst/data_in_reg[5] ;
input \uart_inst/data_in_reg[4] ;
input \uart_inst/data_in_reg[3] ;
input \uart_inst/data_in_reg[2] ;
input \uart_inst/data_in_reg[1] ;
input \uart_inst/data_in_reg[0] ;
input \uart_inst/tx_byte_cnt[4] ;
input \uart_inst/tx_byte_cnt[3] ;
input \uart_inst/tx_byte_cnt[2] ;
input \uart_inst/tx_byte_cnt[1] ;
input \uart_inst/tx_byte_cnt[0] ;
input \uart_inst/send_en ;
input \uart_inst/pi_data_r[7] ;
input \uart_inst/pi_data_r[6] ;
input \uart_inst/pi_data_r[5] ;
input \uart_inst/pi_data_r[4] ;
input \uart_inst/pi_data_r[3] ;
input \uart_inst/pi_data_r[2] ;
input \uart_inst/pi_data_r[1] ;
input \uart_inst/pi_data_r[0] ;
input \uart_inst/u_wr_pos ;
input \uart_inst/u_wr_valid ;
input \uart_inst/cnt_delay[31] ;
input \uart_inst/cnt_delay[30] ;
input \uart_inst/cnt_delay[29] ;
input \uart_inst/cnt_delay[28] ;
input \uart_inst/cnt_delay[27] ;
input \uart_inst/cnt_delay[26] ;
input \uart_inst/cnt_delay[25] ;
input \uart_inst/cnt_delay[24] ;
input \uart_inst/cnt_delay[23] ;
input \uart_inst/cnt_delay[22] ;
input \uart_inst/cnt_delay[21] ;
input \uart_inst/cnt_delay[20] ;
input \uart_inst/cnt_delay[19] ;
input \uart_inst/cnt_delay[18] ;
input \uart_inst/cnt_delay[17] ;
input \uart_inst/cnt_delay[16] ;
input \uart_inst/cnt_delay[15] ;
input \uart_inst/cnt_delay[14] ;
input \uart_inst/cnt_delay[13] ;
input \uart_inst/cnt_delay[12] ;
input \uart_inst/cnt_delay[11] ;
input \uart_inst/cnt_delay[10] ;
input \uart_inst/cnt_delay[9] ;
input \uart_inst/cnt_delay[8] ;
input \uart_inst/cnt_delay[7] ;
input \uart_inst/cnt_delay[6] ;
input \uart_inst/cnt_delay[5] ;
input \uart_inst/cnt_delay[4] ;
input \uart_inst/cnt_delay[3] ;
input \uart_inst/cnt_delay[2] ;
input \uart_inst/cnt_delay[1] ;
input \uart_inst/cnt_delay[0] ;
input clk_50m;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \theta_out[11] ;
wire \theta_out[10] ;
wire \theta_out[9] ;
wire \theta_out[8] ;
wire \theta_out[7] ;
wire \theta_out[6] ;
wire \theta_out[5] ;
wire \theta_out[4] ;
wire \theta_out[3] ;
wire \theta_out[2] ;
wire \theta_out[1] ;
wire \theta_out[0] ;
wire \theta_r[15] ;
wire \theta_r[14] ;
wire \theta_r[13] ;
wire \theta_r[12] ;
wire \theta_r[11] ;
wire \theta_r[10] ;
wire \theta_r[9] ;
wire \theta_r[8] ;
wire \theta_r[7] ;
wire \theta_r[6] ;
wire \theta_r[5] ;
wire \theta_r[4] ;
wire \theta_r[3] ;
wire \theta_r[2] ;
wire \theta_r[1] ;
wire \theta_r[0] ;
wire \theta_out_r[15] ;
wire \theta_out_r[14] ;
wire \theta_out_r[13] ;
wire \theta_out_r[12] ;
wire \theta_out_r[11] ;
wire \theta_out_r[10] ;
wire \theta_out_r[9] ;
wire \theta_out_r[8] ;
wire \theta_out_r[7] ;
wire \theta_out_r[6] ;
wire \theta_out_r[5] ;
wire \theta_out_r[4] ;
wire \theta_out_r[3] ;
wire \theta_out_r[2] ;
wire \theta_out_r[1] ;
wire \theta_out_r[0] ;
wire \uart_inst/data_in_reg[15] ;
wire \uart_inst/data_in_reg[14] ;
wire \uart_inst/data_in_reg[13] ;
wire \uart_inst/data_in_reg[12] ;
wire \uart_inst/data_in_reg[11] ;
wire \uart_inst/data_in_reg[10] ;
wire \uart_inst/data_in_reg[9] ;
wire \uart_inst/data_in_reg[8] ;
wire \uart_inst/data_in_reg[7] ;
wire \uart_inst/data_in_reg[6] ;
wire \uart_inst/data_in_reg[5] ;
wire \uart_inst/data_in_reg[4] ;
wire \uart_inst/data_in_reg[3] ;
wire \uart_inst/data_in_reg[2] ;
wire \uart_inst/data_in_reg[1] ;
wire \uart_inst/data_in_reg[0] ;
wire \uart_inst/tx_byte_cnt[4] ;
wire \uart_inst/tx_byte_cnt[3] ;
wire \uart_inst/tx_byte_cnt[2] ;
wire \uart_inst/tx_byte_cnt[1] ;
wire \uart_inst/tx_byte_cnt[0] ;
wire \uart_inst/send_en ;
wire \uart_inst/pi_data_r[7] ;
wire \uart_inst/pi_data_r[6] ;
wire \uart_inst/pi_data_r[5] ;
wire \uart_inst/pi_data_r[4] ;
wire \uart_inst/pi_data_r[3] ;
wire \uart_inst/pi_data_r[2] ;
wire \uart_inst/pi_data_r[1] ;
wire \uart_inst/pi_data_r[0] ;
wire \uart_inst/u_wr_pos ;
wire \uart_inst/u_wr_valid ;
wire \uart_inst/cnt_delay[31] ;
wire \uart_inst/cnt_delay[30] ;
wire \uart_inst/cnt_delay[29] ;
wire \uart_inst/cnt_delay[28] ;
wire \uart_inst/cnt_delay[27] ;
wire \uart_inst/cnt_delay[26] ;
wire \uart_inst/cnt_delay[25] ;
wire \uart_inst/cnt_delay[24] ;
wire \uart_inst/cnt_delay[23] ;
wire \uart_inst/cnt_delay[22] ;
wire \uart_inst/cnt_delay[21] ;
wire \uart_inst/cnt_delay[20] ;
wire \uart_inst/cnt_delay[19] ;
wire \uart_inst/cnt_delay[18] ;
wire \uart_inst/cnt_delay[17] ;
wire \uart_inst/cnt_delay[16] ;
wire \uart_inst/cnt_delay[15] ;
wire \uart_inst/cnt_delay[14] ;
wire \uart_inst/cnt_delay[13] ;
wire \uart_inst/cnt_delay[12] ;
wire \uart_inst/cnt_delay[11] ;
wire \uart_inst/cnt_delay[10] ;
wire \uart_inst/cnt_delay[9] ;
wire \uart_inst/cnt_delay[8] ;
wire \uart_inst/cnt_delay[7] ;
wire \uart_inst/cnt_delay[6] ;
wire \uart_inst/cnt_delay[5] ;
wire \uart_inst/cnt_delay[4] ;
wire \uart_inst/cnt_delay[3] ;
wire \uart_inst/cnt_delay[2] ;
wire \uart_inst/cnt_delay[1] ;
wire \uart_inst/cnt_delay[0] ;
wire clk_50m;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i({\theta_out[11] ,\theta_out[10] ,\theta_out[9] ,\theta_out[8] ,\theta_out[7] ,\theta_out[6] ,\theta_out[5] ,\theta_out[4] ,\theta_out[3] ,\theta_out[2] ,\theta_out[1] ,\theta_out[0] }),
    .trig1_i(\uart_inst/send_en ),
    .trig2_i({\uart_inst/tx_byte_cnt[4] ,\uart_inst/tx_byte_cnt[3] ,\uart_inst/tx_byte_cnt[2] ,\uart_inst/tx_byte_cnt[1] ,\uart_inst/tx_byte_cnt[0] }),
    .trig3_i(\uart_inst/u_wr_pos ),
    .trig4_i({\uart_inst/cnt_delay[31] ,\uart_inst/cnt_delay[30] ,\uart_inst/cnt_delay[29] ,\uart_inst/cnt_delay[28] ,\uart_inst/cnt_delay[27] ,\uart_inst/cnt_delay[26] ,\uart_inst/cnt_delay[25] ,\uart_inst/cnt_delay[24] ,\uart_inst/cnt_delay[23] ,\uart_inst/cnt_delay[22] ,\uart_inst/cnt_delay[21] ,\uart_inst/cnt_delay[20] ,\uart_inst/cnt_delay[19] ,\uart_inst/cnt_delay[18] ,\uart_inst/cnt_delay[17] ,\uart_inst/cnt_delay[16] ,\uart_inst/cnt_delay[15] ,\uart_inst/cnt_delay[14] ,\uart_inst/cnt_delay[13] ,\uart_inst/cnt_delay[12] ,\uart_inst/cnt_delay[11] ,\uart_inst/cnt_delay[10] ,\uart_inst/cnt_delay[9] ,\uart_inst/cnt_delay[8] ,\uart_inst/cnt_delay[7] ,\uart_inst/cnt_delay[6] ,\uart_inst/cnt_delay[5] ,\uart_inst/cnt_delay[4] ,\uart_inst/cnt_delay[3] ,\uart_inst/cnt_delay[2] ,\uart_inst/cnt_delay[1] ,\uart_inst/cnt_delay[0] }),
    .data_i({\theta_out[11] ,\theta_out[10] ,\theta_out[9] ,\theta_out[8] ,\theta_out[7] ,\theta_out[6] ,\theta_out[5] ,\theta_out[4] ,\theta_out[3] ,\theta_out[2] ,\theta_out[1] ,\theta_out[0] ,\theta_r[15] ,\theta_r[14] ,\theta_r[13] ,\theta_r[12] ,\theta_r[11] ,\theta_r[10] ,\theta_r[9] ,\theta_r[8] ,\theta_r[7] ,\theta_r[6] ,\theta_r[5] ,\theta_r[4] ,\theta_r[3] ,\theta_r[2] ,\theta_r[1] ,\theta_r[0] ,\theta_out_r[15] ,\theta_out_r[14] ,\theta_out_r[13] ,\theta_out_r[12] ,\theta_out_r[11] ,\theta_out_r[10] ,\theta_out_r[9] ,\theta_out_r[8] ,\theta_out_r[7] ,\theta_out_r[6] ,\theta_out_r[5] ,\theta_out_r[4] ,\theta_out_r[3] ,\theta_out_r[2] ,\theta_out_r[1] ,\theta_out_r[0] ,\uart_inst/data_in_reg[15] ,\uart_inst/data_in_reg[14] ,\uart_inst/data_in_reg[13] ,\uart_inst/data_in_reg[12] ,\uart_inst/data_in_reg[11] ,\uart_inst/data_in_reg[10] ,\uart_inst/data_in_reg[9] ,\uart_inst/data_in_reg[8] ,\uart_inst/data_in_reg[7] ,\uart_inst/data_in_reg[6] ,\uart_inst/data_in_reg[5] ,\uart_inst/data_in_reg[4] ,\uart_inst/data_in_reg[3] ,\uart_inst/data_in_reg[2] ,\uart_inst/data_in_reg[1] ,\uart_inst/data_in_reg[0] ,\uart_inst/tx_byte_cnt[4] ,\uart_inst/tx_byte_cnt[3] ,\uart_inst/tx_byte_cnt[2] ,\uart_inst/tx_byte_cnt[1] ,\uart_inst/tx_byte_cnt[0] ,\uart_inst/send_en ,\uart_inst/pi_data_r[7] ,\uart_inst/pi_data_r[6] ,\uart_inst/pi_data_r[5] ,\uart_inst/pi_data_r[4] ,\uart_inst/pi_data_r[3] ,\uart_inst/pi_data_r[2] ,\uart_inst/pi_data_r[1] ,\uart_inst/pi_data_r[0] ,\uart_inst/u_wr_pos ,\uart_inst/u_wr_valid }),
    .clk_i(clk_50m)
);

endmodule
