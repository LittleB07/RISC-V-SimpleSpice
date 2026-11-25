`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 17:18:03
// Design Name: 
// Module Name: divider
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


module divider(input clk,reset,start,output reg busy,done,
input [31:0]quotient,divisor,output reg [31:0]result,remainder
    );
    reg [4:0]count;
    reg [31:0]q,d;
    wire [32:0]temp,remainder_next;
    wire r_bit;
    assign temp={remainder,q[count]};
    assign r_bit=(temp>={1'b0,d});
    assign remainder_next=r_bit?(temp-{1'b0,d}):temp;
 
    always@(posedge clk)
    if(reset)
    begin
      count<=5'd31;
      done<=0;
      busy<=0;
    end
    else begin
    done<=0;
        if(start&&(!busy))
        begin
            count<=5'd31;
            q<=quotient;
            d<=divisor;
            busy<=1;
            remainder<=0;
        end
        else if(busy)
        begin
            remainder<=remainder_next[31:0];
            result[count]<=r_bit;
            if(count!=0)
            begin
                count<=count-1;
            end
            else begin
            done<=1;
            busy<=0;
            end
        end
    end

    
endmodule
