// sin_wave.v  正弦查表：y = A*sin(B*x + C) + D，256 点表 + 线性插值
// z = B*x + C 为 Q15 相位（32768 = 2π），tick 到来算一次，3 拍后 done
module sin_wave #(
    parameter        [15:0] A = 16'd100,    // 输出幅值(无符号, 0~65535)
    parameter        [15:0] B = 16'd82,     // 每 tick 相位增量 Q15(无符号)
    parameter        [15:0] C = 16'd0,      // 相位偏移 Q15(无符号)
    parameter signed [15:0] D = 16'sd0      // 直流中心(有符号, 与 y 同格式)
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               tick,          // 一拍脉冲: 启动一次计算
    input  wire      [7:0]  x,             // 时间/自变量输入(无符号8位, 0~255循环)
    output reg  signed [15:0] y,
    output reg                done
);

// 256 点 sin 查表（Q14，满幅 ±16384）
function signed [15:0] sin_lut;
    input [7:0] idx;
    begin
        case(idx)
            8'd0  : sin_lut = 16'sd0;
            8'd1  : sin_lut = 16'sd402;
            8'd2  : sin_lut = 16'sd804;
            8'd3  : sin_lut = 16'sd1205;
            8'd4  : sin_lut = 16'sd1606;
            8'd5  : sin_lut = 16'sd2006;
            8'd6  : sin_lut = 16'sd2404;
            8'd7  : sin_lut = 16'sd2801;
            8'd8  : sin_lut = 16'sd3196;
            8'd9  : sin_lut = 16'sd3590;
            8'd10 : sin_lut = 16'sd3981;
            8'd11 : sin_lut = 16'sd4370;
            8'd12 : sin_lut = 16'sd4756;
            8'd13 : sin_lut = 16'sd5139;
            8'd14 : sin_lut = 16'sd5520;
            8'd15 : sin_lut = 16'sd5897;
            8'd16 : sin_lut = 16'sd6270;
            8'd17 : sin_lut = 16'sd6639;
            8'd18 : sin_lut = 16'sd7005;
            8'd19 : sin_lut = 16'sd7366;
            8'd20 : sin_lut = 16'sd7723;
            8'd21 : sin_lut = 16'sd8076;
            8'd22 : sin_lut = 16'sd8423;
            8'd23 : sin_lut = 16'sd8765;
            8'd24 : sin_lut = 16'sd9102;
            8'd25 : sin_lut = 16'sd9434;
            8'd26 : sin_lut = 16'sd9760;
            8'd27 : sin_lut = 16'sd10080;
            8'd28 : sin_lut = 16'sd10394;
            8'd29 : sin_lut = 16'sd10702;
            8'd30 : sin_lut = 16'sd11003;
            8'd31 : sin_lut = 16'sd11297;
            8'd32 : sin_lut = 16'sd11585;
            8'd33 : sin_lut = 16'sd11866;
            8'd34 : sin_lut = 16'sd12140;
            8'd35 : sin_lut = 16'sd12406;
            8'd36 : sin_lut = 16'sd12665;
            8'd37 : sin_lut = 16'sd12916;
            8'd38 : sin_lut = 16'sd13160;
            8'd39 : sin_lut = 16'sd13395;
            8'd40 : sin_lut = 16'sd13623;
            8'd41 : sin_lut = 16'sd13842;
            8'd42 : sin_lut = 16'sd14053;
            8'd43 : sin_lut = 16'sd14256;
            8'd44 : sin_lut = 16'sd14449;
            8'd45 : sin_lut = 16'sd14635;
            8'd46 : sin_lut = 16'sd14811;
            8'd47 : sin_lut = 16'sd14978;
            8'd48 : sin_lut = 16'sd15137;
            8'd49 : sin_lut = 16'sd15286;
            8'd50 : sin_lut = 16'sd15426;
            8'd51 : sin_lut = 16'sd15557;
            8'd52 : sin_lut = 16'sd15679;
            8'd53 : sin_lut = 16'sd15791;
            8'd54 : sin_lut = 16'sd15893;
            8'd55 : sin_lut = 16'sd15986;
            8'd56 : sin_lut = 16'sd16069;
            8'd57 : sin_lut = 16'sd16143;
            8'd58 : sin_lut = 16'sd16207;
            8'd59 : sin_lut = 16'sd16261;
            8'd60 : sin_lut = 16'sd16305;
            8'd61 : sin_lut = 16'sd16340;
            8'd62 : sin_lut = 16'sd16364;
            8'd63 : sin_lut = 16'sd16379;
            8'd64 : sin_lut = 16'sd16384;
            8'd65 : sin_lut = 16'sd16379;
            8'd66 : sin_lut = 16'sd16364;
            8'd67 : sin_lut = 16'sd16340;
            8'd68 : sin_lut = 16'sd16305;
            8'd69 : sin_lut = 16'sd16261;
            8'd70 : sin_lut = 16'sd16207;
            8'd71 : sin_lut = 16'sd16143;
            8'd72 : sin_lut = 16'sd16069;
            8'd73 : sin_lut = 16'sd15986;
            8'd74 : sin_lut = 16'sd15893;
            8'd75 : sin_lut = 16'sd15791;
            8'd76 : sin_lut = 16'sd15679;
            8'd77 : sin_lut = 16'sd15557;
            8'd78 : sin_lut = 16'sd15426;
            8'd79 : sin_lut = 16'sd15286;
            8'd80 : sin_lut = 16'sd15137;
            8'd81 : sin_lut = 16'sd14978;
            8'd82 : sin_lut = 16'sd14811;
            8'd83 : sin_lut = 16'sd14635;
            8'd84 : sin_lut = 16'sd14449;
            8'd85 : sin_lut = 16'sd14256;
            8'd86 : sin_lut = 16'sd14053;
            8'd87 : sin_lut = 16'sd13842;
            8'd88 : sin_lut = 16'sd13623;
            8'd89 : sin_lut = 16'sd13395;
            8'd90 : sin_lut = 16'sd13160;
            8'd91 : sin_lut = 16'sd12916;
            8'd92 : sin_lut = 16'sd12665;
            8'd93 : sin_lut = 16'sd12406;
            8'd94 : sin_lut = 16'sd12140;
            8'd95 : sin_lut = 16'sd11866;
            8'd96 : sin_lut = 16'sd11585;
            8'd97 : sin_lut = 16'sd11297;
            8'd98 : sin_lut = 16'sd11003;
            8'd99 : sin_lut = 16'sd10702;
            8'd100: sin_lut = 16'sd10394;
            8'd101: sin_lut = 16'sd10080;
            8'd102: sin_lut = 16'sd9760;
            8'd103: sin_lut = 16'sd9434;
            8'd104: sin_lut = 16'sd9102;
            8'd105: sin_lut = 16'sd8765;
            8'd106: sin_lut = 16'sd8423;
            8'd107: sin_lut = 16'sd8076;
            8'd108: sin_lut = 16'sd7723;
            8'd109: sin_lut = 16'sd7366;
            8'd110: sin_lut = 16'sd7005;
            8'd111: sin_lut = 16'sd6639;
            8'd112: sin_lut = 16'sd6270;
            8'd113: sin_lut = 16'sd5897;
            8'd114: sin_lut = 16'sd5520;
            8'd115: sin_lut = 16'sd5139;
            8'd116: sin_lut = 16'sd4756;
            8'd117: sin_lut = 16'sd4370;
            8'd118: sin_lut = 16'sd3981;
            8'd119: sin_lut = 16'sd3590;
            8'd120: sin_lut = 16'sd3196;
            8'd121: sin_lut = 16'sd2801;
            8'd122: sin_lut = 16'sd2404;
            8'd123: sin_lut = 16'sd2006;
            8'd124: sin_lut = 16'sd1606;
            8'd125: sin_lut = 16'sd1205;
            8'd126: sin_lut = 16'sd804;
            8'd127: sin_lut = 16'sd402;
            8'd128: sin_lut = 16'sd0;
            8'd129: sin_lut = -16'sd402;
            8'd130: sin_lut = -16'sd804;
            8'd131: sin_lut = -16'sd1205;
            8'd132: sin_lut = -16'sd1606;
            8'd133: sin_lut = -16'sd2006;
            8'd134: sin_lut = -16'sd2404;
            8'd135: sin_lut = -16'sd2801;
            8'd136: sin_lut = -16'sd3196;
            8'd137: sin_lut = -16'sd3590;
            8'd138: sin_lut = -16'sd3981;
            8'd139: sin_lut = -16'sd4370;
            8'd140: sin_lut = -16'sd4756;
            8'd141: sin_lut = -16'sd5139;
            8'd142: sin_lut = -16'sd5520;
            8'd143: sin_lut = -16'sd5897;
            8'd144: sin_lut = -16'sd6270;
            8'd145: sin_lut = -16'sd6639;
            8'd146: sin_lut = -16'sd7005;
            8'd147: sin_lut = -16'sd7366;
            8'd148: sin_lut = -16'sd7723;
            8'd149: sin_lut = -16'sd8076;
            8'd150: sin_lut = -16'sd8423;
            8'd151: sin_lut = -16'sd8765;
            8'd152: sin_lut = -16'sd9102;
            8'd153: sin_lut = -16'sd9434;
            8'd154: sin_lut = -16'sd9760;
            8'd155: sin_lut = -16'sd10080;
            8'd156: sin_lut = -16'sd10394;
            8'd157: sin_lut = -16'sd10702;
            8'd158: sin_lut = -16'sd11003;
            8'd159: sin_lut = -16'sd11297;
            8'd160: sin_lut = -16'sd11585;
            8'd161: sin_lut = -16'sd11866;
            8'd162: sin_lut = -16'sd12140;
            8'd163: sin_lut = -16'sd12406;
            8'd164: sin_lut = -16'sd12665;
            8'd165: sin_lut = -16'sd12916;
            8'd166: sin_lut = -16'sd13160;
            8'd167: sin_lut = -16'sd13395;
            8'd168: sin_lut = -16'sd13623;
            8'd169: sin_lut = -16'sd13842;
            8'd170: sin_lut = -16'sd14053;
            8'd171: sin_lut = -16'sd14256;
            8'd172: sin_lut = -16'sd14449;
            8'd173: sin_lut = -16'sd14635;
            8'd174: sin_lut = -16'sd14811;
            8'd175: sin_lut = -16'sd14978;
            8'd176: sin_lut = -16'sd15137;
            8'd177: sin_lut = -16'sd15286;
            8'd178: sin_lut = -16'sd15426;
            8'd179: sin_lut = -16'sd15557;
            8'd180: sin_lut = -16'sd15679;
            8'd181: sin_lut = -16'sd15791;
            8'd182: sin_lut = -16'sd15893;
            8'd183: sin_lut = -16'sd15986;
            8'd184: sin_lut = -16'sd16069;
            8'd185: sin_lut = -16'sd16143;
            8'd186: sin_lut = -16'sd16207;
            8'd187: sin_lut = -16'sd16261;
            8'd188: sin_lut = -16'sd16305;
            8'd189: sin_lut = -16'sd16340;
            8'd190: sin_lut = -16'sd16364;
            8'd191: sin_lut = -16'sd16379;
            8'd192: sin_lut = -16'sd16384;
            8'd193: sin_lut = -16'sd16379;
            8'd194: sin_lut = -16'sd16364;
            8'd195: sin_lut = -16'sd16340;
            8'd196: sin_lut = -16'sd16305;
            8'd197: sin_lut = -16'sd16261;
            8'd198: sin_lut = -16'sd16207;
            8'd199: sin_lut = -16'sd16143;
            8'd200: sin_lut = -16'sd16069;
            8'd201: sin_lut = -16'sd15986;
            8'd202: sin_lut = -16'sd15893;
            8'd203: sin_lut = -16'sd15791;
            8'd204: sin_lut = -16'sd15679;
            8'd205: sin_lut = -16'sd15557;
            8'd206: sin_lut = -16'sd15426;
            8'd207: sin_lut = -16'sd15286;
            8'd208: sin_lut = -16'sd15137;
            8'd209: sin_lut = -16'sd14978;
            8'd210: sin_lut = -16'sd14811;
            8'd211: sin_lut = -16'sd14635;
            8'd212: sin_lut = -16'sd14449;
            8'd213: sin_lut = -16'sd14256;
            8'd214: sin_lut = -16'sd14053;
            8'd215: sin_lut = -16'sd13842;
            8'd216: sin_lut = -16'sd13623;
            8'd217: sin_lut = -16'sd13395;
            8'd218: sin_lut = -16'sd13160;
            8'd219: sin_lut = -16'sd12916;
            8'd220: sin_lut = -16'sd12665;
            8'd221: sin_lut = -16'sd12406;
            8'd222: sin_lut = -16'sd12140;
            8'd223: sin_lut = -16'sd11866;
            8'd224: sin_lut = -16'sd11585;
            8'd225: sin_lut = -16'sd11297;
            8'd226: sin_lut = -16'sd11003;
            8'd227: sin_lut = -16'sd10702;
            8'd228: sin_lut = -16'sd10394;
            8'd229: sin_lut = -16'sd10080;
            8'd230: sin_lut = -16'sd9760;
            8'd231: sin_lut = -16'sd9434;
            8'd232: sin_lut = -16'sd9102;
            8'd233: sin_lut = -16'sd8765;
            8'd234: sin_lut = -16'sd8423;
            8'd235: sin_lut = -16'sd8076;
            8'd236: sin_lut = -16'sd7723;
            8'd237: sin_lut = -16'sd7366;
            8'd238: sin_lut = -16'sd7005;
            8'd239: sin_lut = -16'sd6639;
            8'd240: sin_lut = -16'sd6270;
            8'd241: sin_lut = -16'sd5897;
            8'd242: sin_lut = -16'sd5520;
            8'd243: sin_lut = -16'sd5139;
            8'd244: sin_lut = -16'sd4756;
            8'd245: sin_lut = -16'sd4370;
            8'd246: sin_lut = -16'sd3981;
            8'd247: sin_lut = -16'sd3590;
            8'd248: sin_lut = -16'sd3196;
            8'd249: sin_lut = -16'sd2801;
            8'd250: sin_lut = -16'sd2404;
            8'd251: sin_lut = -16'sd2006;
            8'd252: sin_lut = -16'sd1606;
            8'd253: sin_lut = -16'sd1205;
            8'd254: sin_lut = -16'sd804;
            8'd255: sin_lut = -16'sd402;
            default: sin_lut = 16'sd0;
        endcase
    end
endfunction

// 3 级流水 + 线性插值
// 一圈 32768 = 256个表点 x 128个细分, z[6:0] 是 bin 内小数(0~127)
// s = s0 + (s1-s0)*frac/128  →  实际分辨率 = 32768 点, 误差 < 1LSB
localparam [1:0] S_IDLE = 2'd0,
                 S_PHASE = 2'd1,
                 S_OUT   = 2'd2;
reg [1:0] st;
reg        [31:0] z_r1;     // b*x+c 原始相位(Q15, 无符号)
reg [7:0]  idx_r2;
reg [6:0]  frac_r2;

// 插值组合逻辑
wire signed [15:0] s0      = sin_lut(idx_r2);
wire signed [15:0] s1      = sin_lut(idx_r2 + 8'd1);   // idx=255时落到default=0=sin(2pi), 自然wrap
wire signed [22:0] s_diff   = s1 - s0;
wire signed [30:0] s_mul    = s_diff * $signed({6'd0, frac_r2});
wire signed [15:0] s_interp = s0 + (s_mul >>> 7);

// A 无符号、s_interp 有符号，A 零扩展后相乘
wire signed [31:0] a_times_s = $signed({1'b0, A}) * s_interp;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        z_r1   <= 32'd0;
        idx_r2 <= 8'd0;
        frac_r2<= 7'd0;
        y      <= 16'sd0;
        done   <= 1'b0;
        st     <= S_IDLE;
    end else begin
        done <= 1'b0;
        case(st)
            S_IDLE: if(tick) begin
                z_r1 <= B*x + C;                          // z = b*x + c (无符号)
                st   <= S_PHASE;
            end

            S_PHASE: begin
                // z[14:0]=mod 2pi; >>7=表索引[0,255], [6:0]=bin内小数
                idx_r2  <= z_r1[14:0] >> 7;
                frac_r2 <= z_r1[6:0];
                st      <= S_OUT;
            end

            S_OUT: begin
                // y = a * 插值sin / 16384 + d
                y    <= (a_times_s >>> 14) + $signed(D);
                done <= 1'b1;
                st   <= S_IDLE;
            end

            default: st <= S_IDLE;
        endcase
    end
end

endmodule
