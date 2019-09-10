`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/04 08:20:05
// Module Name: RELU_TOP
// Project Name: CNN
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////


module RELU_TOP
#(
    parameter BUF_WIDTH = 26,
    parameter OUT_WIDTH = 8,
    parameter MAP_SIZE  = 16
)
(
    input clk,
    input rst_n,
    
    input[BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0]ifm,
    output[OUT_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0]ofm
);

generate
    genvar i, j;
    for(i = 0; i < MAP_SIZE; i = i + 1)begin : gfi
        for(j = 0; j < MAP_SIZE; j = j + 1)begin : gfj
            RELU
            #(BUF_WIDTH, OUT_WIDTH)
            RELU_INST(
                .clk(clk),
                .rst_n(rst_n),
                .ifm(ifm[(i * MAP_SIZE + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH]),
                .ofm(ofm[(i * MAP_SIZE + j + 1) * OUT_WIDTH - 1 -: OUT_WIDTH])
            );
        end
    end
endgenerate

endmodule
