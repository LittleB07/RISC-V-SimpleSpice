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

/*
除法分解为多周期方法：
13/3:1101/0011
被除数从高到低  此时的temp={余数，q当前位}  除以除数的结果  这一步的余数（最后一步就是最终余数）
1                   01                      0               01
1                   11                      1               00
0                   00                      0               00
1                   01                      0               01
结果：0100(4),余数1
*/
module divider(input clk,reset,start,output reg busy,done,
input [31:0]quotient,divisor,output reg [31:0]result,remainder
    );//quotient被除数，divisor除数，result商，remainder余数
    reg [4:0]count;//遍历32位，每拍一位
    reg [31:0]q,d;//锁存被除数和除数，防止算一半输入变化
    wire [32:0]temp,remainder_next;
    wire r_bit;
    assign temp={remainder,q[count]};
    assign r_bit=(temp>={1'b0,d});//结果的当前位，temp≥除数d则为1，否则0
    assign remainder_next=r_bit?(temp-{1'b0,d}):temp;//temp整除了除数就减掉，temp没到除数就保留
 
    always@(posedge clk)
    if(reset)
    begin
      count<=5'd31;
      done<=0;
      busy<=0;
    end
    else begin
    done<=0;
        if(start&&(!busy))//开始计算：count从31开始递减，锁存被除数和除数，busy设为1，初始余数为0
        begin
            count<=5'd31;
            q<=quotient;
            d<=divisor;
            busy<=1;
            remainder<=0;
        end
        else if(busy)//正在计算中的每一拍：更新remainder,r_bit对应位写入结果寄存器
        begin
            remainder<=remainder_next[31:0];
            result[count]<=r_bit;
            if(count!=0)//如果没算完，count继续递减
            begin
                count<=count-1;
            end
            else begin//算完了
            done<=1;
            busy<=0;
            end
        end
    end

    
endmodule
