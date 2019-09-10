`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/04 16:36:28
// Module Name: relu_tb
// Project Name: CNN
// Description: simulation
// 
//////////////////////////////////////////////////////////////////////////////////


module relu_tb;

    parameter BUF_WIDTH = 26;
    parameter OUT_WIDTH = 8;
    parameter MAP_SIZE  = 16;
    
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
    
    reg signed[BUF_WIDTH - 1 : 0]r_ifm[MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];
    wire signed[OUT_WIDTH - 1 : 0]r_ofm[MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];
    
    wire[BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0]ifm;
    wire[OUT_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0]ofm;
    
    
    generate
        genvar i, j;
        for(i = 0; i < MAP_SIZE; i = i + 1)begin : gfi
            for(j = 0; j < MAP_SIZE; j = j + 1)begin : gfj
                assign ifm[(i * MAP_SIZE + j + 1) * BUF_WIDTH - 1 -: BUF_WIDTH] = r_ifm[i][j];
                assign r_ofm[i][j] = ofm[(i * MAP_SIZE + j + 1) * OUT_WIDTH - 1 -: OUT_WIDTH];
            end
        end
    endgenerate



    reg[10:0]i1, j1;
    initial begin
        for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin
            for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                r_ifm[i1][j1] = $random%131071;
            end
        end
    end
    
    
    RELU_TOP
    #(
        .BUF_WIDTH(BUF_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .MAP_SIZE(MAP_SIZE)
    )
    RELU_TOP_INST
    (
        .clk(clk),
        .rst_n(rst_n),
        
        .ifm(ifm),
        .ofm(ofm)
    );
    
    initial begin
        #150;
        for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin
            for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin
                if(r_ifm[i1][j1] < 0)begin
                    if(r_ofm[i1][j1] != 0)begin
                        $display("i = %d, j = %d, ofm = %h : error", i1, j1, r_ofm[i1][j1]);
                        #20;
                        $stop;
                    end
                    else begin
                        $display("i = %d, j = %d, ofm = %h : correct", i1, j1, r_ofm[i1][j1]);
                    end
                end
                else begin
                    if((r_ifm[i1][j1] >> 9) >= 8'h7f)begin
                        if(r_ofm[i1][j1] != 8'h7f)begin
                            $display("i = %d, j = %d, ofm = %h : error", i1, j1, r_ofm[i1][j1]);
                            #20;
                            $stop;
                        end
                        else begin
                            $display("i = %d, j = %d, ofm = %h : correct", i1, j1, r_ofm[i1][j1]);
                        end
                    end
                    else begin
                        if(r_ofm[i1][j1] != ((r_ifm[i1][j1] >> 9) + ((r_ifm[i1][j1] >> 8) & 1)))begin
                            $display("i = %d, j = %d, ofm = %h : error", i1, j1, r_ofm[i1][j1]);
                            #20;
                            $stop;
                        end
                        else begin
                            $display("i = %d, j = %d, ofm = %h : correct", i1, j1, r_ofm[i1][j1]);
                        end
                    end
                end
            end
        end
    end
    
endmodule
