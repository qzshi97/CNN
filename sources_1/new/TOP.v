`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/06 21:20:32
// Module Name: TOP
// Project Name: CNN
// Description: 完成64次双通道CNN计算，并输出，以start信号为开始计算时刻，以finish信号为完成计算时刻
// 
//////////////////////////////////////////////////////////////////////////////////


module TOP
#(
    parameter DATA_WIDTH    = 8,
    parameter BUF_WIDTH     = 26,
    parameter MAP_SIZE      = 32,
    parameter PADDING       = 1,
    parameter KERNEL_SIZE   = 3,
    parameter STRIDE        = 2,
    parameter POOLING_SIZE  = 2
)
(
    input clk,
    input rst_n,
    
    output ifm_rd,
    output [8 : 0] ifm_addr,
    input [DATA_WIDTH * MAP_SIZE * MAP_SIZE / 8 - 1 : 0] ifm_readdata,
    
    output kernel_rd,
    output [11 : 0] kernel_addr,
    input [DATA_WIDTH * 2 * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel_readdata,
    
    output bias_rd,
    output[5 : 0] bias_addr,
    input [DATA_WIDTH * 2 * 2 - 1 : 0] bias_readdata,
    
    output ofm_wr,
    output [6 : 0] ofm_addr,
    output [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0] ofm_writedata,
    
    input start,
    output reg idle,
    output reg finish

    );
    

reg cnn_start;
wire cnn_idle;
wire cnn_finish;
reg[6:0] kernel_number;
reg[6:0] finish_number;
reg[1:0]state;

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        state <= 2'd0;
    end
    else begin
        case(state)
            2'd0:begin
                if(start)begin
                    state <= 2'd1;
                end
                else begin
                    state <= 2'd0;
                end
            end
            2'd1:begin
                if(!cnn_idle)begin
                    state <= 2'd2;
                end
                else begin
                    state <= state;
                end
            end
            2'd2:begin
                if(kernel_number > 7'd63)begin
                    state <= 2'd3;
                end
                else if(cnn_idle)begin
                    state <= 2'd1;
                end
                else begin
                    state <= state;
                end
            end
            2'd3:begin
                if(finish_number > 7'd63)begin
                    state <= 2'd0;
                end
                else begin
                    state <= state;
                end
            end
            default:begin
                state <= 2'd0;
            end
        endcase
    end
end


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        cnn_start <= 1'b0;
    end
    else begin
        case(state)
            2'd0:begin
                if(start)begin
                    cnn_start <= 1'b1;
                end
                else begin
                    cnn_start <= 1'b0;
                end
            end
            2'd1, 2'd3:begin
                cnn_start <= 1'b0;
            end
            2'd2:begin
                if(cnn_idle)begin
                    cnn_start <= 1'b1;
                end
                else begin
                    cnn_start <= 1'b0;
                end
            end
            default:begin
                cnn_start <= 1'b0;
            end
        endcase
    end
end


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        kernel_number <= 7'd0;
    end
    else begin
        case(state)
            2'd0, 2'd3:begin
                kernel_number <= 7'd0;
            end
            2'd1:begin
                if(!cnn_idle)begin
                    kernel_number <= kernel_number + 1'b1;
                end
                else begin
                    kernel_number <= kernel_number;
                end
            end
            2'd2:begin
                kernel_number <= kernel_number;
            end
            default:begin
                kernel_number <= 7'd0;
            end
        endcase
    end
end


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        finish_number <= 7'd0;
    end
    else if(state == 2'd0)begin
        finish_number <= 7'd0;
    end
    else if(cnn_finish)begin
        finish_number <= finish_number + 1'b1;
    end
end


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        idle <= 1'b0;
    end
    else begin
        case(state)
            2'd0:begin
                if(start)begin
                    idle <= 1'b0;
                end
                else begin
                    idle <= 1'b1;
                end
            end
            2'd1, 2'd2:begin
                idle <= 1'b0;
            end
            2'd3:begin
                if(finish_number > 7'd63)begin
                    idle <= 1'b1;
                end
                else begin
                    idle <= 1'b0;
                end
            end
            default:begin
                idle <= 1'b0;
            end
        endcase
    end
end



always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        finish <= 1'b0;
    end
    else if(finish_number == 7'd63 && cnn_finish)begin
        finish <= 1'b1;
    end
    else begin
        finish <= 1'b0;
    end
end

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
CNN_TOP_INST
(
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

    .kernel_number(kernel_number[5 : 0]),

    .start(cnn_start),
    .idle(cnn_idle),
    .finish(cnn_finish)

);



endmodule
