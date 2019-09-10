`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/03 21:40:46
// Module Name: POOLING_TOP
// Project Name: CNN
// Description: max pooling
// 
//////////////////////////////////////////////////////////////////////////////////


module POOLING_TOP
#(
    parameter BUF_WIDTH     = 26,
    parameter MAP_SIZE      = 32,
    parameter STRIDE        = 2,
    parameter POOLING_SIZE  = 2
)
(
    input clk,
    input rst_n,

    input [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] ifm,
    output [BUF_WIDTH * MAP_SIZE / STRIDE * MAP_SIZE / STRIDE - 1 : 0] ofm,

    input start
    );
    
generate
    genvar i, j;
    for(i = 0; i < MAP_SIZE / STRIDE; i = i + 1)begin : gfi
        for(j = 0; j < MAP_SIZE / STRIDE; j = j + 1)begin : gfj
            POOLING
            #(BUF_WIDTH, POOLING_SIZE)
            POOLING_INST(
                .clk(clk),
                .rst_n(rst_n),
                .start(start),
                .ifm({{ifm[(i * MAP_SIZE + j + 1) * 2 * BUF_WIDTH - 1 -: BUF_WIDTH * 2]}, {ifm[(((i * MAP_SIZE + j + 1) * 2) + MAP_SIZE) * BUF_WIDTH - 1 -: BUF_WIDTH * 2]}}),
                .ofm(ofm[(i * MAP_SIZE / 2 + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH])
            );
        end
    end
endgenerate

endmodule
