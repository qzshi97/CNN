`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/08/31 19:25:33
// Module Name: CNN_TOP
// Project Name: CNN
// Description: 同时计算双输出通道卷积、池化、激活
// 
//////////////////////////////////////////////////////////////////////////////////


module CNN_TOP
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
    
    output reg bias_rd,
    output reg[5 : 0] bias_addr,
    input [DATA_WIDTH * 2 * 2 - 1 : 0] bias_readdata,
    
    output reg ofm_wr,
    output reg [6 : 0] ofm_addr,
    output reg [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0] ofm_writedata,
    
    
    input[5 : 0] kernel_number,
    input start,
    output idle,
    output reg finish

    );

wire cnn_finish;

wire [5 : 0] kernel_addr0;
reg[11 : 0] kernel_addr_offset;

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        kernel_addr_offset <= 12'd0;
    end
    else if(start)begin
        if(kernel_number == 6'd0)begin
            kernel_addr_offset <= 12'd0;
        end
        else begin
            kernel_addr_offset <= kernel_addr_offset + 12'd64;
        end
    end
    else begin
        kernel_addr_offset <= kernel_addr_offset;
    end
end

assign kernel_addr = kernel_addr_offset + kernel_addr0;

wire [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel_readdata0;
wire [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel_readdata1;
assign kernel_readdata0 = kernel_readdata[DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
assign kernel_readdata1 = kernel_readdata[DATA_WIDTH * 2 * KERNEL_SIZE * KERNEL_SIZE - 1 : DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE];


reg[3:0]state;
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        state <= 4'd0;
    end
    else begin
        case(state)
            4'd0:begin
                if(start)begin
                    state <= 4'd1;
                end
                else begin
                    state <= 4'd0;
                end
            end
            4'd1:state <= 4'd2;
            4'd2:state <= 4'd0;
            default:begin
                state <= 4'd0;
            end
        endcase
    end
end


always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        bias_rd <= 1'b0;
        bias_addr <= 6'd0;
    end
    else begin
        case(state)
            4'd0:begin
                if(start)begin
                    bias_rd <= 1'b1;
                    bias_addr <= kernel_number;
                end
                else begin
                    bias_rd <= 1'b0;
                    bias_addr <= 6'd0;
                end
            end
            4'd1, 4'd2:begin
                bias_rd <= 1'b0;
                bias_addr <= 6'd0;
            end
            default:begin
                bias_rd <= 1'b0;
                bias_addr <= 6'd0;
            end
        endcase
    end
end


reg [DATA_WIDTH * 2 - 1 : 0] bias0;
reg [DATA_WIDTH * 2 - 1 : 0] bias1;
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        bias0 <= {DATA_WIDTH * 2{1'b0}};
        bias1 <= {DATA_WIDTH * 2{1'b0}};
    end
    else begin
        case(state)
            4'd0, 4'd1:begin
                bias0 <= bias0;
                bias1 <= bias1;
            end
            4'd2:begin
                bias0 <= bias_readdata[DATA_WIDTH * 2 - 1 : 0];
                bias1 <= bias_readdata[DATA_WIDTH * 2 * 2 - 1 : DATA_WIDTH * 2];
            end
            default:begin
                bias0 <= {DATA_WIDTH * 2{1'b0}};
                bias1 <= {DATA_WIDTH * 2{1'b0}};
            end
        endcase
    end
end




reg[6 : 0] r_ofm_addr;

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        r_ofm_addr <= 7'd0;
    end
    else if(start && kernel_number == 6'd0)begin
        r_ofm_addr <= 7'd0;
    end
    else if(cnn_finish)begin
        r_ofm_addr <= r_ofm_addr + 7'd2;
    end
    else begin
        r_ofm_addr <= r_ofm_addr;
    end
end



wire [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0]ofm0;
wire [DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2) - 1 : 0]ofm1;

reg[1:0] flag;
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        flag <= 2'd0;
        ofm_wr <= 1'b0;
        ofm_addr <= 7'd0;
        ofm_writedata <= {DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2){1'b0}};
    end
    else begin
        case(flag)
            2'd0:begin
                if(cnn_finish)begin
                    flag <= 2'd1;
                    ofm_wr <= 1'b1;
                    ofm_addr <= r_ofm_addr;
                    ofm_writedata <= ofm0;
                end
                else begin
                    flag <= 2'd0;
                    ofm_wr <= 1'b0;
                    ofm_addr <= 7'd0;
                    ofm_writedata <= {DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2){1'b0}};
                end
            end
            2'd1:begin
                flag <= 2'd2;
                ofm_wr <= 1'b1;
                ofm_addr <= ofm_addr + 1'b1;
                ofm_writedata <= ofm1;
            end
            2'd2:begin
                flag <= 2'd0;
                ofm_wr <= 1'b0;
                ofm_addr <= 7'd0;
                ofm_writedata <= {DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2){1'b0}};
            end
            default:begin
                flag <= 2'd0;
                ofm_wr <= 1'b0;
                ofm_addr <= 7'd0;
                ofm_writedata <= {DATA_WIDTH * (MAP_SIZE / 2) * (MAP_SIZE / 2){1'b0}};
            end
        endcase
    end
end

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        finish <= 1'b0;
    end
    else begin
        case(flag)
            2'd0:begin
                finish <= 1'b0;
            end
            2'd1:begin
                finish <= 1'b1;
            end
            2'd2:begin
                finish <= 1'b0;
            end
            default:begin
                finish <= 1'b0;
            end
        endcase
    end
end

CNN
#(
    .DATA_WIDTH(8),
    .BUF_WIDTH(26),
    .MAP_SIZE(32),
    .PADDING(1),
    .KERNEL_SIZE(3),
    .STRIDE(2),
    .POOLING_SIZE(2)
)
CNN_INST0
(
    .clk(clk),
    .rst_n(rst_n),
    
    .ifm_rd(ifm_rd),
    .ifm_addr(ifm_addr),
    .ifm_readdata(ifm_readdata),
    
    .kernel_rd(kernel_rd),
    .kernel_addr(kernel_addr0),
    .kernel_readdata(kernel_readdata0),
    
    .bias(bias0),
    
    .ofm(ofm0),
    
    .start(start),
    .idle(idle),
    .finish(cnn_finish)
);


CNN
#(
    .DATA_WIDTH(8),
    .BUF_WIDTH(26),
    .MAP_SIZE(32),
    .PADDING(1),
    .KERNEL_SIZE(3),
    .STRIDE(2),
    .POOLING_SIZE(2)
)
CNN_INST1
(
    .clk(clk),
    .rst_n(rst_n),
    
    .ifm_rd(),
    .ifm_addr(),
    .ifm_readdata(ifm_readdata),
    
    .kernel_rd(),
    .kernel_addr(),
    .kernel_readdata(kernel_readdata1),
    
    .bias(bias1),
    
    .ofm(ofm1),
    
    .start(start),
    .idle(),
    .finish()
);
endmodule
