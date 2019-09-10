`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/01 17:37:56
// Module Name: conv_tb
// Project Name: CNN
// Description: simulation
// 
//////////////////////////////////////////////////////////////////////////////////


module conv_tb;
    
    parameter DATA_WIDTH    = 8;
    parameter BUF_WIDTH     = 26;
    parameter MAP_SIZE      = 32;
    parameter PADDING       = 1;
    parameter KERNEL_SIZE   = 3;
    
    ///////////////clk,rst_n/////////////////////

    reg clk;
    reg rst_n;

    initial begin
        clk <= 1'b0;
        forever
            #10 clk = ~clk;
    end

    initial begin
        rst_n <= 1'b0;
        #50;
        rst_n <= 1'b1;
    end

    ///////////////clk,rst_n/////////////////////
    


    ///////////////control/////////////////////
    
    reg start;
    wire idle;
    wire finish;

    initial begin
        start <= 1'b0;
        #150;
        start <= 1'b1;
        #20;
        start <= 1'b0;
    end
    
    ///////////////control/////////////////////



    wire [DATA_WIDTH * (MAP_SIZE + PADDING * 2) * (MAP_SIZE + PADDING * 2) - 1 : 0] ifm;
    wire [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel;
    wire [DATA_WIDTH * 2 - 1 : 0] bias;
    wire [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] ofm;

    reg signed[DATA_WIDTH - 1 : 0] r_ifm [MAP_SIZE + PADDING * 2 - 1 : 0][MAP_SIZE + PADDING * 2 - 1 : 0];
    reg signed[DATA_WIDTH - 1 : 0] r_kernel [KERNEL_SIZE - 1 : 0][KERNEL_SIZE - 1 : 0];
    reg signed[DATA_WIDTH * 2 - 1 : 0] r_bias;
    wire signed [BUF_WIDTH - 1 : 0] r_ofm [MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];


    generate
        genvar i, j;
        for(i = 0; i < MAP_SIZE + PADDING * 2; i = i + 1)begin: gf1
            for(j = 0; j < MAP_SIZE + PADDING * 2; j = j + 1)begin: gf2
                assign ifm[(((MAP_SIZE + PADDING * 2) * i) + j + 1) * DATA_WIDTH - 1 -: DATA_WIDTH] = r_ifm[i][j];
            end
        end
        
        for(i = 0; i < MAP_SIZE; i = i + 1)begin: gf3
            for(j = 0; j < MAP_SIZE; j = j + 1)begin: gf4
                assign r_ofm[i][j] = ofm[(MAP_SIZE * i + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH];
            end
        end
        
        for(i = 0; i < KERNEL_SIZE; i = i + 1)begin: gfwi
            for(j = 0; j < KERNEL_SIZE; j = j + 1)begin: gfwj
                assign kernel[(KERNEL_SIZE * i + j + 1) * DATA_WIDTH - 1 -: DATA_WIDTH] = r_kernel[i][j];
            end
        end
        assign bias = r_bias;
    endgenerate



    reg[10:0]i1, j1, i2, j2;
    initial begin
        for(i1 = 0; i1 < PADDING; i1 = i1 + 1)begin
            for(j1 = 0; j1 < MAP_SIZE + PADDING * 2; j1 = j1 + 1)begin
                r_ifm[i1][j1] <= 8'b0;
            end
        end
        
        for(i1 = PADDING; i1 < MAP_SIZE + PADDING; i1 = i1 + 1)begin
            for(j1 = 0; j1 < PADDING; j1 = j1 + 1)begin
                r_ifm[i1][j1] <= 8'b0;
            end
            for(j1 = PADDING; j1 < MAP_SIZE + PADDING; j1 = j1 + 1)begin
                r_ifm[i1][j1] <= $random%127;
            end
            for(j1 = MAP_SIZE + PADDING; j1 < MAP_SIZE + PADDING * 2; j1 = j1 + 1)begin
                r_ifm[i1][j1] <= 8'b0;
            end
        end
        
        for(i1 = MAP_SIZE + PADDING; i1 < MAP_SIZE + PADDING * 2; i1 = i1 + 1)begin
            for(j1 = 0; j1 < MAP_SIZE + PADDING * 2; j1 = j1 + 1)begin
                r_ifm[i1][j1] <= 8'b0;
            end
        end
    end
    
    initial begin
        for(i1 = 0; i1 < KERNEL_SIZE; i1 = i1 + 1)begin
            for(j1 = 0; j1 < KERNEL_SIZE; j1 = j1 + 1)begin
                r_kernel[i1][j1] <= $random%127;
            end
        end
    end
    
    initial begin
        r_bias <= $random%32767;
    end


    CONV_64
    #(
        .DATA_WIDTH(8),
        .BUF_WIDTH(26),
        .MAP_SIZE(32),
        .PADDING(1),
        .KERNEL_SIZE(3)
    )
    CONV_64_inst
    (
        .clk(clk),
        .rst_n(rst_n),
        .ifm(ifm),
        .kernel(kernel),
        .bias(bias),
        .ofm(ofm),
        .start(start),
        .idle(idle),
        .finish(finish)
    );
    
    reg signed[31:0]t;
    
    always@(*) begin
        if(finish)begin
            for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin
                for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                    t = r_bias;
                    for(i2 = 0; i2 < KERNEL_SIZE; i2 = i2 + 1)begin
                        for(j2 = 0; j2 < KERNEL_SIZE; j2 = j2 + 1)begin
                            t = t + r_ifm[i1 + i2][j1 + j2] * r_kernel[i2][j2];
                        end
                    end
                    if(t != r_ofm[i1][j1])begin
                        $display("i = %d, j = %d, t = %h, ofm = %h : error", i1, j1, t, r_ofm[i1][j1]);
                        #20;
                        $stop;
                    end
                    else begin
                        $display("i = %d, j = %d, t = %h, ofm = %h : correct", i1, j1, t, r_ofm[i1][j1]);
                    end
                end
            end
            #20;
            $stop;
        end
    end
    

endmodule
