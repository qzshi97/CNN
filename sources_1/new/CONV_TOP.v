`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/01 19:32:00
// Module Name: CONV_TOP
// Project Name: CNN
// Description: 实现从ram中读取64输入通道数据，带偏置的卷积核大小为3的二维卷积计算
// 
//////////////////////////////////////////////////////////////////////////////////


module CONV_TOP
#(
    parameter DATA_WIDTH    = 8,
    parameter BUF_WIDTH     = 26,
    parameter MAP_SIZE      = 32,
    parameter PADDING       = 1,
    parameter KERNEL_SIZE   = 3
)
(
    input clk,
    input rst_n,
    
    output reg ifm_rd,
    output reg [8 : 0] ifm_addr,
    input [DATA_WIDTH * MAP_SIZE * MAP_SIZE / 8 - 1 : 0] ifm_readdata,

    output reg kernel_rd,
    output reg [5 : 0] kernel_addr,
    input [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel_readdata,

    input [DATA_WIDTH * 2 - 1 : 0] bias,
    
    output reg [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] ofm,

    input start,
    output reg idle,
    output reg finish
    );

wire [DATA_WIDTH * (MAP_SIZE + PADDING * 2) * (MAP_SIZE + PADDING * 2) - 1 : 0] conv_ifm;
reg [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] conv_kernel;
reg [DATA_WIDTH * 2 - 1 : 0] conv_bias;
wire [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] conv_ofm;
reg[3:0] state;
reg[6:0] cnt;
reg conv_start;
wire conv_finish;


//////////////////////status/////////////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        idle <= 1'b0;
    end
    else begin
        case(state)
            4'd0:begin
                idle <= 1'b1;
            end
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7:begin
                idle <= 1'b0;
            end
            4'd1, 4'd8, 4'd9:begin
                if(cnt == 7'd64)begin
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
    else begin
        finish <= conv_finish;
    end
end
//////////////////////status/////////////////////////



/////////////////////count///////////////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 7'd0;
    end
    else begin
        case(state)
            4'd0:cnt <= 7'd0;
            4'd1:begin
                if(start)begin
                    cnt <= 7'd0;
                end
                else begin
                    cnt <= cnt;
                end
            end
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd8, 4'd9:cnt <= cnt;
            4'd7:cnt <= cnt + 1'b1;
            default:cnt <= 7'd0;
        endcase
    end
end
/////////////////////count///////////////////////////




//////////////////////state//////////////////////////
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
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8:begin
                state <= state + 1'b1;
            end
            4'd1:begin
                if(start)begin
                    state <= 4'd1;
                end
                else if(cnt == 7'd64)begin
                    state <= 4'd0;
                end
                else begin
                    state <= state + 1'b1;
                end
            end
            4'd9:begin
                if(cnt == 7'd1)begin
                    state <= 4'd2;
                end
                else begin
                    state <= 4'd1;
                end
            end
            default:begin
                state <= 4'd0;
            end
        endcase
    end
end
//////////////////////state//////////////////////////



/////////////////////control/////////////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        conv_start <= 1'b0;
    end
    else begin
        case(state)
            4'd0:begin
                conv_start <= 1'b0;
            end
            4'd1:begin
                if(start)begin
                    conv_start <= 1'b0;
                end
                else begin
                    conv_start <= conv_start;
                end
            end
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8:begin
                conv_start <= conv_start;
            end
            4'd9:begin
                conv_start <= 1'b1;
            end
            default:begin
                conv_start <= 1'b0;
            end
        endcase
    end
end
/////////////////////control/////////////////////////



/////////////////ifm data read///////////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        ifm_rd <= 1'b0;
        ifm_addr <= 9'd0;
    end
    else begin
        case(state)
            4'd0:begin
                if(start)begin
                    ifm_rd <= 1'b1;
                    ifm_addr <= 9'd0;
                end
                else begin
                    ifm_rd <= 1'b0;
                    ifm_addr <= 9'd0;
                end
            end
            4'd1:begin
                if(start)begin
                    ifm_rd <= 1'b1;
                    ifm_addr <= 9'd0;
                end
                else begin
                    ifm_rd <= 1'b1;
                    ifm_addr <= ifm_addr + 1'b1;
                end
            end
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd9:begin
                ifm_rd <= 1'b1;
                ifm_addr <= ifm_addr + 1'b1;
            end
            4'd8:begin
                if(cnt == 7'd1)begin
                    ifm_rd <= 1'b1;
                    ifm_addr <= ifm_addr + 1'b1;
                end
                else begin
                    ifm_rd <= 1'b0;
                    ifm_addr <= ifm_addr;
                end
            end
            default:begin
                ifm_rd <= 1'b0;
                ifm_addr <= 9'd0;
            end
        endcase
    end
end
/////////////////ifm data read///////////////////////



///////////////kernel data read/////////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        kernel_rd <= 1'b0;
        kernel_addr <= 6'd0;
    end
    else begin
        case(state)
            4'd0:begin
                kernel_rd <= 1'b0;
                kernel_addr <= 6'd0;
            end
            4'd1:begin
                if(start)begin
                    kernel_rd <= 1'b0;
                    kernel_addr <= 6'd0;
                end
                else begin
                    kernel_rd <= 1'b0;
                    kernel_addr <= kernel_addr;
                end
            end
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd8:begin
                kernel_rd <= 1'b0;
                kernel_addr <= kernel_addr;
            end
            4'd7:begin
                kernel_rd <= 1'b1;
                kernel_addr <= kernel_addr;
            end
            4'd9:begin
                kernel_rd <= 1'b0;
                kernel_addr <= kernel_addr + 1'b1;
            end
            default:begin
                kernel_rd <= 1'b0;
                kernel_addr <= 6'd0;
            end
        endcase
    end
end
///////////////kernel data read/////////////////////



////////////////ifm34X34 input////////////////////
reg[DATA_WIDTH - 1 : 0]r_ifm[MAP_SIZE + PADDING * 2 - 1 : 0][MAP_SIZE + PADDING * 2 - 1 : 0];
generate
    genvar i, j, k;
    for(i = 0; i < PADDING; i = i + 1)begin: gfi0
        for(j = 0; j < MAP_SIZE + PADDING * 2; j = j + 1)begin: gfj0
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
        end
    end
    for(i = PADDING; i < MAP_SIZE + PADDING; i = i + 1)begin: gfi1
        for(j = 0; j < PADDING; j = j + 1)begin: gfj10
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
        end
        
        for(j = MAP_SIZE + PADDING; j < MAP_SIZE + PADDING * 2; j = j + 1)begin: gfj12
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
        end
    end
    for(i = MAP_SIZE + PADDING; i < MAP_SIZE + PADDING * 2; i = i + 1)begin: gfi2
        for(j = 0; j < MAP_SIZE + PADDING * 2; j = j + 1)begin: gfj2
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
        end
    end
    
    for(k = 0; k < 4; k = k + 1)begin: gfk
        for(j = PADDING; j < MAP_SIZE + PADDING; j = j + 1)begin: gfj11
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[1 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9:r_ifm[1 + k][j] <= r_ifm[1 + k][j];
                        4'd2:r_ifm[1 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[1 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[5 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9:r_ifm[5 + k][j] <= r_ifm[5 + k][j];
                        4'd3:r_ifm[5 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[5 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[9 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd3, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9:r_ifm[9 + k][j] <= r_ifm[9 + k][j];
                        4'd4:r_ifm[9 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[9 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[13 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd3, 4'd4, 4'd6, 4'd7, 4'd8, 4'd9:r_ifm[13 + k][j] <= r_ifm[13 + k][j];
                        4'd5:r_ifm[13 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[13 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[17 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd7, 4'd8, 4'd9:r_ifm[17 + k][j] <= r_ifm[17 + k][j];
                        4'd6:r_ifm[17 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[17 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[21 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd8, 4'd9:r_ifm[21 + k][j] <= r_ifm[21 + k][j];
                        4'd7:r_ifm[21 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[21 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[25 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd9:r_ifm[25 + k][j] <= r_ifm[25 + k][j];
                        4'd8:r_ifm[25 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[25 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
            
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[29 + k][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8:r_ifm[29 + k][j] <= r_ifm[29 + k][j];
                        4'd9:r_ifm[29 + k][j] <= ifm_readdata[(j - PADDING + 1) * DATA_WIDTH + k * 256 - 1 -: DATA_WIDTH];
                        default:begin
                            r_ifm[29 + k][j] <= {DATA_WIDTH{1'b0}};
                        end
                    endcase
                end
            end
        end
    end
endgenerate
////////////////ifm34X34 input////////////////////



/////////////////////3D to 1D/////////////////////
generate
    genvar k1, k2;
    for(k1 = 0; k1 < MAP_SIZE + PADDING * 2; k1 = k1 + 1)begin: gfk1
        for(k2 = 0; k2 < MAP_SIZE + PADDING * 2; k2 = k2 + 1)begin: gfk2
            assign conv_ifm[((MAP_SIZE + PADDING * 2) * k1 + k2 + 1) * DATA_WIDTH - 1 -: DATA_WIDTH] = r_ifm[k1][k2];
        end
    end
endgenerate
/////////////////////3D to 1D/////////////////////



////////////////kernel data input/////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        conv_kernel <= {(DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE){1'b0}};
    end
    else if(state == 4'd9)begin
        conv_kernel <= kernel_readdata;
    end
    else begin
        conv_kernel <= conv_kernel;
    end
end
////////////////kernel data input/////////////////



////////////////bias data input///////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        conv_bias <= {(DATA_WIDTH * 2){1'b0}};
    end
    else if(state == 4'd8)begin
        conv_bias <= bias;
    end
    else begin
        conv_bias <= conv_bias;
    end
end
////////////////bias data input///////////////////



///////////////ofm data output////////////////////
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        ofm <= {BUF_WIDTH * MAP_SIZE * MAP_SIZE{1'b0}};
    end
    else if(conv_finish)begin
        ofm <= conv_ofm;
    end
end
///////////////ofm data output////////////////////


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
    .ifm(conv_ifm),
    .kernel(conv_kernel),
    .bias(conv_bias),
    .ofm(conv_ofm),
    .start(conv_start),
    .idle(),
    .finish(conv_finish)
);

endmodule
