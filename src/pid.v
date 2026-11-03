// 位置式 PID：整数增益（KP/DIV），顺序恢复除法，P/I 与 D 分路限幅，向零截断
module pid #(
    parameter integer KP        = 30,       // 比例增益（实际 = KP/DIV）
    parameter integer KI        = 1,        // 积分增益（实际 = KI/DIV）
    parameter integer KD        = 40,       // 微分增益（实际 = KD/DIV）
    parameter integer DIV       = 1000,     // 分频系数（增益分母）
    parameter integer OUT_MAX   = 100,      // P/I 输出限幅（绝对值）
    parameter integer D_MAX     = 100,      // D 项独立限幅（绝对值，默认=OUT_MAX）
    parameter integer INT_LIM   = 100000,   // 积分累加限幅（抗饱和）
    parameter integer DEAD_ZONE = 0         // 误差死区：|err|<此值时 err=0，防止小误差抖动
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               tick,        // 计算触发脉冲（仅空闲态有效）
    input  wire               clr_int,     // 积分清零（任意时刻有效）
    input  wire signed [31:0] target,      // 目标值（有符号）
    input  wire signed [31:0] actual,      // 实际反馈值（有符号）
    output reg  signed [31:0] out,         // PID 总输出 = out_p + out_d（有符号）
    output reg  signed [31:0] out_p,       // P/I 项独立输出（限幅 ±OUT_MAX）
    output reg  signed [31:0] out_d,       // D 项独立输出（限幅 ±D_MAX）
    output reg                done         // 计算完成标志（拉高1拍）
);

    // 商位数：限幅后 |Out| <= OUT_MAX，故只需 clog2(OUT_MAX+1) 位
    localparam integer QB      = $clog2(OUT_MAX + 1);
    localparam [63:0]  SAT_ABS = OUT_MAX * DIV;   // |PI| >= 此值 -> P/I 直接饱和到 OUT_MAX
    localparam [63:0]  D_SAT   = D_MAX * DIV;     // |D| >= 此值 -> D 直接饱和到 D_MAX

    // 状态机：IDLE 锁存误差 → SUM 乘加 → ABS 取模/饱和 → DIV 除 P/I → D2 除 D → OUT 输出
    localparam S_IDLE = 3'd0,
               S_SUM  = 3'd1,
               S_ABS  = 3'd2,
               S_DIV  = 3'd3,
               S_D2   = 3'd4,
               S_OUT  = 3'd5;

    reg signed [31:0] e0, e1, ei;
    reg signed [31:0] de;                // 本拍 E0−E1
    reg signed [63:0] sum_r;             // PI 总和（KP·E0 + KI·ΣE）
    reg signed [63:0] d_r;               // D 项（KD·de）
    reg        [2:0]  st;
    reg               neg_pi, neg_d;
    reg               pi_sat, d_sat;
    reg        [63:0] rem,  drem;        // PI / D 除法余数
    reg        [31:0] quo,  dquo;        // PI / D 除法商（过程值）
    reg        [31:0] quo_pi, quo_d;     // PI / D 最终结果
    reg        [5:0]  bitn, dbitn;

    // 误差计算（带死区）
    wire signed [31:0] e_raw  = target - actual;
    wire signed [31:0] e_abs  = e_raw[31] ? -e_raw : e_raw;
    wire signed [31:0] e_new  = (e_abs < $signed(DEAD_ZONE)) ? 32'sd0 : e_raw;

    // 积分更新（抗饱和 + KI=0 清零 + clr_int）
    wire signed [31:0] ei_base = clr_int ? 32'sd0 : ei;
    wire signed [32:0] ei_raw  = $signed({ei_base[31], ei_base})
                               + $signed({e_new[31], e_new});
    wire signed [31:0] ei_new  = (KI == 0)           ? 32'sd0 :
                                 (ei_raw >  INT_LIM) ? INT_LIM :
                                 (ei_raw < -INT_LIM) ? -INT_LIM :
                                                       ei_raw[31:0];

    // PI / D 两项乘加
    wire signed [63:0] sum_pi = $signed(KP) * e0 + $signed(KI) * ei;
    wire signed [63:0] d_term = $signed(KD) * de;
    wire        [63:0] sum_abs = sum_r[63] ? -sum_r : sum_r;
    wire        [63:0] d_abs   = d_r[63]  ? -d_r   : d_r;
    wire        [63:0] dsh     = (64'd0 + DIV) << bitn;    // PI 除法试减：DIV << bitn
    wire        [63:0] dsh_d   = (64'd0 + DIV) << dbitn;   // D  除法试减

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e0 <= 0; e1 <= 0; ei <= 0; de <= 0;
            sum_r <= 0; d_r <= 0;
            st <= S_IDLE;
            neg_pi <= 1'b0; neg_d <= 1'b0;
            pi_sat <= 1'b0; d_sat <= 1'b0;
            rem <= 0; drem <= 0;
            quo <= 0; dquo <= 0;
            quo_pi <= 0; quo_d <= 0;
            bitn <= 0; dbitn <= 0;
            out <= 32'sd0; out_p <= 32'sd0; out_d <= 32'sd0; done <= 1'b0;
        end else begin
            done <= 1'b0;
            case (st)
                // 空闲：等待 tick，锁存误差与积分
                S_IDLE: if (tick) begin
                    e1   <= e0;
                    e0   <= e_new;
                    de   <= e_new - e0;
                    ei   <= ei_new;
                    st   <= S_SUM;
                end

                // 乘加：分别寄存 PI 总和与 D 项
                S_SUM: begin
                    sum_r <= sum_pi;
                    d_r   <= d_term;
                    st    <= S_ABS;
                end

                // 双路取模 + 提前饱和判断
                S_ABS: begin
                    // PI 路
                    neg_pi <= sum_r[63];
                    rem    <= sum_abs;                  // 向零截断 = 对模做除法再补号
                    bitn   <= QB - 1;
                    quo    <= 32'sd0;                   // 商清零，否则残留会算错
                    pi_sat <= (sum_abs >= SAT_ABS);
                    if (sum_abs >= SAT_ABS) quo_pi <= OUT_MAX;
                    else                     quo_pi <= 32'sd0;
                    // D 路
                    neg_d  <= d_r[63];
                    drem   <= d_abs;
                    dbitn  <= QB - 1;
                    dquo   <= 32'sd0;                   // 同上
                    d_sat  <= (d_abs >= D_SAT);
                    if (d_abs >= D_SAT) quo_d <= D_MAX;
                    else                quo_d <= 32'sd0;
                    st     <= S_DIV;
                end

                // PI 恢复除法：自高位起逐位试减 DIV<<bitn
                //   pi_sat 时已饱和（quo_pi 在 S_ABS 已置 OUT_MAX），本拍直接跳过
                S_DIV: begin
                    if (pi_sat) begin
                        st <= (d_sat) ? S_OUT : S_D2;
                    end else begin
                        if (rem >= dsh) begin
                            rem <= rem - dsh;
                            quo <= quo | (32'd1 << bitn);
                        end
                        if (bitn == 0) begin
                            // bit0 本拍判定下一拍才生效，这里显式并入
                            quo_pi <= quo | ((rem >= dsh) ? 32'd1 : 32'd0);
                            st     <= (d_sat) ? S_OUT : S_D2;
                        end else begin
                            bitn <= bitn - 1'b1;
                        end
                    end
                end

                // D 恢复除法（独立限幅，PI 饱和时仍输出阻尼）
                S_D2: begin
                    if (d_sat) begin
                        st <= S_OUT;
                    end else begin
                        if (drem >= dsh_d) begin
                            drem <= drem - dsh_d;
                            dquo <= dquo | (32'd1 << dbitn);
                        end
                        if (dbitn == 0) begin
                            // 同上
                            quo_d <= dquo | ((drem >= dsh_d) ? 32'd1 : 32'd0);
                            st    <= S_OUT;
                        end else begin
                            dbitn <= dbitn - 1'b1;
                        end
                    end
                end

                // 输出：P 项与 D 项分别补符号，各自独立限幅
                S_OUT: begin
                    out_p <= (neg_pi ? -$signed(quo_pi) : $signed(quo_pi));
                    out_d <= (neg_d  ? -$signed(quo_d)  : $signed(quo_d));
                    out   <= (neg_pi ? -$signed(quo_pi) : $signed(quo_pi))
                           + (neg_d  ? -$signed(quo_d)  : $signed(quo_d));
                    done <= 1'b1;
                    st   <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase

            // 独立的 clr_int：任意状态清 ΣE，不动 E0/E1
            if (clr_int && !(st == S_IDLE && tick)) ei <= 32'sd0;
        end
    end

endmodule
