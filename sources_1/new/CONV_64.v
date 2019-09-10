`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: qinzhenshi
// Create Date: 2019/09/01 15:50:50
// Module Name: CONV_64
// Project Name: CNN
// Description: 实现卷积核大小为3的二维卷积计算（ifm需包含pad），可连续计算若干输入通道加和
// 
//////////////////////////////////////////////////////////////////////////////////


module CONV_64
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
    
    input [DATA_WIDTH * (MAP_SIZE + PADDING * 2) * (MAP_SIZE + PADDING * 2) - 1 : 0] ifm,
    input [DATA_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0] kernel,
    input [DATA_WIDTH * 2 - 1 : 0] bias,
    output [BUF_WIDTH * MAP_SIZE * MAP_SIZE - 1 : 0] ofm,
    
    input start,
    output reg idle,
    output reg finish
);

reg [3:0] state;
reg start_flag;
//64通道连续加和标志位
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        start_flag <= 1'b0;
    end
    else if(state == 4'd8 && start)begin
        start_flag <= 1'b1;
    end
    else begin
        start_flag <= 1'b0;
    end
end

//状态机
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
            4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8:begin
                state <= state + 1'b1;
            end
            4'd9:begin
                if(idle && start || start_flag)begin
                    state <= 4'd1;
                end
                else begin
                    state <= 4'd0;
                end
            end
            default:begin
                state <= 4'd0;
            end
        endcase
    end
end

//空闲信号，指示下一次输入可以开始
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        idle <= 1'b0;
    end
    else begin
        case(state)
            4'd0:begin
                if(start)begin
                    idle <= 1'b0;
                end
                else begin
                    idle <= 1'b1;
                end
            end
            4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6:begin
                idle <= 1'b0;
            end
            4'd7, 4'd8:begin
                if(start)begin
                    idle <= 1'b0;
                end
                else begin
                    idle <= 1'b1;
                end
            end
            4'd9:begin
                if(start_flag)begin
                    idle <= 1'b0;
                end
                else begin
                    idle <= 1'b1;
                end
            end
            default:idle <= 1'b0;
        endcase
    end
end

//完成信号，指示当前输出已经完成
always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        finish <= 1'b0;
    end
    else begin
        case(state)
            4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8:begin
                finish <= 1'b0;
            end
            4'd9:begin
                if(idle)begin
                    finish <= 1'b1;
                end
                else begin
                    finish <= 1'b0;
                end
            end
            default:finish <= 1'b0;
        endcase
    end
end


//输入通道一维矩阵转三维存储器格式

reg [DATA_WIDTH - 1 : 0] r_ifm [MAP_SIZE + PADDING * 2 - 1 : 0][MAP_SIZE + PADDING * 2 - 1 : 0];
wire[DATA_WIDTH - 1 : 0] w_ifm [MAP_SIZE + PADDING * 2 - 1 : 0][MAP_SIZE + PADDING * 2 - 1 : 0];
generate
    genvar i, j;
    for(i = 0; i < MAP_SIZE + PADDING * 2; i = i + 1)begin: gfwi
        for(j = 0; j < MAP_SIZE + PADDING * 2; j = j + 1)begin: gfwj
            assign w_ifm[i][j] = ifm[(((MAP_SIZE + PADDING * 2) * i) + j + 1) * DATA_WIDTH - 1 -: DATA_WIDTH];
        end
    end
    
    for(i = 0; i < MAP_SIZE + PADDING * 2; i = i + 1)begin: gfi
        for(j = 0; j < MAP_SIZE + PADDING * 2; j = j + 1)begin: gfj
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd0, 4'd8:begin
                            r_ifm[i][j] <= w_ifm[i][j];
                        end
                        4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7:begin
                            r_ifm[i][j] <= r_ifm[i][j];
                        end
                        4'd9:begin
                            if(idle && start)begin
                                r_ifm[i][j] <= w_ifm[i][j];
                            end
                            else begin
                                r_ifm[i][j] <= r_ifm[i][j];
                            end
                        end
                        default:r_ifm[i][j] <= {DATA_WIDTH{1'b0}};
                    endcase
                end
            end
        end
    end
endgenerate

//卷积核一维矩阵转二维存储器格式

reg [DATA_WIDTH - 1 : 0] r_kernel [KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [DATA_WIDTH - 1 : 0] w_kernel [KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

generate
    genvar k;
    for(k = 0; k < KERNEL_SIZE * KERNEL_SIZE; k = k + 1)begin: gfwk
        assign w_kernel[k] = kernel[(k + 1) * DATA_WIDTH - 1 -: DATA_WIDTH];
    end
    
    for(k = 0; k < KERNEL_SIZE * KERNEL_SIZE; k = k + 1)begin: gfk
        always @(posedge clk, negedge rst_n)begin
            if(!rst_n)begin
                r_kernel[k] <= {DATA_WIDTH{1'b0}};
            end
            else begin
                case(state)
                    4'd0, 4'd8:begin
                        r_kernel[k] <= w_kernel[k];
                    end
                    4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7:begin
                        r_kernel[k] <= r_kernel[k];
                    end
                    4'd9:begin
                        if(idle && start)begin
                            r_kernel[k] <= w_kernel[k];
                        end
                        else begin
                            r_kernel[k] <= r_kernel[k];
                        end
                    end
                    default:r_kernel[k] <= {DATA_WIDTH{1'b0}};
                endcase
            end
        end
    end
endgenerate

//卷积计算，输出加和

reg signed [BUF_WIDTH - 1 : 0] r_ofm [MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];

generate
    genvar i1, j1;
    for(i1 = 0; i1 < MAP_SIZE; i1 = i1 + 1)begin: gfi1
        for(j1 = 0; j1 < MAP_SIZE; j1 = j1 + 1)begin: gfj1
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    r_ofm[i1][j1] <= {BUF_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd0:begin
                            if(start)begin
                                r_ofm[i1][j1] <= $signed(bias);
                            end
                            else begin
                                r_ofm[i1][j1] <= r_ofm[i1][j1];
                            end
                        end
                        4'd1:begin
                            if(idle && start)begin
                                r_ofm[i1][j1] <= $signed(bias) + $signed(C[((MAP_SIZE * i1) + j1 + 1) * DATA_WIDTH * 2 - 1 -: DATA_WIDTH * 2]);
                            end
                            else begin
                                r_ofm[i1][j1] <= r_ofm[i1][j1] + $signed(C[((MAP_SIZE * i1) + j1 + 1) * DATA_WIDTH * 2 - 1 -: DATA_WIDTH * 2]);
                            end
                        end
                        4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9:begin
                            r_ofm[i1][j1] <= r_ofm[i1][j1] + $signed(C[((MAP_SIZE * i1) + j1 + 1) * DATA_WIDTH * 2 - 1 -: DATA_WIDTH * 2]);
                        end
                        default:r_ofm[i1][j1] <= {BUF_WIDTH{1'b0}};
                    endcase
                end
            end
        end
    end
endgenerate


//输出通道三维存储器格式转一维矩阵
generate
    genvar k1, k2;
    for(k1 = 0; k1 < MAP_SIZE; k1 = k1 + 1)begin: gfk1
        for(k2 = 0; k2 < MAP_SIZE; k2 = k2 + 1)begin: gfk2
            assign ofm[(MAP_SIZE * k1 + k2 + 1) * BUF_WIDTH - 1 -: BUF_WIDTH] = r_ofm[k1][k2];
        end
    end
endgenerate



///////////乘法器输入通道A////////////////

reg [DATA_WIDTH - 1 : 0] MAP_A [MAP_SIZE - 1 : 0][MAP_SIZE - 1 : 0];
wire [MAP_SIZE * MAP_SIZE * DATA_WIDTH - 1 : 0] A;

//输入通道卷积滑动遍历
generate
    genvar i2, j2;
    for(i2 = 0; i2 < MAP_SIZE; i2 = i2 + 1)begin: gfi2
        for(j2 = 0; j2 < MAP_SIZE; j2 = j2 + 1)begin: gfj2
            always @(posedge clk, negedge rst_n)begin
                if(!rst_n)begin
                    MAP_A[i2][j2] <= {DATA_WIDTH{1'b0}};
                end
                else begin
                    case(state)
                        4'd0:begin
                            if(start)begin
                                MAP_A[i2][j2] <= w_ifm[i2][j2];
                            end
                            else begin
                                MAP_A[i2][j2] <= {DATA_WIDTH{1'b0}};
                            end
                        end
                        4'd1: MAP_A[i2][j2] <= r_ifm[i2][j2 + 1];
                        4'd2: MAP_A[i2][j2] <= r_ifm[i2][j2 + 2];
                        4'd3: MAP_A[i2][j2] <= r_ifm[i2 + 1][j2];
                        4'd4: MAP_A[i2][j2] <= r_ifm[i2 + 1][j2 + 1];
                        4'd5: MAP_A[i2][j2] <= r_ifm[i2 + 1][j2 + 2];
                        4'd6: MAP_A[i2][j2] <= r_ifm[i2 + 2][j2];
                        4'd7: MAP_A[i2][j2] <= r_ifm[i2 + 2][j2 + 1];
                        4'd8: MAP_A[i2][j2] <= r_ifm[i2 + 2][j2 + 2];
                        4'd9:begin
                            if(idle && start)begin
                                MAP_A[i2][j2] <= w_ifm[i2][j2];
                            end
                            else begin
                                MAP_A[i2][j2] <= r_ifm[i2][j2];
                            end
                        end
                        default: MAP_A[i2][j2] <= {DATA_WIDTH{1'b0}};
                    endcase
                end
            end
        end
    end
endgenerate


//输入通道三维存储器格式转一维矩阵
generate
    genvar i3, j3;
    for(i3 = 0; i3 < MAP_SIZE; i3 = i3 + 1)begin: gfi3
        for(j3 = 0; j3 < MAP_SIZE; j3 = j3 + 1)begin: gfj3
            assign A[(MAP_SIZE * i3 + j3 + 1) * DATA_WIDTH - 1 -: DATA_WIDTH] = MAP_A[i3][j3];
        end
    end
endgenerate

///////////乘法器输入通道A////////////////



///////////乘法器输入通道B////////////////

reg [MAP_SIZE * MAP_SIZE * DATA_WIDTH - 1 : 0] B;

always @(posedge clk, negedge rst_n)begin
    if(!rst_n)begin
        B <= {(MAP_SIZE * MAP_SIZE * DATA_WIDTH){1'b0}};
    end
    else begin
        case(state)
            4'd0:begin
                if(start)begin
                    B <= {(MAP_SIZE * MAP_SIZE){w_kernel[0]}};
                end
                else begin
                    B <= {(MAP_SIZE * MAP_SIZE * DATA_WIDTH){1'b0}};
                end
            end
            4'd1: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[1]}};
            4'd2: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[2]}};
            4'd3: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[3]}};
            4'd4: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[4]}};
            4'd5: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[5]}};
            4'd6: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[6]}};
            4'd7: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[7]}};
            4'd8: B <= {(MAP_SIZE * MAP_SIZE){r_kernel[8]}};
            4'd9:begin
                if(idle && start)begin
                    B <= {(MAP_SIZE * MAP_SIZE){w_kernel[0]}};
                end
                else begin
                    B <= {(MAP_SIZE * MAP_SIZE){r_kernel[0]}};
                end
            end
            default: B <= {(MAP_SIZE * MAP_SIZE * DATA_WIDTH){1'b0}};
        endcase
    end
end

///////////乘法器输入通道B////////////////



wire [MAP_SIZE * MAP_SIZE * DATA_WIDTH * 2 - 1 : 0] C;

MULT
#(DATA_WIDTH, MAP_SIZE)
MULT_INST
(
    .A(A),
    .B(B),
    .C(C)
);



endmodule
