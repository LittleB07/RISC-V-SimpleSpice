`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 09:33:07
// Design Name: 
// Module Name: BTB
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

//一共64个位置，根据指令地址PC[7:2]来定位这64个位置
module BTB(
input clk,reset,branch,branch_en,//从E阶段传回来，branch表示是跳转指令，branch_en表示实际是否跳转
input [31:0]PC,PCtarget_in,PCplus4F,PCF,
//PC,PCtarget_in是EX阶段传回来写表的，PC是指令的PC中地址，PCtarget_in是要跳转的地址
//PCF及其plus4是IF阶段进来查表的
output [31:0]PCtarget//预测判断（跳/不跳）后的目标位置
    );
    reg [31:0]RAM[0:63];//64个，每个32位，存不同指令的PC
    reg [23:0]tag[0:63];//存指令的PC的31~8位（即7:2以上的部分），用于确保指令的准确匹配
    reg [63:0]valid;//标定64个位置分别是否有有效信息
    reg [1:0]counter[0:63];//标定64个位置的指令的预测情况，00，01不跳，10，11跳
always@(posedge clk)
begin
    if(reset)
    begin
        valid<=0;
    end
    else if(branch)begin//发现E阶段的分支指令，写入指令PC并更新相应位置counter
    RAM[PC[7:2]]<=PCtarget_in;
    tag[PC[7:2]]<=PC[31:8];
    valid[PC[7:2]]<=1;
    if(!valid[PC[7:2]]||tag[PC[7:2]]!=PC[31:8])counter[PC[7:2]]<=branch_en?2'b10:2'b01;//此处没有有效数据，或者当前位置的数据是其他指令（tag不同）的，如果跳就是10否则01
    else if(branch_en&&(counter[PC[7:2]]!=2'b11))counter[PC[7:2]]<=counter[PC[7:2]]+2'b01;//跳，而且不是11，就+1
    else if((!branch)&&(counter[PC[7:2]]!=2'b00))counter[PC[7:2]]<=counter[PC[7:2]]-2'b01;//不跳，而且不是00，就-1
    end
end
assign PCtarget=valid[PCF[7:2]]&&(tag[PCF[7:2]]==PCF[31:8])&&counter[PCF[7:2]][1]?RAM[PCF[7:2]]:PCplus4F;
//当前目标有效+tag匹配+counter[1]位为1，则判断跳（目标地址是RAM[PCF[7:2]]），否则不跳，下一步是正常的PCplus4F,PCtarget为跳/不跳判断后的最终目标地址
endmodule
