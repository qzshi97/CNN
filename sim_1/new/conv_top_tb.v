`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/02 16:01:28
// Module Name: conv_top_tb
// Project Name: CNN
// Description: simulation
// 
//////////////////////////////////////////////////////////////////////////////////


module conv_top_tb;

    parameter DATA_WIDTH    = 8;
    parameter BUF_WIDTH     = 26;
    parameter MAP_SIZE      = 32;
    parameter PADDING       = 1;
    parameter KERNEL_SIZE   = 3;
    
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
            for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 4)begin
                for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                    for(i2 = 0; i2 < 4; i2 = i2 + 1)begin
                        mem_ifm[k1 * 8 + i1/4][(j1 + 1) * DATA_WIDTH + i2 * 256 - 1 -: DATA_WIDTH] = r_ifm[k1][i1 + i2][j1];
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
    wire [5:0] kernel_addr;
    reg[DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1:0] kernel_readdata;
    reg[DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1:0] mem_kernel[8191:0];
    reg signed[DATA_WIDTH - 1 : 0]r_kernel[127 : 0][63 : 0][KERNEL_SIZE - 1 : 0][KERNEL_SIZE - 1 : 0];
    
    reg[31 : 0] kernel_number;
    
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
        for(k1 = 0; k1 < 128; k1 = k1 + 1)begin
            for(k2 = 0; k2 < 64; k2 = k2 + 1)begin
                mem_kernel[k1 * 64 + k2] = {
                r_kernel[k1][k2][2][2],
                r_kernel[k1][k2][2][1],
                r_kernel[k1][k2][2][0],
                r_kernel[k1][k2][1][2],
                r_kernel[k1][k2][1][1],
                r_kernel[k1][k2][1][0],
                r_kernel[k1][k2][0][2],
                r_kernel[k1][k2][0][1],
                r_kernel[k1][k2][0][0]
                };
            end
        end
        kernel_number = 32'd0;
    end

    
    always @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            kernel_readdata <= {DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE{1'b0}};
        end
        else if(kernel_rd)begin
            kernel_readdata <= mem_kernel[kernel_addr + 64 * kernel_number];
        end
        else begin
            kernel_readdata <= kernel_readdata;
        end
    end
    
    /////////////////kernel_mem/////////////////////
    
    
    
    /////////////////ofm/////////////////////
    
    wire signed[BUF_WIDTH - 1 : 0]r_ofm[MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];
    wire signed[BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0]ofm;
    generate
        genvar i, j;
        for(i = 0; i < MAP_SIZE; i = i + 1)begin: gfi
            for(j = 0; j < MAP_SIZE; j = j + 1)begin: gfj
                assign r_ofm[i][j] = ofm[(MAP_SIZE * i + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH];
            end
        end
    endgenerate
    
    /////////////////ofm/////////////////////

    
    
    
    
    /////////////////bias/////////////////////
    
    reg signed[DATA_WIDTH * 2 - 1 : 0]bias[127:0];
    
    initial begin
        for(i1 = 0; i1 < 128; i1 = i1 + 1)begin
            bias[i1] = $random%32767;
        end
    end

    /////////////////bias/////////////////////



    CONV_TOP
    #(
        DATA_WIDTH,
        BUF_WIDTH,
        MAP_SIZE,
        PADDING,
        KERNEL_SIZE
    )
    CONV_TOP_INST(
        .clk(clk),
        .rst_n(rst_n),
        .ifm_rd(ifm_rd),
        .ifm_addr(ifm_addr),
        .ifm_readdata(ifm_readdata),
        .kernel_rd(kernel_rd),
        .kernel_addr(kernel_addr),
        .kernel_readdata(kernel_readdata),
        .bias(bias[kernel_number]),
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
                    t = bias[kernel_number];
                    for(k1 = 0; k1 < 64; k1 = k1 + 1)begin
                        for(i2 = 0; i2 < KERNEL_SIZE; i2 = i2 + 1)begin
                            for(j2 = 0; j2 < KERNEL_SIZE; j2 = j2 + 1)begin
                                t = t + r_ifm2[k1][i1 + i2][j1 + j2] * r_kernel[kernel_number][k1][i2][j2];
                            end
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
