// asin_wave.v  反正弦查表：y = A*asin(B*x + C) + D，256 点表
// z 为 Q3.13（内部 clamp 到 ±1.0），查表输出 Q4.12 弧度，4 拍后 done
module asin_wave #(
    parameter signed [15:0] A = 16'sd256,   // 幅值系数 Q8(256 = 1.0)
    parameter signed [15:0] B = 16'sd256,   // x 缩放 Q3.13
    parameter signed [15:0] C = 16'sd0,     // 相位偏移 Q3.13(0.0)
    parameter signed [15:0] D = 16'sd0      // 直流偏移(与 y 同格式)
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               tick,          // 一拍脉冲: 启动一次计算
    input  wire signed [15:0] x,             // 时间/自变量输入
    output reg  signed [15:0] y,
    output reg                done
);

// 256 点 asin 查表（Q4.12 弧度）
function signed [15:0] asin_lut;
    input [7:0] idx;
    begin
        case(idx)
            8'd0  : asin_lut = -16'sd6434;
            8'd1  : asin_lut = -16'sd5922;
            8'd2  : asin_lut = -16'sd5709;
            8'd3  : asin_lut = -16'sd5545;
            8'd4  : asin_lut = -16'sd5407;
            8'd5  : asin_lut = -16'sd5285;
            8'd6  : asin_lut = -16'sd5175;
            8'd7  : asin_lut = -16'sd5073;
            8'd8  : asin_lut = -16'sd4978;
            8'd9  : asin_lut = -16'sd4889;
            8'd10 : asin_lut = -16'sd4804;
            8'd11 : asin_lut = -16'sd4723;
            8'd12 : asin_lut = -16'sd4646;
            8'd13 : asin_lut = -16'sd4572;
            8'd14 : asin_lut = -16'sd4500;
            8'd15 : asin_lut = -16'sd4431;
            8'd16 : asin_lut = -16'sd4364;
            8'd17 : asin_lut = -16'sd4299;
            8'd18 : asin_lut = -16'sd4235;
            8'd19 : asin_lut = -16'sd4174;
            8'd20 : asin_lut = -16'sd4113;
            8'd21 : asin_lut = -16'sd4054;
            8'd22 : asin_lut = -16'sd3997;
            8'd23 : asin_lut = -16'sd3940;
            8'd24 : asin_lut = -16'sd3885;
            8'd25 : asin_lut = -16'sd3830;
            8'd26 : asin_lut = -16'sd3777;
            8'd27 : asin_lut = -16'sd3724;
            8'd28 : asin_lut = -16'sd3673;
            8'd29 : asin_lut = -16'sd3622;
            8'd30 : asin_lut = -16'sd3572;
            8'd31 : asin_lut = -16'sd3522;
            8'd32 : asin_lut = -16'sd3474;
            8'd33 : asin_lut = -16'sd3426;
            8'd34 : asin_lut = -16'sd3378;
            8'd35 : asin_lut = -16'sd3331;
            8'd36 : asin_lut = -16'sd3285;
            8'd37 : asin_lut = -16'sd3239;
            8'd38 : asin_lut = -16'sd3194;
            8'd39 : asin_lut = -16'sd3149;
            8'd40 : asin_lut = -16'sd3105;
            8'd41 : asin_lut = -16'sd3061;
            8'd42 : asin_lut = -16'sd3018;
            8'd43 : asin_lut = -16'sd2975;
            8'd44 : asin_lut = -16'sd2932;
            8'd45 : asin_lut = -16'sd2890;
            8'd46 : asin_lut = -16'sd2848;
            8'd47 : asin_lut = -16'sd2806;
            8'd48 : asin_lut = -16'sd2765;
            8'd49 : asin_lut = -16'sd2725;
            8'd50 : asin_lut = -16'sd2684;
            8'd51 : asin_lut = -16'sd2644;
            8'd52 : asin_lut = -16'sd2604;
            8'd53 : asin_lut = -16'sd2564;
            8'd54 : asin_lut = -16'sd2525;
            8'd55 : asin_lut = -16'sd2486;
            8'd56 : asin_lut = -16'sd2447;
            8'd57 : asin_lut = -16'sd2408;
            8'd58 : asin_lut = -16'sd2370;
            8'd59 : asin_lut = -16'sd2332;
            8'd60 : asin_lut = -16'sd2294;
            8'd61 : asin_lut = -16'sd2256;
            8'd62 : asin_lut = -16'sd2219;
            8'd63 : asin_lut = -16'sd2182;
            8'd64 : asin_lut = -16'sd2145;
            8'd65 : asin_lut = -16'sd2108;
            8'd66 : asin_lut = -16'sd2071;
            8'd67 : asin_lut = -16'sd2035;
            8'd68 : asin_lut = -16'sd1998;
            8'd69 : asin_lut = -16'sd1962;
            8'd70 : asin_lut = -16'sd1926;
            8'd71 : asin_lut = -16'sd1890;
            8'd72 : asin_lut = -16'sd1855;
            8'd73 : asin_lut = -16'sd1819;
            8'd74 : asin_lut = -16'sd1784;
            8'd75 : asin_lut = -16'sd1749;
            8'd76 : asin_lut = -16'sd1714;
            8'd77 : asin_lut = -16'sd1679;
            8'd78 : asin_lut = -16'sd1644;
            8'd79 : asin_lut = -16'sd1609;
            8'd80 : asin_lut = -16'sd1574;
            8'd81 : asin_lut = -16'sd1540;
            8'd82 : asin_lut = -16'sd1506;
            8'd83 : asin_lut = -16'sd1471;
            8'd84 : asin_lut = -16'sd1437;
            8'd85 : asin_lut = -16'sd1403;
            8'd86 : asin_lut = -16'sd1369;
            8'd87 : asin_lut = -16'sd1336;
            8'd88 : asin_lut = -16'sd1302;
            8'd89 : asin_lut = -16'sd1268;
            8'd90 : asin_lut = -16'sd1235;
            8'd91 : asin_lut = -16'sd1201;
            8'd92 : asin_lut = -16'sd1168;
            8'd93 : asin_lut = -16'sd1134;
            8'd94 : asin_lut = -16'sd1101;
            8'd95 : asin_lut = -16'sd1068;
            8'd96 : asin_lut = -16'sd1035;
            8'd97 : asin_lut = -16'sd1002;
            8'd98 : asin_lut = -16'sd969;
            8'd99 : asin_lut = -16'sd936;
            8'd100: asin_lut = -16'sd903;
            8'd101: asin_lut = -16'sd871;
            8'd102: asin_lut = -16'sd838;
            8'd103: asin_lut = -16'sd805;
            8'd104: asin_lut = -16'sd773;
            8'd105: asin_lut = -16'sd740;
            8'd106: asin_lut = -16'sd708;
            8'd107: asin_lut = -16'sd675;
            8'd108: asin_lut = -16'sd643;
            8'd109: asin_lut = -16'sd610;
            8'd110: asin_lut = -16'sd578;
            8'd111: asin_lut = -16'sd546;
            8'd112: asin_lut = -16'sd513;
            8'd113: asin_lut = -16'sd481;
            8'd114: asin_lut = -16'sd449;
            8'd115: asin_lut = -16'sd417;
            8'd116: asin_lut = -16'sd385;
            8'd117: asin_lut = -16'sd352;
            8'd118: asin_lut = -16'sd320;
            8'd119: asin_lut = -16'sd288;
            8'd120: asin_lut = -16'sd256;
            8'd121: asin_lut = -16'sd224;
            8'd122: asin_lut = -16'sd192;
            8'd123: asin_lut = -16'sd160;
            8'd124: asin_lut = -16'sd128;
            8'd125: asin_lut = -16'sd96;
            8'd126: asin_lut = -16'sd64;
            8'd127: asin_lut = -16'sd32;
            8'd128: asin_lut = 16'sd0;
            8'd129: asin_lut = 16'sd32;
            8'd130: asin_lut = 16'sd64;
            8'd131: asin_lut = 16'sd96;
            8'd132: asin_lut = 16'sd128;
            8'd133: asin_lut = 16'sd160;
            8'd134: asin_lut = 16'sd192;
            8'd135: asin_lut = 16'sd224;
            8'd136: asin_lut = 16'sd256;
            8'd137: asin_lut = 16'sd288;
            8'd138: asin_lut = 16'sd320;
            8'd139: asin_lut = 16'sd352;
            8'd140: asin_lut = 16'sd385;
            8'd141: asin_lut = 16'sd417;
            8'd142: asin_lut = 16'sd449;
            8'd143: asin_lut = 16'sd481;
            8'd144: asin_lut = 16'sd513;
            8'd145: asin_lut = 16'sd546;
            8'd146: asin_lut = 16'sd578;
            8'd147: asin_lut = 16'sd610;
            8'd148: asin_lut = 16'sd643;
            8'd149: asin_lut = 16'sd675;
            8'd150: asin_lut = 16'sd708;
            8'd151: asin_lut = 16'sd740;
            8'd152: asin_lut = 16'sd773;
            8'd153: asin_lut = 16'sd805;
            8'd154: asin_lut = 16'sd838;
            8'd155: asin_lut = 16'sd871;
            8'd156: asin_lut = 16'sd903;
            8'd157: asin_lut = 16'sd936;
            8'd158: asin_lut = 16'sd969;
            8'd159: asin_lut = 16'sd1002;
            8'd160: asin_lut = 16'sd1035;
            8'd161: asin_lut = 16'sd1068;
            8'd162: asin_lut = 16'sd1101;
            8'd163: asin_lut = 16'sd1134;
            8'd164: asin_lut = 16'sd1168;
            8'd165: asin_lut = 16'sd1201;
            8'd166: asin_lut = 16'sd1235;
            8'd167: asin_lut = 16'sd1268;
            8'd168: asin_lut = 16'sd1302;
            8'd169: asin_lut = 16'sd1336;
            8'd170: asin_lut = 16'sd1369;
            8'd171: asin_lut = 16'sd1403;
            8'd172: asin_lut = 16'sd1437;
            8'd173: asin_lut = 16'sd1471;
            8'd174: asin_lut = 16'sd1506;
            8'd175: asin_lut = 16'sd1540;
            8'd176: asin_lut = 16'sd1574;
            8'd177: asin_lut = 16'sd1609;
            8'd178: asin_lut = 16'sd1644;
            8'd179: asin_lut = 16'sd1679;
            8'd180: asin_lut = 16'sd1714;
            8'd181: asin_lut = 16'sd1749;
            8'd182: asin_lut = 16'sd1784;
            8'd183: asin_lut = 16'sd1819;
            8'd184: asin_lut = 16'sd1855;
            8'd185: asin_lut = 16'sd1890;
            8'd186: asin_lut = 16'sd1926;
            8'd187: asin_lut = 16'sd1962;
            8'd188: asin_lut = 16'sd1998;
            8'd189: asin_lut = 16'sd2035;
            8'd190: asin_lut = 16'sd2071;
            8'd191: asin_lut = 16'sd2108;
            8'd192: asin_lut = 16'sd2145;
            8'd193: asin_lut = 16'sd2182;
            8'd194: asin_lut = 16'sd2219;
            8'd195: asin_lut = 16'sd2256;
            8'd196: asin_lut = 16'sd2294;
            8'd197: asin_lut = 16'sd2332;
            8'd198: asin_lut = 16'sd2370;
            8'd199: asin_lut = 16'sd2408;
            8'd200: asin_lut = 16'sd2447;
            8'd201: asin_lut = 16'sd2486;
            8'd202: asin_lut = 16'sd2525;
            8'd203: asin_lut = 16'sd2564;
            8'd204: asin_lut = 16'sd2604;
            8'd205: asin_lut = 16'sd2644;
            8'd206: asin_lut = 16'sd2684;
            8'd207: asin_lut = 16'sd2725;
            8'd208: asin_lut = 16'sd2765;
            8'd209: asin_lut = 16'sd2806;
            8'd210: asin_lut = 16'sd2848;
            8'd211: asin_lut = 16'sd2890;
            8'd212: asin_lut = 16'sd2932;
            8'd213: asin_lut = 16'sd2975;
            8'd214: asin_lut = 16'sd3018;
            8'd215: asin_lut = 16'sd3061;
            8'd216: asin_lut = 16'sd3105;
            8'd217: asin_lut = 16'sd3149;
            8'd218: asin_lut = 16'sd3194;
            8'd219: asin_lut = 16'sd3239;
            8'd220: asin_lut = 16'sd3285;
            8'd221: asin_lut = 16'sd3331;
            8'd222: asin_lut = 16'sd3378;
            8'd223: asin_lut = 16'sd3426;
            8'd224: asin_lut = 16'sd3474;
            8'd225: asin_lut = 16'sd3522;
            8'd226: asin_lut = 16'sd3572;
            8'd227: asin_lut = 16'sd3622;
            8'd228: asin_lut = 16'sd3673;
            8'd229: asin_lut = 16'sd3724;
            8'd230: asin_lut = 16'sd3777;
            8'd231: asin_lut = 16'sd3830;
            8'd232: asin_lut = 16'sd3885;
            8'd233: asin_lut = 16'sd3940;
            8'd234: asin_lut = 16'sd3997;
            8'd235: asin_lut = 16'sd4054;
            8'd236: asin_lut = 16'sd4113;
            8'd237: asin_lut = 16'sd4174;
            8'd238: asin_lut = 16'sd4235;
            8'd239: asin_lut = 16'sd4299;
            8'd240: asin_lut = 16'sd4364;
            8'd241: asin_lut = 16'sd4431;
            8'd242: asin_lut = 16'sd4500;
            8'd243: asin_lut = 16'sd4572;
            8'd244: asin_lut = 16'sd4646;
            8'd245: asin_lut = 16'sd4723;
            8'd246: asin_lut = 16'sd4804;
            8'd247: asin_lut = 16'sd4889;
            8'd248: asin_lut = 16'sd4978;
            8'd249: asin_lut = 16'sd5073;
            8'd250: asin_lut = 16'sd5175;
            8'd251: asin_lut = 16'sd5285;
            8'd252: asin_lut = 16'sd5407;
            8'd253: asin_lut = 16'sd5545;
            8'd254: asin_lut = 16'sd5709;
            8'd255: asin_lut = 16'sd5922;
            default: asin_lut = 16'sd0;
        endcase
    end
endfunction

// 4 级流水
localparam [1:0] S_IDLE = 2'd0,
                 S_MUL  = 2'd1,
                 S_CLP  = 2'd2,
                 S_OUT  = 2'd3;
reg [1:0] st;
reg signed [31:0] z_r1;     // b*x+c 原始结果
reg signed [15:0] z_r2;     // clamp 后
reg [7:0] idx_r2;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        z_r1   <= 32'sd0;
        z_r2   <= 16'sd0;
        idx_r2 <= 8'd0;
        y      <= 16'sd0;
        done   <= 1'b0;
        st     <= S_IDLE;
    end else begin
        done <= 1'b0;
        case(st)
            S_IDLE: if(tick) begin
                z_r1 <= $signed(B)*$signed(x) + $signed(C);  // z = b*x + c
                st   <= S_MUL;
            end

            S_MUL: begin
                // clamp z 到 [-1.0, +1.0] = [-8191, +8191](Q3.13)
                if(z_r1 >  32'sd8191)      z_r2 <=  16'sd8191;
                else if(z_r1 < -32'sd8191) z_r2 <= -16'sd8191;
                else                       z_r2 <= z_r1[15:0];
                st <= S_CLP;
            end

            S_CLP: begin
                // z in [-8191,+8191] 映射到索引 [0,255]
                // idx = (z + 8192) >> 6
                idx_r2 <= (z_r2 + 16'sd8192) >>> 6;
                st     <= S_OUT;
            end

            S_OUT: begin
                // y = (a * asin_lut(idx)) >> 16 + d
                y    <= ($signed(A)*asin_lut(idx_r2) >>> 16) + $signed(D);
                done <= 1'b1;
                st   <= S_IDLE;
            end

            default: st <= S_IDLE;
        endcase
    end
end

endmodule
