module top(

    input			clk_50m 	,	//时钟输入
    input			rst_n   	,	//复位输入
	
	input	[3:0]	key_sw		,	//SW1~SW4按键（4位，按下低有效）	
	
	output			uart_tx		,	//串口发送
    input			uart_rx		,	//串口接收

    // ADC WDD35D4 接口
    output			adc_clk		,	// ADC采样时钟输出
    output			adc_oe_n	,	// 输出使能低有效

    output			adc_stby_n	,	// 休眠低有效
    input	[9:0]	adc_data_in	,	// D9~D0并行数据
    
	//编码器接口（增量式正交信号，四倍频计数）
    input			enc1_a		,	//编码器1输出的A相
    input			enc1_b		,	//编码器1输出的B相
    input			enc2_a		,	//编码器2输出的A相
    input			enc2_b		,	//编码器2输出的B相
	
	//电机A/B驱动输出（TB6612驱动 + MG531电机）
    output			AN1			,	//A电机控制信号IN1
    output			AN2			,	//A电机控制信号IN2
    output			PWMA		,	//A电机PWM输出
	
    output			BN1			,	//B电机控制信号IN1
    output			BN2			,   //B电机控制信号IN2
    output			PWMB		,    //B电机PWM输出
    
    output   test       // 测试输出：0=正常运行 1=测试模式（接givo_test）
    );
	
	wire			[03:0]	swing_key		;
	
	genvar i;
		generate for(i = 0; i <= 3; i = i + 1) begin
	
		key_filter #(
	
			.CNT_MAX ( 20'd1000_000)
		
		) key_filter_inst (
	
			.sys_clk	(clk_50m),	
			.sys_rst_n	(rst_n),	
			.key_in		(key_sw[i]),
			
			.key_flag	(swing_key[i])
	
		);
	
		end
	endgenerate


// ADC 角度采集
wire 			[11:0]	theta_out	;
reg		signed	[15:0]	theta_r		;
wire	signed	[15:0]	theta_out_r	;

wire givo_test/*synthesis syn_keep=1*/; 	// 测试信号（syn_keep=1：综合时保持不优化）
assign givo_test = test?0:1;				// 测试模式：test=1时输出0

adc adc_inst(

   .clk_50m     (clk_50m	),	
   .rst_n		(rst_n		),
   // 3PA1030硬件接口	
   .adc_clk		(adc_clk	),	// ADC采样时钟输出
   .adc_oe_n	(adc_oe_n	),	// 输出使能低有效
   .adc_stby_n	(adc_stby_n	),	// 休眠低有效
   .adc_data_in	(adc_data_in),	// D9~D0并行数据
   .theta_out   (theta_out	)	//采集的实时角度值输出
   
);   

//保存当前theta_r值,并符号化（用于UART上报）
always@(posedge clk_50m or negedge rst_n)begin
    if(!rst_n)begin
        theta_r <= 0;
    end else 
        theta_r <= {0,theta_out};
end

assign theta_out_r = theta_r + $signed(135);	//UART上报用偏移

// 编码器位置信号（提前声明，避免隐式1位wire）
wire [15:0] enc_pos1, enc_pos2;

// PID 更新节拍：5ms 角度环、50ms 位置环
reg [17:0] cnt_angle;
reg        pulse_5ms;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        cnt_angle <= 'd0;
        pulse_5ms <= 1'b0;
    end else if(cnt_angle == 18'd249_999) begin  // 50MHz / 250000 = 200Hz = 5ms
        cnt_angle <= 'd0;
        pulse_5ms <= 1'b1;
    end else begin
        cnt_angle <= cnt_angle + 1'b1;
        pulse_5ms <= 1'b0;
    end
end

// 50ms 位置环
reg [21:0] cnt_pos;
reg        pulse_50ms;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        cnt_pos     <= 'd0;
        pulse_50ms  <= 1'b0;
    end else if(cnt_pos == 22'd2_499_999) begin  // 50MHz / 2500000 = 20Hz = 50ms
        cnt_pos     <= 'd0;
        pulse_50ms  <= 1'b1;
    end else begin
        cnt_pos     <= cnt_pos + 1'b1;
        pulse_50ms  <= 1'b0;
    end
end


// 位置环
// 目标位置 = 编码器复位初始值 10000；每按一次SW2，目标位置+800
// 实际位置 = 电机1编码器 enc_pos1
// 输出 = 有符号角度偏移，叠加到中心角度得到角度环目标
reg signed [15:0] target_pos;   // 赋值 always 见下方（起摆切平衡处，避免前向引用）
wire signed [15:0] actual_pos  = $signed(enc_pos1);

// 位置环参数
localparam POS_KP        = 750;      // 比例系数（实际 = KP/DIV = 0.3）；饱和点 100/0.3=333 LSB，扩大线性区
localparam POS_KI        = 0;      // 积分系数（倒立摆保持0）
localparam POS_KD        = 4250;      // 微分系数（实际 = 3.0，加强旋转臂转速阻尼，压住pe振幅增长）
localparam POS_DIV       = 1000;   // 分频系数
localparam POS_DEAD_ZONE = 0;      // 误差死区
localparam POS_INTEG_MAX = 5000;   // 积分限幅
localparam POS_OUT_MAX   = 150;    // P 项输出限幅
localparam POS_D_MAX     = 150;    // D 项独立限幅（与 P 分开，可单独调节）

// 位置环 PID 实例
wire signed [31:0] pos_target32 = {{16{target_pos[15]}}, target_pos};
wire signed [31:0] pos_actual32 = {{16{actual_pos[15]}}, actual_pos};
wire signed [31:0] pos_out_core;
wire signed [31:0] pos_out_p_core, pos_out_d_core;
wire               pos_done;

pid #(
    .KP       (POS_KP),
    .KI       (POS_KI),
    .KD       (POS_KD),
    .DIV      (POS_DIV),
    .DEAD_ZONE(POS_DEAD_ZONE),
    .INT_LIM  (POS_INTEG_MAX),
    .OUT_MAX  (POS_OUT_MAX),
    .D_MAX    (POS_D_MAX)
) pid_pos_inst (
    .clk    (clk_50m),
    .rst_n  (rst_n),
    .tick   (pulse_50ms),     // 20Hz 节拍触发（50ms）
    .clr_int(1'b0),
    .target (pos_target32),
    .actual (pos_actual32),
    .out    (pos_out_core),
    .out_p  (pos_out_p_core),
    .out_d  (pos_out_d_core),
    .done   (pos_done)
);

// P/D 分别锁存，done 到来时更新
reg signed [15:0] pos_pid_out;
reg signed [15:0] pos_d_out;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        pos_pid_out <= 16'sd0;
        pos_d_out   <= 16'sd0;
    end else if(swing_catch) begin
        pos_pid_out <= 16'sd0;               // 起摆切平衡瞬间清零，避免目标角度阶跃
        pos_d_out   <= 16'sd0;
    end else if(pos_done) begin
        pos_pid_out <= pos_out_p_core[15:0];
        pos_d_out   <= pos_out_d_core[15:0];
    end
end


// 起摆状态机
// 状态0 空闲，1 判断入域，2/3 右转保持，4/5 左转保持，6 回到 1
// 摆杆倒下后自动重新起摆（auto_restart），SW4 未使用
localparam [15:0] SWING_DUTY = 16'd40;          // 起摆占空比（40%）
localparam [23:0] SWING_WAIT = 24'd15_000_000;  // 摆动延时 300ms @50MHz

localparam [2:0] ST_IDLE = 3'd0,  // 状态0：电机不启动
                 ST_CHK  = 3'd1,  // 状态1：判断摆杆是否在可调控范围
                 ST_R    = 3'd2,  // 状态2：电机向右旋转
                 ST_RW   = 3'd3,  // 状态3：延时100ms（右转保持）
                 ST_L    = 3'd4,  // 状态4：电机向左旋转
                 ST_LW   = 3'd5,  // 状态5：延时100ms（左转保持）
                 ST_LOOP = 3'd6;  // 状态6：回到状态1重新判断

reg [2:0]  swing_st;        // 起摆状态
reg [23:0] swing_timer;     // 延时计数器
reg        swing_catch;     // 切平衡脉冲（清零位置环输出，避免目标角度阶跃）

// 位置环输出低通
reg signed [15:0] pos_out_filtered;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        pos_out_filtered <= 'd0;
    else if(swing_catch)
        pos_out_filtered <= 'd0;           // 起摆切平衡瞬间清零，避免目标角度阶跃
    else if(pulse_50ms)
        pos_out_filtered <= (pos_out_filtered * 2 + pos_pid_out) >>> 2;
end

// 目标角度 = 中心角 + 位置环输出
wire signed [15:0] center_angle = 16'sd3122;
wire signed [15:0] target_angle = center_angle + pos_out_filtered + pos_d_out;

// 起摆判据
wire signed [15:0] sw_dev     = actual_angle - center_angle;
wire signed [15:0] sw_dev_abs = sw_dev[15] ? -sw_dev : sw_dev;
wire sw_in_range = (sw_dev_abs <= 16'sd400);

// 起摆状态机
// 起摆中每拍判断是否入域，入域立即切平衡
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        swing_st    <= ST_IDLE;
        swing_timer <= 'd0;
        swing_catch <= 1'b0;
    end else begin
        swing_catch <= 1'b0;
        if(swing_key[0] || (auto_restart && swing_st == ST_IDLE)) begin
            // SW1手动 / 倒下立刻自动 → 重新起摆
            swing_st <= ST_CHK;
        end else if((swing_st != ST_IDLE) && sw_in_range) begin
            // 入域即切平衡
            swing_st    <= ST_IDLE;
            swing_catch <= 1'b1;                   // 触发置平衡/清倒下/位置环输出清零
        end else begin
            case(swing_st)
                ST_IDLE: begin
                    swing_timer <= 'd0;
                end
                ST_CHK: begin                      // 按下SW1后首次检测（不在范围）
                    swing_st <= ST_R;              // → 开始右转摆荡
                end
                ST_R: begin                        // 右转置位，进入延时态
                    swing_timer <= 'd0;
                    swing_st    <= ST_RW;
                end
                ST_RW: begin                       // 右转保持 300ms
                    if(swing_timer >= SWING_WAIT) begin
                        swing_st    <= ST_L;
                        swing_timer <= 'd0;
                    end else
                        swing_timer <= swing_timer + 1'b1;
                end
                ST_L: begin                        // 左转置位，进入延时态
                    swing_timer <= 'd0;
                    swing_st    <= ST_LW;
                end
                ST_LW: begin                       // 左转保持 300ms
                    if(swing_timer >= SWING_WAIT) begin
                        swing_st    <= ST_LOOP;
                        swing_timer <= 'd0;
                    end else
                        swing_timer <= swing_timer + 1'b1;
                end
                ST_LOOP: begin                     // 回到状态1重新判断
                    swing_st <= ST_CHK;
                end
                default: swing_st <= ST_IDLE;
            endcase
        end
    end
end

// 目标位置赋值
reg signed [15:0] pos_base;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        target_pos <= 16'sd10000;
    else if(swing_st != ST_IDLE)    // 起摆期间：目标位置持续跟随当前编码器位置
        target_pos <= enc_pos1;
    else if(swing_key[2])           // SW3按下：锁存当前位置为正弦摆动基准
        pos_base <= target_pos;
    else if(sin_done && sin_en)     // SW3正弦扰动：围绕基准叠加sin输出
        target_pos <= pos_base + sin_y;
    else if(swing_key[1]) begin     // SW2按下（去抖后单周期脉冲）
        if(target_pos > 16'sd31767) // 饱和保护：上限32767
            target_pos <= 16'sd32767;
        else
            target_pos <= target_pos + 16'sd800;
    end
end

// SW3 正弦扰动
localparam [25:0] SIN_TICK_CNT = 26'd_2_500_000;  // 50ms @50MHz

reg        sin_en;        // SW3 开关（toggle）
reg [25:0] sin_timer;
reg        pulse_sin;     // 500ms 到点脉冲 → sin.tick
reg [7:0]  x_cnt;         // 时间计数，每 500ms +1，8位无符号：255后自动回0

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        sin_en    <= 1'b0;
        sin_timer <= 26'd0;
        pulse_sin <= 1'b0;
        x_cnt     <= 8'd0;
    end else if(swing_key[2]) begin     // SW3 toggle
        sin_en    <= ~sin_en;
        sin_timer <= 26'd0;
        pulse_sin <= 1'b0;
        x_cnt     <= 8'd0;              // 重新开启时相位从0开始
    end else if(sin_en) begin
        if(sin_timer >= SIN_TICK_CNT) begin
            sin_timer <= 26'd0;
            pulse_sin <= 1'b1;
            x_cnt     <= x_cnt + 1'b1;
        end else begin
            sin_timer <= sin_timer + 1'b1;
            pulse_sin <= 1'b0;
        end
    end else begin
        sin_timer <= 26'd0;
        pulse_sin <= 1'b0;
    end
end

// 正弦查表
wire signed [15:0] sin_y;
wire               sin_done;
sin_wave #(
    .A(16'd400),        // 摆幅 ±400 编码器计数
    .B(16'd128),       // x=0~255 正好走一圈正弦
    .C(16'd0),
    .D(16'sd0)
) u_sin_pos (
    .clk(clk_50m),
    .rst_n(rst_n),
    .tick(pulse_sin),
    .x(x_cnt),
    .y(sin_y),
    .done(sin_done)
);


// 角度环 PID
wire signed [15:0] actual_angle  = $signed({4'b0, theta_out});

// 角度环参数（整数/DIV 精确表示）
// 原实现 KP=4, DIV_SHIFT=4 → 等效 4/16 = 0.25 → 折算 KP=250, DIV=1000
localparam ANG_KP        = 800;    // 比例系数（实际 = KP/DIV = 1.2）；分步调试第1步失败后加大纠偏力
localparam ANG_KI        = 0;      // 积分系数（倒立摆保持0）
localparam ANG_KD        = 2000;      // 微分系数（实际 = 6.0，阻尼翻倍防振荡）
localparam ANG_DIV       = 1000;   // 分频系数
localparam ANG_DEAD_ZONE = 0;      // 误差死区
localparam ANG_INTEG_MAX = 2000;   // 积分限幅
localparam ANG_OUT_MAX   = 100;    // 输出限幅±100

// 角度环 PID 实例
wire signed [31:0] ang_target32 = {{16{target_angle[15]}}, target_angle};
wire signed [31:0] ang_actual32 = {{16{actual_angle[15]}}, actual_angle};
wire signed [31:0] ang_out_core;
wire               ang_done;

pid #(
    .KP       (ANG_KP),
    .KI       (ANG_KI),
    .KD       (ANG_KD),
    .DIV      (ANG_DIV),
    .DEAD_ZONE(ANG_DEAD_ZONE),
    .INT_LIM  (ANG_INTEG_MAX),
    .OUT_MAX  (ANG_OUT_MAX),
    .D_MAX    (ANG_OUT_MAX)
) pid_angle_inst (
    .clk    (clk_50m),
    .rst_n  (rst_n),
    .tick   (pulse_5ms),      // 200Hz 节拍触发（5ms）
    .clr_int(1'b0),
    .target (ang_target32),
    .actual (ang_actual32),
    .out    (ang_out_core),
    .done   (ang_done)
);

// 角度环输出锁存
reg signed [15:0] angle_pid_out;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        angle_pid_out <= 16'sd0;
    else if(ang_done)
        angle_pid_out <= ang_out_core[15:0];
end


// 平衡使能
reg balance_en;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        balance_en <= 1'b0;
    else if(swing_key[0])   // SW1按下 → 开启平衡
        balance_en <= 1'b1;
    else if(swing_catch)   // 起摆到位 / 倒下自动重启到位 → 自动开启平衡
        balance_en <= 1'b1;
end

// 倒下检测
localparam FALL_THRESHOLD = 16'sd800;  // 偏离中心角度(3122)超过800认为倒下
wire signed [15:0] angle_dev     = actual_angle - center_angle;
wire signed [15:0] angle_dev_abs = angle_dev[15] ? -angle_dev : angle_dev;

reg fall_down;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        fall_down <= 1'b0;
    else if(swing_key[0])            // 按SW1清除倒下标志，重新起摆
        fall_down <= 1'b0;
    else if(swing_catch)            // 起摆到位 → 清除倒下标志
        fall_down <= 1'b0;
    else if(angle_dev_abs > FALL_THRESHOLD)
        fall_down <= 1'b1;           // 倒下，自锁
end

// 是否成功平衡过：上电为 0，用于区分上电垂吊和运行中倒下
reg ever_balanced;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        ever_balanced <= 1'b0;
    else if(swing_catch)
        ever_balanced <= 1'b1;        // 起摆到位进入平衡 → 武装自动重启
end

// 倒下后自动重起
wire auto_restart = ever_balanced && fall_down;

// 电机使能：平衡开启 且 摆杆未倒下
wire motor_enable = balance_en && !fall_down;

// 角度环输出 → 电机方向/占空比
wire        pid_neg   = angle_pid_out[15];                    // 符号位：1=负
wire signed [15:0] abs_out = pid_neg ? -angle_pid_out : angle_pid_out;
// 输出为0时停机
wire        motor_run = motor_enable && (angle_pid_out != 16'sd0);
// 起摆时开环摆动
wire swing_on = (swing_st != ST_IDLE) && (swing_st != ST_CHK);
// 起摆方向
wire [1:0]  swing_dir_cur = ((swing_st == ST_R) || (swing_st == ST_RW)) ? 2'b10
                          : ((swing_st == ST_L) || (swing_st == ST_LW) || (swing_st == ST_LOOP)) ? 2'b01
                          : 2'b00;
wire [1:0]  motor_b_dir  = swing_on ? swing_dir_cur
                          : (motor_run ? (pid_neg ? 2'b01 : 2'b10) : 2'b00);
wire [15:0] motor_b_duty = swing_on ? SWING_DUTY                     // 起摆：固定40%占空比
                          : (motor_run ? abs_out[15:0] : 16'd0);

// 电机A 停用
motor_ctrl motor_ctrl_A(

    .clk_50m		(clk_50m		),	//时钟输入
    .rst_n			(rst_n			),	//复位输入
    .motor_a_sel	(2'b00			),	//停止
    .duty_out		(10'd0			),
	//output 
    .ain1			(AN1			),
    .ain2			(AN2			),
	
	.pwm			(PWMA			)
	
    );


// 电机B 角度环控制
motor_ctrl motor_ctrl_B(

    .clk_50m		(clk_50m		),	//时钟输入
    .rst_n			(rst_n			),	//复位输入
    .motor_a_sel	(motor_b_dir	),
    .duty_out		(motor_b_duty	),
	//output 
    .ain1			(BN1			),
    .ain2			(BN2			),
	
	.pwm			(PWMB			)
	
    );
	
	encoder encoder_1 (
	
		.clk_50m		(clk_50m),
		.rst_n			(rst_n),
				
		.enc_a			(enc1_a), 
		.enc_b			(enc1_b),
		
		.pos			(enc_pos1)	//编码器采集的位置环
	
	);

	encoder encoder_2 (
	
		.clk_50m		(clk_50m),
		.rst_n			(rst_n),
				
		.enc_a			(enc2_a), 
		.enc_b			(enc2_b),
		
		.pos			(enc_pos2)	//编码器采集的位置环
	
	);	
	
	wire	[15:0]	data_out;
	
reg [31:0] cnt_500ms;
reg [15:0] data_in_reg;
reg [31:0] encoder_in_reg;

always@(posedge clk_50m or negedge rst_n) begin
	if(!rst_n) begin
		cnt_500ms <= 0;
		data_in_reg <= 0;
		encoder_in_reg <= 0; 
		end
	else if(cnt_500ms == 32'd12_499_999) begin  // 50MHz/12500000=250ms
		cnt_500ms <= 0;
		data_in_reg <= {4'b0, theta_out};  // 发送原始12位ADC值
		encoder_in_reg <= {enc_pos1, enc_pos2};
		end
	else begin
		cnt_500ms <= cnt_500ms +1;
		data_in_reg <=	data_in_reg;
		encoder_in_reg <= encoder_in_reg;
		end
end


// 串口调试数据
wire signed [15:0] ang_err_dbg = target_angle - actual_angle;
wire signed [15:0] pos_err_dbg = target_pos - actual_pos;

uart #(

) uart_inst (

	.clk_50M		(clk_50m		),
	.rst_n			(rst_n			),

	.key3			(swing_key[2]	),

	.fpga_rx		(uart_rx		),
	.fpga_tx		(uart_tx		),

	.data_in		(target_pos	),	//位置环目标位置（有符号），每50ms发送

	.data_out   	(data_out		)
	
);

endmodule
