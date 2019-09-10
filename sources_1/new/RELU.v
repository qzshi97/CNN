`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/04 08:09:50
// Module Name: RELU
// Project Name: CNN
// Description: Relu
// 
//////////////////////////////////////////////////////////////////////////////////


module RELU
#(
    parameter BUF_WIDTH = 26,
    parameter OUT_WIDTH = 8
)
(
    input clk,
    input rst_n,
    
    input[BUF_WIDTH - 1 : 0]ifm,
    output reg[OUT_WIDTH - 1 : 0]ofm
);

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        ofm <= {OUT_WIDTH{1'b0}};
    end
    else if(ifm[BUF_WIDTH - 1])begin    //符号位为1，即负数，ofm输出0x00
        ofm <= {OUT_WIDTH{1'b0}};
    end
    else if(ifm[BUF_WIDTH - 2 : 9] < 7'h7f)begin    //不饱和输出截掉低九位并四舍五入后的结果
        ofm <= {1'b0, (ifm[15 : 9] + ifm[8])};
    end
    else begin  //饱和输出0x7f
        ofm <= 8'h7f;
    end
end

endmodule
