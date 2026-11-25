`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 10:04:57
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU(input clk,reset,output divwaitE,mulwaitE,
input [4:0]ALUcontrol,input [31:0]A,B,input [2:0]branch_src,output reg[31:0]result,output reg branch_en,input [31:0]branch_B
    );
    wire signed [63:0]signed_A,signed_B,unsigned_A,unsigned_B;
    wire [63:0]mul_ss,mul_uu,mul_su;
    wire [31:0]div_A,div_B,result_divide,remainder;
    wire sign_divide_en,divide_en,start,busy,done;
    reg divide_sign,remainder_sign;
    assign signed_A={{32{A[31]}},A};
    assign signed_B={{32{B[31]}},B};
    assign unsigned_A={32'b0,A};
    assign unsigned_B={32'b0,B};
    assign mul_ss=signed_A*signed_B;
    assign mul_uu=unsigned_A*unsigned_B;
    assign mul_su=signed_A*unsigned_B;
    assign start = divide_en && !busy && !done;
    wire is_mul;
    assign is_mul=(ALUcontrol==5'b01010)||(ALUcontrol==5'b01011)||(ALUcontrol==5'b01100)||(ALUcontrol==5'b01101);
reg  mul_ready;
    assign divwaitE=divide_en&&(!done);
    assign sign_divide_en=(ALUcontrol==5'b01110)||(ALUcontrol==5'b10000);
    assign divide_en=sign_divide_en||(ALUcontrol==5'b01111)||(ALUcontrol==5'b10001);
    assign div_A=(sign_divide_en&&A[31])?-A:A;
    assign div_B=(sign_divide_en&&B[31])?-B:B;
    wire mul_start = is_mul && !mul_ready;
    assign mulwaitE  = mul_start;
    wire [65:0]mulresult;
always @(posedge clk) begin
    if (reset)
        mul_ready <= 1'b0;
    else
        mul_ready <= mul_start;
end
    divider d(clk,reset,start,busy,done,div_A,div_B,result_divide,remainder);
    always@(*)
    begin
        
        case(ALUcontrol)
            5'b00000:result=A+B;//add
            5'b00001:result=A-B;//sub
            5'b00010:result=A&B;//and
            5'b00011:result=A|B;//or
            5'b00100:result=A^B;//xor
            5'b00101:result=A<<B[4:0];//sll逻辑左移
            5'b00110:result=A>>B[4:0];//srl逻辑右移
            5'b00111:result=$signed(A)>>>B[4:0];//sra算术右移
            5'b01000:result=($signed(A)<$signed(B));//slt set less than如果小于则置1，否则0
            5'b01001:result=A<B;//sltu set less than unsigned 无符号数比较，如果小于则置1，否则0
            5'b01010:result=mulresult[31:0];//mul乘法低位
            5'b01011:result=mulresult[63:32];//mulh有符号数乘法高位
            5'b01100:result=mulresult[63:32];//mulhsu有符号数与无符号数乘法高位
            5'b01101:result=mulresult[63:32];//mulhu无符号数乘法高位
            5'b01110:result=divide_sign?-result_divide:result_divide;//div有符号数除法，规定如果除数为0，结果为-1
            5'b01111:result=result_divide;//divu无符号数除法
            5'b10000:result=remainder_sign?-remainder:remainder;//rem有符号数取余，如果B=0则结果为A
            5'b10001:result=remainder;//remu无符号数取余
            default:result=32'b0;
        endcase
    
    end

wire a_signed = (ALUcontrol == 5'b01011) ||   // MULH
                (ALUcontrol == 5'b01100);     // MULHSU
wire b_signed = (ALUcontrol == 5'b01011);     // MULH

wire signed [16:0] a_lo = {1'b0, A[15:0]};
wire signed [16:0] b_lo = {1'b0, B[15:0]};
wire signed [16:0] a_hi = {a_signed && A[31], A[31:16]};
wire signed [16:0] b_hi = {b_signed && B[31], B[31:16]};

reg signed [33:0] p_ll, p_hl, p_lh, p_hh;

always @(posedge clk) begin
    if (mul_start) begin
        p_ll <= a_lo * b_lo;
        p_hl <= a_hi * b_lo;
        p_lh <= a_lo * b_hi;
        p_hh <= a_hi * b_hi;
    end
    //else mulresult<=p_ll+({{30{p_hl[33]}},p_hl}<<16)+({{30{p_lh[33]}},p_lh}<<16)+({{30{p_hh[33]}},p_hh}<<32);
end
assign mulresult = {30'b0, p_ll}
                 + ({{30{p_hl[33]}}, p_hl} << 16)
                 + ({{30{p_lh[33]}}, p_lh} << 16)
                 + ({{30{p_hh[33]}}, p_hh} << 32);
    always @* begin
    case (branch_src)
        3'b000: branch_en=(A == branch_B);                  // BEQ
        3'b001: branch_en=(A != branch_B);                  // BNE
        3'b100: branch_en=($signed(A) < $signed(branch_B)); // BLT
        3'b101: branch_en=($signed(A) >= $signed(branch_B));// BGE
        3'b110: branch_en=(A < branch_B);                   // BLTU
        3'b111: branch_en=(A >= branch_B);                  // BGEU
        default: branch_en= 1'b0;
    endcase
end
    always@(posedge clk)//使用原始AB在除法器锁存操作数时取符号
    if(reset)begin
    divide_sign<=0;
    remainder_sign<=0;
    end
    else if(start)begin
    divide_sign<=sign_divide_en&&(A[31]^B[31])&&(B!=0);
    remainder_sign<=sign_divide_en&&A[31];
    end
endmodule
