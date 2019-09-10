`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/01 07:26:37
// Module Name: MULT
// Project Name: CNN
// Description: 实现X*X个N位有符号数乘法器
//
//////////////////////////////////////////////////////////////////////////////////


module MULT
#(
    parameter DATA_WIDTH    = 8,
    parameter MAP_SIZE      = 32
)
(
    input [MAP_SIZE * MAP_SIZE * DATA_WIDTH - 1 : 0] A,
    input [MAP_SIZE * MAP_SIZE * DATA_WIDTH - 1 : 0] B,
    output [MAP_SIZE * MAP_SIZE * DATA_WIDTH * 2 - 1 : 0] C
);

wire signed [DATA_WIDTH - 1 : 0] MAP_A [MAP_SIZE * MAP_SIZE - 1 : 0];
wire signed [DATA_WIDTH - 1 : 0] MAP_B [MAP_SIZE * MAP_SIZE - 1 : 0];
wire signed [DATA_WIDTH * 2 - 1 : 0] MAP_C [MAP_SIZE * MAP_SIZE - 1 : 0];


//一维矩阵转二维存储器格式
generate 
    genvar	i;	
    for(i = 0; i < MAP_SIZE * MAP_SIZE; i = i + 1)begin: gfi						
        assign MAP_A[i] = A[(i + 1) * DATA_WIDTH - 1 -: DATA_WIDTH];
        assign MAP_B[i] = B[(i + 1) * DATA_WIDTH - 1 -: DATA_WIDTH];
        assign C[(i + 1) * DATA_WIDTH * 2 - 1 -: DATA_WIDTH * 2] = MAP_C[i];
    end
endgenerate


//例化1024个乘法器
generate 
    genvar j;	
    for(j = 0; j < MAP_SIZE * MAP_SIZE; j = j + 1)begin: gfj						
        MULT_N #(DATA_WIDTH)
        MULT_N_INST(
        .a(MAP_A[j]),
        .b(MAP_B[j]),
        .c(MAP_C[j])
        );
    end
endgenerate

endmodule
