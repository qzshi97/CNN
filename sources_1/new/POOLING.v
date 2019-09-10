`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/03 20:30:11
// Module Name: POOLING
// Project Name: CNN
// Description: MAX POOLING
// 
//////////////////////////////////////////////////////////////////////////////////


module POOLING
#(
    parameter BUF_WIDTH     = 26,
    parameter POOLING_SIZE  = 2
)
(
    input clk,
    input rst_n,
    
    input start,
    
    input [BUF_WIDTH * POOLING_SIZE * POOLING_SIZE - 1 : 0] ifm,
    output reg [BUF_WIDTH - 1 : 0] ofm
    
    );

wire signed[BUF_WIDTH - 1 : 0]w_ifm[3:0];
reg signed [BUF_WIDTH - 1 : 0]r_ofm[1:0];
reg flag;


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        flag <= 1'b0;
    end
    else if(start)begin
        flag <= 1'b1;
    end
    else begin
        flag <= 1'b0;
    end
end


generate
    genvar i;
    for(i = 0; i < 4; i = i + 1)begin : gfi
        assign w_ifm[i] = ifm[(i + 1) * BUF_WIDTH - 1 -: BUF_WIDTH];
    end
endgenerate


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        r_ofm[1] <= {BUF_WIDTH{1'b0}};
        r_ofm[0] <= {BUF_WIDTH{1'b0}};
    end
    else if(start)begin//输入四选二，取最大的两个值
        r_ofm[0] <= w_ifm[0] > w_ifm[1] ? w_ifm[0] : w_ifm[1];
        r_ofm[1] <= w_ifm[2] > w_ifm[3] ? w_ifm[2] : w_ifm[3];
    end
    else begin
        r_ofm[0] <= r_ofm[0];
        r_ofm[1] <= r_ofm[1];
    end
end


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        ofm <= {BUF_WIDTH{1'b0}};
    end
    else if(flag)begin//输出二选一，取最大的一个值
        ofm <= r_ofm[0] > r_ofm[1] ? r_ofm[0] : r_ofm[1];
    end
    else begin
        ofm <= ofm;
    end
end

endmodule
