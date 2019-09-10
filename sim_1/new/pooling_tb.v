`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/03 22:08:44
// Module Name: pooling_tb
// Project Name: CNN
// Description: simulation
// 
//////////////////////////////////////////////////////////////////////////////////


module pooling_tb;

    parameter BUF_WIDTH     = 26;
    parameter MAP_SIZE      = 32;
    parameter STRIDE        = 2;
    parameter POOLING_SIZE  = 2;

    ///////////////clk,rst_n/////////////////////

    reg clk;
    reg rst_n;

    initial begin
        clk <= 1'b0;
        forever
            #10 clk <= ~clk;
    end

    initial begin
        rst_n <= 1'b0;
        #50;
        rst_n <= 1'b1;
    end

    ///////////////clk,rst_n/////////////////////

    reg start;

    initial begin
        start <= 1'b0;
        #150;
        start <= 1'b1;
        #20;
        start <= 1'b0;
    end
        
        
        
    reg signed[BUF_WIDTH - 1 : 0] r_ifm[MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];
    wire signed[BUF_WIDTH - 1 : 0] r_ofm[MAP_SIZE / STRIDE - 1 : 0][MAP_SIZE / STRIDE - 1 : 0];

    wire [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] ifm;
    wire [BUF_WIDTH * MAP_SIZE / STRIDE * MAP_SIZE / STRIDE - 1 : 0] ofm;

    generate
        genvar i, j;
        for(i = 0; i < MAP_SIZE; i = i + 1)begin: gf1
            for(j = 0; j < MAP_SIZE; j = j + 1)begin: gf2
                assign ifm[(i * MAP_SIZE + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH] = r_ifm[i][j];
            end
        end
        for(i = 0; i < MAP_SIZE / STRIDE; i = i + 1)begin: gf3
            for(j = 0; j < MAP_SIZE / STRIDE; j = j + 1)begin: gf4
                assign r_ofm[i][j] = ofm[(i * MAP_SIZE / STRIDE + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH];
            end
        end
    endgenerate

    reg[10:0]i1, j1;
    initial begin
        for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin
            for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                r_ifm[i1][j1] = $random%33554431;
            end
        end
    end


    POOLING_TOP
    #(
        .BUF_WIDTH(BUF_WIDTH),
        .MAP_SIZE(MAP_SIZE),
        .STRIDE(STRIDE),
        .POOLING_SIZE(POOLING_SIZE)
    )
    POOLING_TOP_INST
    (
        .clk(clk),
        .rst_n(rst_n),

        .ifm(ifm),
        .ofm(ofm),

        .start(start)
    );
    
    initial begin
        #250;
        for(i1 = 0; i1 < MAP_SIZE / STRIDE; i1 = i1 + 1)begin
            for(j1 = 0; j1 < MAP_SIZE / STRIDE; j1 = j1 + 1)begin
                if(r_ofm[i1][j1] < r_ifm[i1 * 2][j1 * 2])begin
                    $display("%d, %d : error", i1, j1);
                    #20;
                    $stop;
                end
                else if(r_ofm[i1][j1] < r_ifm[i1 * 2][j1 * 2 + 1])begin
                    $display("%d, %d : error", i1, j1);
                    #20;
                    $stop;
                end
                else if(r_ofm[i1][j1] < r_ifm[i1 * 2 + 1][j1 * 2])begin
                    $display("%d, %d : error", i1, j1);
                    #20;
                    $stop;
                end
                else if(r_ofm[i1][j1] < r_ifm[i1 * 2 + 1][j1 * 2 + 1])begin
                    $display("%d, %d : error", i1, j1);
                    #20;
                    $stop;
                end
                else begin
                    $display("%d, %d : correct", i1, j1);
                end
            end
        end
    end


endmodule
