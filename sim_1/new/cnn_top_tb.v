`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/05 15:28:08
// Module Name: cnn_top_tb
// Project Name: CNN
// Description: simulation
// 
//////////////////////////////////////////////////////////////////////////////////


module cnn_top_tb;

    parameter DATA_WIDTH    = 8;
    parameter BUF_WIDTH     = 26;
    parameter MAP_SIZE      = 32;
    parameter PADDING       = 1;
    parameter KERNEL_SIZE   = 3;
    parameter STRIDE        = 2;
    parameter POOLING_SIZE  = 2;

    reg[10:0]i1, j1, k1, i2, j2, k2;
    
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
    
    
    
    
    /////////////////ifm_mem/////////////////////

    wire ifm_rd;
    wire [8:0] ifm_addr;
    reg[DATA_WIDTH * MAP_SIZE * MAP_SIZE / 8 - 1:0] ifm_readdata;
    reg[DATA_WIDTH * MAP_SIZE * MAP_SIZE / 8 - 1:0] mem_ifm[511:0];
    
    reg signed[DATA_WIDTH - 1 : 0]r_ifm[63 : 0][MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];
    reg signed[DATA_WIDTH - 1 : 0]r_ifm2[63 : 0][MAP_SIZE + PADDING * 2 - 1 : 0][MAP_SIZE + PADDING * 2 - 1 : 0];
    
    
    initial begin
        for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
            for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin
                for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                    r_ifm[k1][i1][j1] = $random%127;
                end
            end
        end
        for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
            for(i1 = 0; i1 < MAP_SIZE / 4; i1 = i1 + 1)begin
                for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                    for(i2 = 0; i2 < 4; i2 = i2 + 1)begin
                        mem_ifm[k1 * 8 + i1][(j1 + 1) * DATA_WIDTH + i2 * 256 - 1 -: DATA_WIDTH] = r_ifm[k1][i1 * 4 + i2][j1];
                    end
                end
            end
        end
        for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
            for(i1 = 0; i1 < MAP_SIZE + PADDING * 2; i1 = i1 + 1)begin
                for(j1 = 0; j1 < MAP_SIZE + PADDING * 2; j1 = j1 + 1)begin
                    r_ifm2[k1][i1][j1] = 8'd0;
                end
            end
        end
        for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
            for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin
                for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                    r_ifm2[k1][i1 + 1][j1 + 1] = r_ifm[k1][i1][j1];
                end
            end
        end
    end
    
    
    always @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            ifm_readdata <= {DATA_WIDTH * MAP_SIZE * MAP_SIZE / 8{1'b0}};
        end
        else if(ifm_rd)begin
            ifm_readdata <= mem_ifm[ifm_addr];
        end
        else begin
            ifm_readdata <= ifm_readdata;
        end
    end
    
    /////////////////ifm_mem/////////////////////
    
    
    /////////////////kernel_mem/////////////////////

    wire kernel_rd;
    wire [11:0] kernel_addr;
    reg[DATA_WIDTH * 2 * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel_readdata;
    reg[DATA_WIDTH * 2 * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] mem_kernel[4095:0];
    reg signed[DATA_WIDTH - 1 : 0]r_kernel[127 : 0][63 : 0][KERNEL_SIZE - 1 : 0][KERNEL_SIZE - 1 : 0];
    
    
    initial begin
        for(k1 = 0; k1 < 128; k1 = k1 + 1)begin
            for(k2 = 0; k2 < 64; k2 = k2 + 1)begin
                for(i1 = 0; i1 < KERNEL_SIZE; i1 = i1 + 1)begin
                    for(j1 = 0; j1 < KERNEL_SIZE; j1 = j1 + 1)begin
                        r_kernel[k1][k2][i1][j1] = $random%127;
                    end
                end
            end
        end
        for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
            for(k2 = 0; k2 < 64; k2 = k2 + 1)begin
                mem_kernel[k1 * 64 + k2] = {
                r_kernel[k1 * 2 + 1][k2][2][2],
                r_kernel[k1 * 2 + 1][k2][2][1],
                r_kernel[k1 * 2 + 1][k2][2][0],
                r_kernel[k1 * 2 + 1][k2][1][2],
                r_kernel[k1 * 2 + 1][k2][1][1],
                r_kernel[k1 * 2 + 1][k2][1][0],
                r_kernel[k1 * 2 + 1][k2][0][2],
                r_kernel[k1 * 2 + 1][k2][0][1],
                r_kernel[k1 * 2 + 1][k2][0][0],
                r_kernel[k1 * 2][k2][2][2],
                r_kernel[k1 * 2][k2][2][1],
                r_kernel[k1 * 2][k2][2][0],
                r_kernel[k1 * 2][k2][1][2],
                r_kernel[k1 * 2][k2][1][1],
                r_kernel[k1 * 2][k2][1][0],
                r_kernel[k1 * 2][k2][0][2],
                r_kernel[k1 * 2][k2][0][1],
                r_kernel[k1 * 2][k2][0][0]
                };
            end
        end
    end

    
    always @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            kernel_readdata <= {DATA_WIDTH * 2 * KERNEL_SIZE * KERNEL_SIZE{1'b0}};
        end
        else if(kernel_rd)begin
            kernel_readdata <= mem_kernel[kernel_addr];
        end
        else begin
            kernel_readdata <= kernel_readdata;
        end
    end
    
    /////////////////kernel_mem/////////////////////
    
    
    
    /////////////////ofm/////////////////////
    
    wire signed[DATA_WIDTH - 1 : 0]r_ofm[127 : 0][MAP_SIZE / 2 - 1 : 0][MAP_SIZE / 2 - 1 : 0];
    
    reg [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0] mem_ofm[127 : 0];
    wire ofm_wr;
    wire [6 : 0] ofm_addr;
    wire [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0] ofm_writedata;
    
    always @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            kernel_readdata <= {DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE{1'b0}};
        end
        else if(ofm_wr)begin
            mem_ofm[ofm_addr] <= ofm_writedata;
        end
    end
    
    generate
        genvar i, j, k;
        for(k = 0; k < 128; k = k + 1)begin: gfk
            for(i = 0; i < MAP_SIZE / 2; i = i + 1)begin: gfi
                for(j = 0; j < MAP_SIZE / 2; j = j + 1)begin: gfj
                    assign r_ofm[k][i][j] = mem_ofm[k][(MAP_SIZE / 2 * i + j + 1) * DATA_WIDTH - 1 -: DATA_WIDTH];
                end
            end
        end
    endgenerate
    
    /////////////////ofm/////////////////////

    
    
    
    
    /////////////////bias/////////////////////

    wire bias_rd;
    wire [5:0] bias_addr;
    reg[DATA_WIDTH * 2 * 2 - 1 : 0] bias_readdata;
    reg[DATA_WIDTH * 2 * 2 - 1 : 0] mem_bias[63:0];
    reg signed[DATA_WIDTH * 2 - 1 : 0]r_bias[127:0];
    
    initial begin
        for(i1 = 0; i1 < 128; i1 = i1 + 1)begin
            r_bias[i1] = $random%32767;
        end
        for(i1 = 0; i1 < 64; i1 = i1 + 1)begin
            mem_bias[i1] = {r_bias[i1 * 2 + 1], r_bias[i1 * 2]};
        end
    end
    
    always @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            bias_readdata <= {DATA_WIDTH * 2 * 2{1'b0}};
        end
        else if(bias_rd)begin
            bias_readdata <= mem_bias[bias_addr];
        end
        else begin
            bias_readdata <= {DATA_WIDTH * 2 * 2{1'b0}};
        end
    end


    /////////////////bias/////////////////////



    CNN_TOP
    #(
        .DATA_WIDTH(8),
        .BUF_WIDTH(26),
        .MAP_SIZE(32),
        .PADDING(1),
        .KERNEL_SIZE(3),
        .STRIDE(2),
        .POOLING_SIZE(2)
    )
    CNN_TOP_INST(
        .clk(clk),
        .rst_n(rst_n),
        
        .ifm_rd(ifm_rd),
        .ifm_addr(ifm_addr),
        .ifm_readdata(ifm_readdata),
        
        .kernel_rd(kernel_rd),
        .kernel_addr(kernel_addr),
        .kernel_readdata(kernel_readdata),
        
        .bias_rd(bias_rd),
        .bias_addr(bias_addr),
        .bias_readdata(bias_readdata),
        
        .ofm_wr(ofm_wr),
        .ofm_addr(ofm_addr),
        .ofm_writedata(ofm_writedata),
        
        .kernel_number(6'd0),
        
        .start(start),
        .idle(idle),
        .finish(finish)
    );


    reg signed[31:0]t[3:0];
    reg signed[31:0]res;
    always@(*) begin
        if(finish)begin
            #100;
            for(k2 = 0; k2 < 2; k2 = k2 + 1)begin
                for(i1 = 0; i1 < MAP_SIZE / 2; i1 = i1 + 1)begin
                    for(j1 = 0; j1 < MAP_SIZE / 2; j1 = j1 + 1)begin
                        t[0] = r_bias[k2];
                        t[1] = r_bias[k2];
                        t[2] = r_bias[k2];
                        t[3] = r_bias[k2];
                        for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
                            for(i2 = 0; i2 < KERNEL_SIZE; i2 = i2 + 1)begin
                                for(j2 = 0; j2 < KERNEL_SIZE; j2 = j2 + 1)begin
                                    t[0] = t[0] + r_ifm2[k1][i1 * 2 + 0 + i2][j1 * 2 + 0 + j2] * r_kernel[k2][k1][i2][j2];
                                    t[1] = t[1] + r_ifm2[k1][i1 * 2 + 0 + i2][j1 * 2 + 1 + j2] * r_kernel[k2][k1][i2][j2];
                                    t[2] = t[2] + r_ifm2[k1][i1 * 2 + 1 + i2][j1 * 2 + 0 + j2] * r_kernel[k2][k1][i2][j2];
                                    t[3] = t[3] + r_ifm2[k1][i1 * 2 + 1 + i2][j1 * 2 + 1 + j2] * r_kernel[k2][k1][i2][j2];
                                end
                            end
                        end
                        
                        res = t[0] > t[1] ? t[0] : t[1];
                        res = res > t[2] ? res : t[2];
                        res = res > t[3] ? res : t[3];
                        res = res > 0 ? res : 0;
                        res = res >> 8;
                        res = (res >> 1) + (res & 1);
                        res = res > 8'h7f ? 8'h7f : res;
                        if(res != r_ofm[k2][i1][j1])begin
                            $display("k = %d, i = %d, j = %d, res = %h, ofm = %h : error", k2, i1, j1, res, r_ofm[k2][i1][j1]);
                            #20;
                            $stop;
                        end
                        else begin
                            $display("k = %d, i = %d, j = %d, res = %h, ofm = %h : correct", k2, i1, j1, res, r_ofm[k2][i1][j1]);
                        end
                    end
                end
            end
            #20;
            $stop;
        end
    end


endmodule
