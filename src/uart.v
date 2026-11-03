module uart #(

    parameter   CNT_1S = 32'd2_499_999 //发送间隔：50MHz计数2500000 = 50ms

)(

    input              		clk_50M		,
    input              		rst_n		,

    input					key3		,

    input              		fpga_rx		,
    output             		fpga_tx		,

    input      		signed [15:0] data_in	,   // 要发送的数据（target_pos，有符号）

    output	reg		[15:0]	data_out

);

parameter	UART_BPS       =   21'd115200		,   //波特率115200
            CLK_FREQ       =   26'd50_000_000	,   //时钟频率50MHz
            SEN_CNT_MAX    =   20'd5000		,   //字节间间隔0.1ms
            SEN_BYTE_CNT   =   5'd7				;	//发送8字节（索引0~7）

wire			pi_flag		;
wire	[7:0]	pi_data		;
wire			pi_done		;

uart_tx #(

    .UART_BPS    (UART_BPS  ),
    .CLK_FREQ    (CLK_FREQ  )

) uart_tx_inst (

    .sys_clk    (clk_50M    ),
    .sys_rst_n  (rst_n      ),
    .pi_data    (pi_data    ),
    .pi_flag    (pi_flag    ),

    .tx         (fpga_tx    ),
    .pi_done    (pi_done    )

);

// 帧编码：target_pos 有符号 5 位十进制
// 帧格式：+PPPPP\r\n（共 8 字节）
// 示例：+10000\r\n  或  -00400\r\n
wire        neg = data_in[15];
wire [15:0] abs_v = neg ? -data_in : data_in;
wire [3:0]  d4 = (abs_v / 10000) % 10;   // 万位
wire [3:0]  d3 = (abs_v / 1000)  % 10;   // 千位
wire [3:0]  d2 = (abs_v / 100)   % 10;   // 百位
wire [3:0]  d1 = (abs_v / 10)    % 10;   // 十位
wire [3:0]  d0 = abs_v % 10;             // 个位
wire [7:0]  a4 = d4 + 8'h30;
wire [7:0]  a3 = d3 + 8'h30;
wire [7:0]  a2 = d2 + 8'h30;
wire [7:0]  a1 = d1 + 8'h30;
wire [7:0]  a0 = d0 + 8'h30;
wire [7:0]  v_sign = neg ? 8'h2D : 8'h2B;  // '-' 或 '+'

// 定时发送触发
reg [31:0] timer_cnt;
reg        send_valid;

always @(posedge clk_50M or negedge rst_n) begin
    if(!rst_n) begin
        timer_cnt  <= 'd0;
        send_valid <= 1'b0;
    end else if(timer_cnt == CNT_1S) begin
        timer_cnt  <= 'd0;
        send_valid <= 1'b1;          // 到时间，开始发送
    end else begin
        timer_cnt <= timer_cnt + 1'b1;
        if(tx_byte_cnt > SEN_BYTE_CNT)
            send_valid <= 1'b0;      // 发完，停止
    end
end

// 字节间间隔计时
reg [21:0] send_cnt;
always @(posedge clk_50M or negedge rst_n) begin
    if(!rst_n)
        send_cnt <= 'd0;
    else if(send_valid && send_cnt < SEN_CNT_MAX && tx_byte_cnt <= SEN_BYTE_CNT)
        send_cnt <= send_cnt + 1'b1;
    else
        send_cnt <= 'd0;
end

wire send_en = (send_cnt == SEN_CNT_MAX - 1) ? 1'b1 : 1'b0;
assign pi_flag = send_en;
assign pi_data = pi_data_r;

// 发送字节计数
reg [4:0] tx_byte_cnt;
always @(posedge clk_50M or negedge rst_n) begin
    if(!rst_n)
        tx_byte_cnt <= 5'd0;
    else if(timer_cnt == CNT_1S)
        tx_byte_cnt <= 5'd0;           // 新一轮发送，清零
    else if(tx_byte_cnt > SEN_BYTE_CNT)
        tx_byte_cnt <= SEN_BYTE_CNT + 1;
    else if(send_en)
        tx_byte_cnt <= tx_byte_cnt + 1'b1;
end

// 发送数据选择
reg [7:0] pi_data_r;
always @(posedge clk_50M or negedge rst_n) begin
    if(!rst_n)
        pi_data_r <= 'd0;
    else if(send_en) begin
        case(tx_byte_cnt)
            0 : pi_data_r <= v_sign;   // 符号
            1 : pi_data_r <= a4;       // 万位
            2 : pi_data_r <= a3;       // 千位
            3 : pi_data_r <= a2;       // 百位
            4 : pi_data_r <= a1;       // 十位
            5 : pi_data_r <= a0;       // 个位
            6 : pi_data_r <= 8'h0D;     // 回车 \r
            7 : pi_data_r <= 8'h0A;     // 换行 \n
            default: pi_data_r <= 8'h00;
        endcase
    end
end

endmodule
