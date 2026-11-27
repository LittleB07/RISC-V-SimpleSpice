`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 10:04:57
// Design Name: 
// Module Name: hazard
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


module hazard(
input [4:0]Rs1D,Rs2D,Rs1E,Rs2E,RdE,input PCsrcE,divwaitE,mulwaitE,input[1:0]resultsrcE,input [4:0]RdM,RdW,input regwriteM,regwriteW,
output stallF,stallD,stallE,flushD,flushE,output reg[1:0]forwardAE,forwardBE
    );
    //1.递进（前馈）
    always@(*)begin
            if(((Rs1E==RdM)&regwriteM)&(Rs1E!=0)) forwardAE=2'b10;
            //M阶段指令（需要写寄存器）的Rd与当前在E阶段的指令的Rs1相同，则使srcAE=ALUresultM即M阶段指令计算结果直接送到srcAE（同时发生则访存阶段优先）
            else if(((Rs1E==RdW)&regwriteW)&(Rs1E!=0)) forwardAE=2'b01;
            //W阶段指令（需要写寄存器）的Rd与当前在E阶段的指令的Rs1相同，则使srcAE=resultW即准备写回寄存器的数据直接送到srcAE
            else forwardAE=2'b00;
            //Rs2E对应srcBE，规则同上
            if(((Rs2E==RdM)&regwriteM)&(Rs2E!=0)) forwardBE=2'b10;
            else if(((Rs2E==RdW)&regwriteW)&(Rs2E!=0)) forwardBE=2'b01;
            else forwardBE=2'b00;end
    //2.停顿（lw指令直到M阶段结束才完成数据读取，但下一条指令在同一个周期（在E阶段）开始时就要用）
    wire loaduse;
    assign loaduse=(resultsrcE==2'b01)&((Rs1D==RdE)|(Rs2D==RdE))&(RdE!=0);
    //只有lw指令的resultsrcE=2'b01,由此判断lw指令;处于E阶段的lw指令将要把读取的数据写入的目标寄存器（非0）与处于D阶段的下一条指令的一个源寄存器相同
    //停顿条件：lw等待或乘除法等待，其中lw等待只需要FD停顿，乘除法等待需要FDE都停顿
    assign stallF=loaduse||divwaitE||mulwaitE;
    assign stallD=loaduse||divwaitE||mulwaitE;
    assign stallE=divwaitE||mulwaitE;
    //如果E阶段指令需要跳转，则DE都刷新，如果lw触发停顿，则只需要E刷新
    assign flushD=PCsrcE;
    assign flushE=loaduse||PCsrcE;
endmodule
