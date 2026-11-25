`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 20:03:19
// Design Name: 
// Module Name: reg5_stall
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
module reg5_stall(
input clk,reset,stall,flush,input[4:0]in,output reg [4:0]out
    );
    always@(posedge clk)
        
        begin 
            if(reset|flush)out<=0;
            else if(!stall)out<=in;
        end
endmodule