`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 20:02:01
// Design Name: 
// Module Name: reg1_stall
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
module reg1_stall(
input clk,reset,stall,flush,input in,output reg out
    );
    always@(posedge clk)
        
        begin 
            if(reset|flush)out<=0;
            else if(!stall)out<=in;
        end
endmodule