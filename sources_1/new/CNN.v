`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/08/31 19:27:59
// Module Name: CNN
// Project Name: CNN
// Description: 计算单输出通道卷积、池化、激活
// 
//////////////////////////////////////////////////////////////////////////////////


module CNN
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
    output [5 : 0] kernel_addr,
    input [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel_readdata,
    
    input [DATA_WIDTH * 2 - 1 : 0] bias,
    
    output[DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0]ofm,
    
    
    input start,
    output idle,
    output reg finish
    );

wire [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] conv_ofm;
wire conv_finish;

CONV_TOP
#(
    .DATA_WIDTH(DATA_WIDTH),
    .BUF_WIDTH(BUF_WIDTH),
    .MAP_SIZE(MAP_SIZE),
    .PADDING(PADDING),
    .KERNEL_SIZE(KERNEL_SIZE)
)
CONV_TOP_INST
(
    .clk(clk),
    .rst_n(rst_n),
    .ifm_rd(ifm_rd),
    .ifm_addr(ifm_addr),
    .ifm_readdata(ifm_readdata),
    .kernel_rd(kernel_rd),
    .kernel_addr(kernel_addr),
    .kernel_readdata(kernel_readdata),
    .bias(bias),
    .ofm(conv_ofm),
    .start(start),
    .idle(idle),
    .finish(conv_finish)
);
    
    
wire [BUF_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0] pooling_ofm;
    
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

    .ifm(conv_ofm),
    .ofm(pooling_ofm),

    .start(conv_finish)
);
    
// wire [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0]ofm;
RELU_TOP
#(
    .BUF_WIDTH(BUF_WIDTH),
    .OUT_WIDTH(DATA_WIDTH),
    .MAP_SIZE(MAP_SIZE / 2)
)
RELU_TOP_INST
(
    .clk(clk),
    .rst_n(rst_n),
    
    .ifm(pooling_ofm),
    .ofm(ofm)
);
    
reg[1:0] cnt;

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 2'd0;
    end
    else begin
        case(cnt)
            2'd0:begin
                if(conv_finish)begin
                    cnt <= cnt + 1'b1;
                end
                else begin
                    cnt <= 2'd0;
                end
            end
            2'd1:begin
                cnt <= cnt + 1'b1;
            end
            default:begin
                cnt <= 1'b0;
            end
        endcase
    end
end

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        finish <= 1'b0;
    end
    else if(cnt == 2'd2)begin
        finish <= 1'b1;
    end
    else begin
        finish <= 1'b0;
    end
end

endmodule
