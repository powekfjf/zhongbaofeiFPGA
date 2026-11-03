module  adc(

    input      		clk_50m		,	
    input      		rst_n		,
    // 3PA1030硬件接口	
    output	    	adc_clk		,	// ADC采样时钟输出
    output	    	adc_oe_n	,	// 输出使能低有效
    output	    	adc_stby_n	,	// 休眠低有效
    output			adc_otr		,
    input	[9:0]	adc_data_in	,	// D9~D0并行数据
    output	[11:0]	theta_out       
    
    );
	
//参数定义
reg				clk_div			; 
//将adc扩大到12bit,		
wire	[11:0]	theta_12bit		;  
reg		[11:0]	theta_out_reg	;
reg		[15:0]	theta_sum		;
reg		[12:0]	cnt_sample		;	// 125us采样间隔：6250时钟（0~6249）
reg		[15:0]	cnt_1ms			;	// 1ms输出周期：50000时钟（0~49999）
reg		[3:0]	cnt_add			;	// 采样次数计数（0~7）

//信号定义
assign adc_oe_n     = 1'b0;
assign adc_stby_n   = 1'b0;  
assign adc_otr      = 1'b0;
assign theta_12bit  = {adc_data_in, 2'b0};
assign theta_out    = theta_out_reg;

// ADC时钟：50MHz二分频 = 25MHz输出给3PA1030 CLK引脚
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        clk_div <= 1'b0;
    else 
        clk_div <= ~clk_div;
end

assign adc_clk = clk_div;

// 125us采样间隔计数器（50MHz / 6250 = 8kHz）
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        cnt_sample <= 'd0;
    else if(cnt_sample == 13'd6249)
        cnt_sample <= 'd0;
    else 
        cnt_sample <= cnt_sample + 1'b1;
end

// 1ms输出周期计数器（50MHz / 50000 = 1kHz）
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        cnt_1ms <= 'd0;
    else if(cnt_1ms == 16'd49999)
        cnt_1ms <= 'd0;
    else 
        cnt_1ms <= cnt_1ms + 1'b1;
end

// 采样累加 + 1ms输出8次平均
// 每125us采一次，1ms内恰好8次；输出theta_sum/8，延迟约0.5ms
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        theta_sum     <= 'd0;
        cnt_add       <= 'd0;
        theta_out_reg <= 'd0;
    end else if(cnt_sample == 13'd6248) begin
        // 每125us采样累加
        theta_sum <= theta_sum + theta_12bit;
        cnt_add   <= cnt_add + 1'b1;
    end else if(cnt_1ms == 16'd49999) begin
        // 每1ms输出8次平均值（除以8 = 右移3位）
        theta_out_reg <= theta_sum[14:3];
        theta_sum     <= 'd0;
        cnt_add       <= 'd0;
    end
end

endmodule
