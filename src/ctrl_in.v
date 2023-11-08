`timescale 1ns / 1ps

    module ctrl_in
    #(
        parameter PIXEL_WIDTH = 8,
        parameter MESS_WIDTH = 4
    )
    (
        clk,
        rst,
        start,
        pp_wr,
        ff_wr,
        //FIFO In
        pixel_din1,
        pixel_din2,
        pixel_din3,
        pixel_rd_req,
        pixel_rd_vld,
        // FIFO secret
        secret_din,
        secret_rd_req,
        secret_empty,
        // Pixel Process 1
        pp1_run,
        pp1_start,
        pp1_g1,
        pp1_g2,
        pp1_g3,
        pp1_secret,
        // Pixel Process 2
        pp2_run,
        pp2_start,
        pp2_g1,
        pp2_g2,
        pp2_g3,
        pp2_secret        
    );

    // Port declarations
    input clk;
    input rst;
    input start;
    input pp_wr;
    input ff_wr;
    //FIFO In
    input [PIXEL_WIDTH-1 : 0]pixel_din1;
    input [PIXEL_WIDTH-1 : 0]pixel_din2;
    input [PIXEL_WIDTH-1 : 0]pixel_din3;
    input pixel_rd_vld;
    output pixel_rd_req;
    // FIFO secret
    input [MESS_WIDTH-1 : 0]secret_din;
    input secret_empty;
    output secret_rd_req;
    // Pixel Process 1
    input pp1_run;
    output pp1_start;
    output [PIXEL_WIDTH-1 : 0]pp1_g1;
    output [PIXEL_WIDTH-1 : 0]pp1_g2;
    output [PIXEL_WIDTH-1 : 0]pp1_g3;
    output [MESS_WIDTH-1 : 0]pp1_secret;
    // Pixel Process 2
    input pp2_run;
    output pp2_start;
    output [PIXEL_WIDTH-1 : 0]pp2_g1;
    output [PIXEL_WIDTH-1 : 0]pp2_g2;
    output [PIXEL_WIDTH-1 : 0]pp2_g3;
    output [MESS_WIDTH-1 : 0]pp2_secret;
    
    // State
    localparam INIT = 0;
    localparam RD_DATA = 1;
    localparam WR_PP1 = 2;
    localparam WR_PP2 = 3;
    
    //Internal reg wire
    reg pixel_rd_req_reg;
    reg secret_rd_req_reg;
    reg pp1_start_reg;
    reg [PIXEL_WIDTH-1 : 0]pp1_g1_reg;
    reg [PIXEL_WIDTH-1 : 0]pp1_g2_reg;
    reg [PIXEL_WIDTH-1 : 0]pp1_g3_reg;
    reg [MESS_WIDTH-1 : 0]pp1_secret_reg;
    reg pp2_start_reg;
    reg [PIXEL_WIDTH-1 : 0]pp2_g1_reg;
    reg [PIXEL_WIDTH-1 : 0]pp2_g2_reg;
    reg [PIXEL_WIDTH-1 : 0]pp2_g3_reg;
    reg [MESS_WIDTH-1 : 0]pp2_secret_reg;
    
    reg [1:0]next_state;
    wire [1:0]curr_state;
    reg which_pp;
    wire ctrl_wr;
    
    reg [PIXEL_WIDTH-1 : 0]pixel_din1_reg;
    reg [PIXEL_WIDTH-1 : 0]pixel_din2_reg;
    reg [PIXEL_WIDTH-1 : 0]pixel_din3_reg;
    reg [MESS_WIDTH-1 : 0]secret_din_reg;
    
    // Assign
    assign pixel_rd_req = pixel_rd_req_reg;
    assign secret_rd_req = secret_rd_req_reg;
    assign pp1_start = pp1_start_reg;
    assign pp1_g1 = pp1_g1_reg;
    assign pp1_g2 = pp1_g2_reg;
    assign pp1_g3 = pp1_g3_reg;
    assign pp1_secret = pp1_secret_reg;
    assign pp2_start = pp2_start_reg;
    assign pp2_g1 = pp2_g1_reg;
    assign pp2_g2 = pp2_g2_reg;
    assign pp2_g3 = pp2_g3_reg;
    assign pp2_secret = pp2_secret_reg;
    assign ctrl_wr = pp_wr & ~ff_wr;
    
    assign curr_state = next_state;
    
    
    // Reading pixel and write to fifo
    always @(posedge clk) begin
        if (!rst) begin
            next_state <= INIT;
            pixel_rd_req_reg <= 0;
            secret_rd_req_reg <= 0;
            pp1_start_reg <= 0;
            pp1_g1_reg <= 0;
            pp1_g2_reg <= 0;
            pp1_g3_reg <= 0;
            pp1_secret_reg <= 0;
            pp2_start_reg <= 0;
            pp2_g1_reg <= 0;
            pp2_g2_reg <= 0;
            pp2_g3_reg <= 0;
            pp2_secret_reg <= 0;
            pixel_din1_reg <= 0;
            pixel_din2_reg <= 0;
            pixel_din3_reg <= 0;
            which_pp <= 0;
        end
        else begin
            case (curr_state)
                INIT: begin
                    if (start)
                        next_state <= RD_DATA;
                    else
                        next_state <= INIT;
                end
                RD_DATA: begin
                    pp1_start_reg <= 0;
                    pp2_start_reg <= 0;
                    if (pixel_rd_vld & !secret_empty & ctrl_wr & !which_pp) begin
                        pixel_rd_req_reg <= 1;
                        secret_rd_req_reg <= 1;
                        pixel_din1_reg <= pixel_din1;
                        pixel_din2_reg <= pixel_din2;
                        pixel_din3_reg <= pixel_din3;
                        secret_din_reg <= secret_din;
                        next_state <= WR_PP1;
                    end
                    else if (pixel_rd_vld & !secret_empty & ctrl_wr & which_pp) begin
                        pixel_rd_req_reg <= 1;
                        secret_rd_req_reg <= 1;
                        pixel_din1_reg <= pixel_din1;
                        pixel_din2_reg <= pixel_din2;
                        pixel_din3_reg <= pixel_din3;
                        secret_din_reg <= secret_din;
                        next_state <= WR_PP2;
                    end
                    else begin
                        next_state <= RD_DATA;
                    end
                end
                WR_PP1: begin
                    pixel_rd_req_reg <= 0;
                    secret_rd_req_reg <= 0;
                    if (!pp1_run) begin
                        pp1_g1_reg <= pixel_din1_reg;
                        pp1_g2_reg <= pixel_din2_reg;
                        pp1_g3_reg <= pixel_din3_reg;
                        pp1_secret_reg <= secret_din_reg;
                        pp1_start_reg <= 1;
                        which_pp <= 1;
                        next_state <= RD_DATA;
                    end
                    else begin
                        next_state <= WR_PP1;
                    end
                end
                WR_PP2: begin
                    pixel_rd_req_reg <= 0;
                    secret_rd_req_reg <= 0;
                    if (!pp2_run) begin
                        pp2_g1_reg <= pixel_din1_reg;
                        pp2_g2_reg <= pixel_din2_reg;
                        pp2_g3_reg <= pixel_din3_reg;
                        pp2_secret_reg <= secret_din_reg;
                        pp2_start_reg <= 1;
                        which_pp <= 0;
                        next_state <= RD_DATA;
                    end
                    else begin
                        next_state <= WR_PP2;
                    end
                end
            endcase
        end
    end
endmodule