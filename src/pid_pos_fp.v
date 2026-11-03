// 位置环 PID 浮点版（实验代码，接口与整数版一致，可直接替换）
// 资源开销较大，未仿真验证；需要时把 fp_mul / fp_add 换成厂商浮点 IP

// 浮点乘法（正常数范围）
module fp_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);
    wire        sa = a[31],  sb = b[31];
    wire [7:0]  ea = a[30:23], eb = b[30:23];
    wire [22:0] ma = a[22:0],  mb = b[22:0];
    wire [23:0] m1 = {1'b1, ma};
    wire [23:0] m2 = {1'b1, mb};
    wire [47:0] mprod = m1 * m2;                 // 24×24 → 48位

    wire zero_a = (ea == 8'd0) && (ma == 23'd0);
    wire zero_b = (eb == 8'd0) && (mb == 23'd0);
    wire mul_zero = zero_a || zero_b;

    wire [23:0] mant_norm = mprod[47] ? mprod[47:24] : mprod[46:23];
    wire signed [8:0] e_raw = $signed({1'b0, ea}) + $signed({1'b0, eb}) - 9'sd127;
    wire signed [8:0] e_fin  = e_raw + (mprod[47] ? 9'sd1 : 9'sd0);

    assign result = mul_zero          ? 32'd0                // 0×x = 0
                  : (e_fin >= 9'd255) ? {sa^sb, 8'hFF, 23'd0} // 溢出→±inf（简化）
                  : (e_fin <= 9'd0)   ? 32'd0                 // 下溢→0（简化）
                  : {sa^sb, e_fin[7:0], mant_norm[22:0]};
endmodule

// 浮点加法（正常数范围）
module fp_add (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);
    wire        sa = a[31],  sb = b[31];
    wire [7:0]  ea = a[30:23], eb = b[30:23];
    wire [22:0] ma = a[22:0],  mb = b[22:0];
    wire a_zero = (ea == 8'd0) && (ma == 23'd0);
    wire b_zero = (eb == 8'd0) && (mb == 23'd0);
    wire [23:0] m1 = {1'b1, ma};
    wire [23:0] m2 = {1'b1, mb};

    // 按指数/尾数确定大者（幅值）
    wire a_gt = (ea > eb) || ((ea == eb) && (ma >= mb));
    wire [7:0]  e_big  = a_gt ? ea : eb;
    wire [23:0] m_big  = a_gt ? m1  : m2;
    wire [23:0] m_sml  = a_gt ? m2  : m1;
    wire        s_big  = a_gt ? sa  : sb;
    wire        same_sign = (sa == sb);
    wire [7:0]  exp_diff = (ea > eb) ? (ea - eb) : (eb - ea);
    wire [23:0] m_shift = (exp_diff >= 8'd24) ? 24'd0 : (m_sml >> exp_diff);

    // 同号相加（25位），异号大减小（非负）
    wire [24:0] sum_m = same_sign ? ({1'b0, m_big} + {1'b0, m_shift})
                                  : ({1'b0, m_big} - {1'b0, m_shift});

    wire [4:0]  lz     = clz_n(sum_m, 5'd24);   // 前导零计数
    wire [24:0] norm_m = sum_m << lz;
    wire signed [8:0] e_fin = $signed({1'b0, e_big}) - $signed({1'b0, lz}) + 9'sd1;
    wire sum_zero = (sum_m == 25'd0);
    wire op_zero  = a_zero || b_zero;
    wire [31:0] zero_result = a_zero ? b : a;   // 0+x = x

    assign result = op_zero  ? zero_result
                  : sum_zero ? 32'd0
                  : (e_fin >= 9'd255) ? {s_big, 8'hFF, 23'd0}
                  : (e_fin <= 9'd0)   ? 32'd0
                  : {s_big, e_fin[7:0], norm_m[23:1]};

    // 前导零计数：从最高有效位往下数连续0
    function [4:0] clz_n;
        input [31:0] x;
        input [4:0]  w;
        integer k;
        reg [4:0] lz;
        begin
            lz = 5'd0;
            for (k = 0; k <= 31; k = k + 1) begin
                if (lz == k[4:0]) begin
                    if (k[4:0] <= w) begin
                        if (x[w - k[4:0]] == 1'b0)
                            lz = lz + 1'b1;
                    end
                end
            end
            clz_n = lz;
        end
    endfunction
endmodule

// 16 位有符号整数 → 单精度浮点
module i2f16 (
    input  wire signed [15:0] i,
    output wire [31:0] result
);
    wire [16:0] mag = i[15] ? (~i + 1'b1) : {1'b0, i};
    wire [4:0]  lz  = clz_n({15'd0, mag}, 5'd16);
    wire [4:0]  msb = 5'd16 - lz;
    wire [7:0]  e   = 8'd127 + msb;
    wire [39:0] mag_s = mag << (5'd23 - msb);

    assign result = (i == 16'sd0) ? 32'd0
                  : {i[15], e, mag_s[22:0]};

    function [4:0] clz_n;
        input [31:0] x;
        input [4:0]  w;
        integer k;
        reg [4:0] lz;
        begin
            lz = 5'd0;
            for (k = 0; k <= 31; k = k + 1) begin
                if (lz == k[4:0]) begin
                    if (k[4:0] <= w) begin
                        if (x[w - k[4:0]] == 1'b0)
                            lz = lz + 1'b1;
                    end
                end
            end
            clz_n = lz;
        end
    endfunction
endmodule

// 单精度浮点 → 16 位有符号整数（截断+饱和）
module f2i16 (
    input  wire [31:0] f,
    output wire signed [15:0] result
);
    wire        s    = f[31];
    wire [7:0]  e    = f[30:23];
    wire [22:0] mant = f[22:0];
    wire [23:0] m1   = {1'b1, mant};
    wire f_zero = (e == 8'd0) && (mant == 23'd0);

    wire signed [8:0] n_s = $signed({1'b0, e}) - 9'sd127;  // 2的幂次
    wire lt1 = (n_s <  9'd0);     // |值|<1 → 0
    wire big   = (n_s >= 9'd15);    // |值|≥32768 → 饱和
    wire [7:0] sh = n_s[8] ? 8'd23 : (8'd23 - n_s[7:0]);
    wire [24:0] i_raw = m1 >> sh;
    wire [15:0] i_abs = (i_raw > 25'd32767) ? 16'd32767 : i_raw[15:0];
    wire [15:0] i_val = lt1 ? 16'd0 : (big ? 16'd32767 : i_abs);

    assign result = f_zero ? 16'sd0
                  : (s ? -$signed(i_val) : $signed(i_val));
endmodule

// 位置环浮点 PID 顶层（接口与整数版 pid_pos 一致）
module pid_pos_fp #(
    parameter DATA_W    = 16,
    parameter OUT_W     = 16,
    parameter [31:0] KP_F        = 32'h3E800000, // 0.25f
    parameter [31:0] KI_F        = 32'h00000000, // 0.0f
    parameter [31:0] KD_F        = 32'h40200000, // 2.5f
    parameter [31:0] INTEG_MAX_F = 32'h459C4000, // 5000.0f
    parameter DEAD_ZONE = 0,
    parameter OUT_MAX   = 120
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      pid_en,   // 更新使能（一个时钟周期脉冲）
    input  wire signed [DATA_W-1:0]  target,   // 目标值
    input  wire signed [DATA_W-1:0]  actual,   // 实际反馈值
    output reg  signed [OUT_W-1:0]   pid_out   // PID输出（有符号，已限幅）
);

// 误差计算（整数域，带死区，与整数版一致）
wire signed [DATA_W-1:0]  err_raw = target - actual;
wire signed [DATA_W-1:0]  err_abs = err_raw[DATA_W-1] ? -err_raw : err_raw;
wire signed [DATA_W-1:0]  err     = (err_abs < $signed(DEAD_ZONE)) ? 'd0 : err_raw;
reg  signed [DATA_W-1:0]  err_prev;
wire signed [DATA_W-1:0]  deriv   = err - err_prev;

// 使能门控输入（省动态功耗）
wire signed [DATA_W-1:0]  err_g   = pid_en ? err   : 'd0;
wire signed [DATA_W-1:0]  deriv_g = pid_en ? deriv : 'd0;

// 整数 → 浮点
wire [31:0] err_f;
wire [31:0] deriv_f;
i2f16 u_i2f_err   (.i(err_g),   .result(err_f));
i2f16 u_i2f_deriv (.i(deriv_g), .result(deriv_f));

// 积分累加（浮点域）+ 积分限幅
reg  [31:0] integ_f;
wire [31:0] integ_new_f;
fp_add u_add_integ (.a(integ_f), .b(err_f), .result(integ_new_f));
wire [31:0] integ_abs   = {1'b0, integ_new_f[30:0]};   // 幅值（清符号位）
wire        integ_over  = (integ_abs > INTEG_MAX_F);    // 正浮点位序=数值序
wire [31:0] integ_clamped =
    integ_new_f[31] ? (integ_over ? {1'b1, INTEG_MAX_F[30:0]} : integ_new_f)
                    : (integ_over ? INTEG_MAX_F : integ_new_f);

// P / I / D 三项（浮点乘法）
wire [31:0] p_f;
wire [31:0] i_f;
wire [31:0] d_f;
fp_mul u_mul_p (.a(err_f),   .b(KP_F), .result(p_f));
fp_mul u_mul_i (.a(integ_f), .b(KI_F), .result(i_f));
fp_mul u_mul_d (.a(deriv_f), .b(KD_F), .result(d_f));

// 求和（浮点加法）
wire [31:0] sum1_f;
wire [31:0] sum2_f;
fp_add u_add_pi (.a(p_f), .b(i_f), .result(sum1_f));
fp_add u_add_sum (.a(sum1_f), .b(d_f), .result(sum2_f));

// 浮点 → 整数 + 输出限幅
wire signed [15:0] pid_raw;
f2i16 u_f2i_out (.f(sum2_f), .result(pid_raw));
wire signed [15:0] pid_int = (pid_raw >  $signed(OUT_MAX)) ?  $signed(OUT_MAX)
                           : (pid_raw < -$signed(OUT_MAX)) ? -$signed(OUT_MAX)
                           : pid_raw;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        err_prev <= 'd0;
        integ_f  <= 32'd0;
        pid_out  <= 'd0;
    end else if(pid_en) begin
        err_prev <= err;
        integ_f  <= integ_clamped;
        pid_out  <= pid_int;
    end
end

endmodule
