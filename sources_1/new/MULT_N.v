`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/01 08:32:09
// Module Name: MULT_N
// Project Name: CNN
// Description: 实现1个N位有符号数乘法器
//
//////////////////////////////////////////////////////////////////////////////////


module MULT_N
#(
    parameter DATA_WIDTH = 8
)
(
    input [DATA_WIDTH - 1 : 0] a,
    input [DATA_WIDTH - 1 : 0] b,
    output [DATA_WIDTH * 2 - 1 : 0] c
);
    
wire signed [DATA_WIDTH - 1:0] A;
wire signed [DATA_WIDTH - 1:0] B;
reg signed [DATA_WIDTH * 2 - 1:0] C;

assign A = a;
assign B = b;
assign c = C;


always@(*)begin
    C <= B * A;
end
    
endmodule
