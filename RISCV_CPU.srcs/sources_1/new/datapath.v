`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 10:04:57
// Design Name: 
// Module Name: datapath
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

module datapath(
input clk,reset,output [31:0]PCF,input [31:0]instr,output [31:0]readdata_addr,writedata,output write_en,input [31:0]readdata,output [1:0]sdsrcM
    );
    wire regwriteD,regwriteE,regwriteM,regwriteW,memwriteD,memwriteE,memwriteM,jumpD,jumpE,branchD,branchE;
    wire ALUsrcD,ALUsrcE,PCsrcE,branch_en,stallF,stallD,stallE,flushD,flushE,jalrD,jalrE,luiD,luiE,divwaitE,mulwaitE;
    wire [1:0]resultsrcD,resultsrcE,resultsrcM,resultsrcW,forwardAE,forwardBE,sdsrcD,sdsrcE;
    wire [2:0]immsrcD,rdsrcD,rdsrcE,rdsrcM,branchcontrolD,branchcontrolE;
    wire [4:0]ALUcontrolD,ALUcontrolE,Rs1D,Rs2D,RdD,Rs1E,Rs2E,RdE,RdM,RdW;
    wire [31:0]ALUresultE_set0,instrD,PC_next,PCD,PCE,immD,immE,RD1,RD2,RD1E,RD2E,srcAE,srcBE,writedataE,writedataM,ALUresultE,ALUresultM,ALUresultW;
    wire[31:0] readdataM,readdataW,PCplus4F,PCplus4D,PCplus4E,PCplus4M,PCplus4W,resultW,PCtargetE,PCtargetE_after_predict,PCtargetM,PCtargetW,PC_next_j,forward_resultM;
    wire [31:0]pred_PCtargetF,pred_PCtargetD,pred_PCtargetE;//pred_PCtargetF是BTB预测是否跳转后的目标地址
    assign Rs1D=instrD[19:15];
    assign Rs2D=instrD[24:20];
    assign RdD=instrD[11:7];
    assign writedata=writedataM;
    assign write_en=memwriteM;
    assign readdata_addr=ALUresultM;
    
    assign PCtargetE=luiE?immE:(PCE+immE);
    assign ALUresultE_set0={ALUresultE[31:1],1'b0};
    assign forward_resultM=(resultsrcM == 2'b11)?PCtargetM:(resultsrcM==2'b10)?PCplus4M:ALUresultM;
    assign PCtargetE_after_predict=(jumpE||branch_en)?PCtargetE:PCplus4E;//真正应该跳转的地址
    //assign PCsrcE=jumpE||(branchE&&(pred_PCtargetE!=PCtargetE_after_predict));用下面语句替代，以进行时序优化
    wire wrong_if_takenE;
    wire wrong_if_not_takenE;
    assign wrong_if_takenE     = (pred_PCtargetE != PCtargetE);//预测的地址不是跳转的地址则为1
    assign wrong_if_not_takenE = (pred_PCtargetE != PCplus4E);//预测的地址不是正常执行的地址则为1
    assign PCsrcE = jumpE ||(branchE && (branch_en ? wrong_if_takenE: wrong_if_not_takenE));//分支预测失败时冲刷

    //F部分取指
    reg32_stall PC(clk,reset,stallF,0,PC_next,PCF);
    mux_2 PC_mux(pred_PCtargetF,PC_next_j,PCsrcE,PC_next);
    mux_2 jal_mux(PCtargetE_after_predict,ALUresultE_set0,jalrE,PC_next_j);
    BTB btb(clk,reset,branchE,branch_en,PCE,PCtargetE,PCplus4F,PCF,pred_PCtargetF);
    //pred_PCtargetF为经过分支预测判断后的下一个PC要取的地址
    assign PCplus4F=PCF+4;
    //F与D
    reg32_stall instrFD(clk,reset,stallD,flushD,instr,instrD);
    
    reg32_stall PCFD(clk,reset,stallD,1'b0,PCF,PCD);
    reg32_stall PCplus4FD(clk,reset,stallD,1'b0,PCplus4F,PCplus4D);
    reg32_stall pred_PCtargetFD(clk,reset,stallD,1'b0,pred_PCtargetF,pred_PCtargetD);
    //D部分译码
    reg_file regf(clk,regwriteW,instrD[19:15],instrD[24:20],RdW,resultW,RD1,RD2);
    extend imm_extend(immsrcD,instrD[31:7],immD);
    control_unit control(instrD[6:0],instrD[14:12],instrD[31:25],regwriteD,resultsrcD,memwriteD,jumpD,branchD,ALUcontrolD,branchcontrolD,ALUsrcD,immsrcD,rdsrcD,sdsrcD,jalrD,luiD);
    //D与E
    reg1_stall regwriteDE(clk,reset,stallE,flushE,regwriteD,regwriteE);
    reg2_stall resultsrcDE(clk,reset,stallE,flushE,resultsrcD,resultsrcE);
    reg1_stall memwriteDE(clk,reset,stallE,flushE,memwriteD,memwriteE);
    reg3_stall rdsrcDE(clk,reset,stallE,flushE,rdsrcD,rdsrcE);
    reg2_stall sdsrcDE(clk,reset,stallE,flushE,sdsrcD,sdsrcE);
    reg1_stall jumpDE(clk,reset,stallE,flushE,jumpD,jumpE);
    reg1_stall jalrDE(clk,reset,stallE,flushE,jalrD,jalrE);
    reg1_stall branchDE(clk,reset,stallE,flushE,branchD,branchE);
    reg5_stall ALUcontrolDE(clk,reset,stallE,flushE,ALUcontrolD,ALUcontrolE);
    reg3_stall branchcontrolDE(clk,reset,stallE,flushE,branchcontrolD,branchcontrolE);
    reg1_stall ALUsrcDE(clk,reset,stallE,flushE,ALUsrcD,ALUsrcE);
    reg32_stall RD1DE(clk,reset,stallE,1'b0,RD1,RD1E);
    reg32_stall RD2DE(clk,reset,stallE,1'b0,RD2,RD2E);
    reg32_stall PCDE(clk,reset,stallE,1'b0,PCD,PCE);
    reg5_stall Rs1DE(clk,reset,stallE,flushE,Rs1D,Rs1E);
    reg5_stall Rs2DE(clk,reset,stallE,flushE,Rs2D,Rs2E);
    reg5_stall RdDE(clk,reset,stallE,flushE,RdD,RdE);
    reg32_stall immDE(clk,reset,stallE,flushE,immD,immE);
    reg32_stall PCplus4DE(clk,reset,stallE,flushE,PCplus4D,PCplus4E);
    reg1_stall luiDE(clk,reset,stallE,flushE,luiD,luiE);
    reg32_stall pred_PCtargetDE(clk,reset,stallE,flushE,pred_PCtargetD,pred_PCtargetE);
    //E部分执行
    //mux_3 srcAE_mux(RD1E,resultW,forward_resultM,forwardAE,srcAE); 用下面语句替代，以进行时序优化
    wire a_hit_m, a_hit_w;
    assign a_hit_m = regwriteM && (RdM != 5'd0) && (RdM == Rs1E);
    assign a_hit_w = regwriteW && (RdW != 5'd0) && (RdW == Rs1E);
    assign srcAE = ({32{a_hit_m}}& forward_resultM)| ({32{!a_hit_m && a_hit_w}} & resultW)
             | ({32{!a_hit_m && !a_hit_w}} & RD1E);
    //mux_3 srcBE_mux(RD2E,resultW,forward_resultM,forwardBE,writedataE);用下面语句替代，以进行时序优化
    wire b_hit_m, b_hit_w;
    assign b_hit_m = regwriteM && (RdM != 5'd0) && (RdM == Rs2E);
    assign b_hit_w = regwriteW && (RdW != 5'd0) && (RdW == Rs2E);
    assign writedataE = ({32{b_hit_m}} & forward_resultM) | ({32{!b_hit_m && b_hit_w}} & resultW)
                  | ({32{!b_hit_m && !b_hit_w}} & RD2E);
       
              
    assign srcBE=ALUsrcE?immE:writedataE;
    ALU alu(clk,reset,divwaitE,mulwaitE,ALUcontrolE,srcAE,srcBE,branchcontrolE,ALUresultE,branch_en,writedataE);
    //E与M
    reg1 regwriteEM(clk,reset,0,regwriteE&&(!(divwaitE|mulwaitE)),regwriteM);
    reg2 resultsrcEM(clk,reset,0,resultsrcE,resultsrcM);
    reg1 memwriteEM(clk,reset,0,memwriteE&&(!(divwaitE|mulwaitE)),memwriteM);
    reg3 rdsrcEM(clk,reset,0,rdsrcE,rdsrcM);
    reg2 sdsrcEM(clk,reset,0,sdsrcE,sdsrcM);
    reg32 ALUresultEM(clk,reset,0,ALUresultE,ALUresultM);
    reg32 writedataEM(clk,reset,0,writedataE,writedataM);
    reg5 RdEM(clk,reset,0,RdE,RdM);
    reg32 PCplus4EM(clk,reset,0,PCplus4E,PCplus4M);
    reg32 PCtargetEM(clk,reset,0,PCtargetE,PCtargetM);
    //M
    readdata_control rdcon(rdsrcM,readdata,ALUresultM[1:0],readdataM);
    //M与W
    reg1 regwriteMW(clk,reset,0,regwriteM,regwriteW);
    reg2 resultsrcMW(clk,reset,0,resultsrcM,resultsrcW);
    reg32 ALUresultMW(clk,reset,0,ALUresultM,ALUresultW);
    reg32 readdataMW(clk,reset,0,readdataM,readdataW);
    reg5 RdMW(clk,reset,0,RdM,RdW);
    reg32 PCplus4MW(clk,reset,0,PCplus4M,PCplus4W);
    reg32 PCtargetMW(clk,reset,0,PCtargetM,PCtargetW);
    //W
    mux4 resultmux(ALUresultW,readdataW,PCplus4W,PCtargetW,resultsrcW,resultW);
    //冲突处理单元
    hazard h(Rs1D,Rs2D,Rs1E,Rs2E,RdE,PCsrcE,divwaitE,mulwaitE,resultsrcE,RdM,RdW,regwriteM,regwriteW,stallF,stallD,stallE,flushD,flushE,forwardAE,forwardBE);
endmodule
