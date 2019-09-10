`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/01 09:35:12
// Module Name: mult_tb
// Project Name: CNN
// Description: simulation
// 
//////////////////////////////////////////////////////////////////////////////////


module mult_tb;

    parameter DATA_WIDTH    = 8;
    parameter MAP_SIZE      = 32;


    reg signed[DATA_WIDTH - 1 : 0] r_A[MAP_SIZE * MAP_SIZE - 1 : 0];
    reg signed[DATA_WIDTH - 1 : 0] r_B[MAP_SIZE * MAP_SIZE - 1 : 0];
    wire signed[2 * DATA_WIDTH - 1 : 0] r_C[MAP_SIZE * MAP_SIZE - 1 : 0];

    wire [MAP_SIZE * MAP_SIZE * DATA_WIDTH - 1 : 0] A;
    wire [MAP_SIZE * MAP_SIZE * DATA_WIDTH - 1 : 0] B;
    wire [MAP_SIZE * MAP_SIZE * DATA_WIDTH * 2 - 1 : 0] C;

    

    generate
        genvar i;
        for(i = 0; i < MAP_SIZE * MAP_SIZE; i = i + 1)begin: gf1
            assign A[(i + 1) * DATA_WIDTH - 1 -: DATA_WIDTH] = r_A[i];
        end
        for(i = 0; i < MAP_SIZE * MAP_SIZE; i = i + 1)begin: gf2
            assign B[(i + 1) * DATA_WIDTH - 1 -: DATA_WIDTH] = r_B[i];
        end
        for(i = 0; i < MAP_SIZE * MAP_SIZE; i = i + 1)begin: gf3
            assign r_C[i] = C[(i + 1) * DATA_WIDTH * 2 - 1 -: DATA_WIDTH * 2];
        end
    endgenerate

    reg[10:0]j;

    initial begin
        for(j = 0; j < MAP_SIZE * MAP_SIZE; j = j + 1)begin
            r_A[j] <= $random%127;
        end
    end


    initial begin
        for(j = 0; j < MAP_SIZE * MAP_SIZE; j = j + 1)begin
            r_B[j] <= $random%127;
        end
    end

        
    MULT
    #(DATA_WIDTH, MAP_SIZE)
    MULT_inst(
        A,
        B,
        C
    );

    initial begin
        #100;
        for(j = 0; j < MAP_SIZE * MAP_SIZE; j = j + 1)begin
            if(r_A[j] * r_B[j] != r_C[j])begin
                $display("%d : error", j);
                #20;
                $stop;
            end
            else begin
                $display("%d : correct", j);
            end
        end
    end
endmodule
