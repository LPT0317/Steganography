`timescale 1ns / 1ps
module ctrl_wr_bram #
    (
        parameter DATA_WIDTH = 32,
		parameter ADDR_WIDTH = 32,
		parameter NUM_BYTES = 4,
		parameter REG_WIDTH = 32,
		parameter FF_WIDTH = 8
    )  
    (
        input clk,
		input rst_n,
		output reg finish,
		input sel,
		// Register bank
		input start,
		input [REG_WIDTH-1 : 0] data_size,
		// BRAM IMAGE
		output image_clk,
		output [DATA_WIDTH-1 : 0] image_wrdata,
		output [ADDR_WIDTH-1 : 0] image_addr,
		output [NUM_BYTES-1 : 0] image_we,
		// BRAM SECRET
		output secret_clk,
		output [DATA_WIDTH-1 : 0] secret_wrdata,
		output [ADDR_WIDTH-1 : 0] secret_addr,
		output [NUM_BYTES-1 : 0] secret_we,
		// FIFO In Interface
		input ff_empty,
		input [FF_WIDTH-1 : 0] ff_rd_data,
		output reg ff_rden
    );
    
    // BRAM Interface
    wire bram_clk;
    reg [DATA_WIDTH-1 : 0] wrdata;
    reg [ADDR_WIDTH-1 : 0] addr;
    reg [NUM_BYTES-1 : 0] we;
    
    reg [ADDR_WIDTH-1 : 0] addr_reg;
    reg [FF_WIDTH-1 : 0] data_reg [3 : 0];
    reg we_reg [3 : 0];
    reg [1 : 0] wr_sel;
    reg [REG_WIDTH-1 : 0] data_cnt;
    wire start_wr;
    
    assign start_wr = (start && (data_size > 0));
    assign image_clk = clk;
    assign secret_clk = clk;
    assign image_wrdata = wrdata;
    assign secret_wrdata = wrdata;
    assign image_addr = addr;
    assign secret_addr = addr;
    assign image_we = (sel) ? {NUM_BYTES{1'b0}} : we;
    assign secret_we = (sel) ? we : {NUM_BYTES{1'b0}};
    
    
    // FSM
    localparam INIT = 3'd0;
    localparam RD_FF = 3'd1;
    localparam LD_FF = 3'd2;
    localparam LD_ADDR = 3'd3;
    localparam WR_BRAM = 3'd4;
    localparam FINISH = 3'd5;
    reg [2:0] next_state;
    wire [2:0] curr_state;
    assign curr_state = next_state;
    integer i;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            addr <= {ADDR_WIDTH{1'b0}};
            next_state <= INIT;
        end
        else begin
            case (curr_state)
                INIT: begin
                    finish <= 1'b0;
                    wrdata <= {DATA_WIDTH{1'b0}};
                    addr <= {ADDR_WIDTH{1'b0}};
                    we <= {NUM_BYTES{1'b0}};
                    ff_rden <= 1'b0;
                    addr_reg <= {ADDR_WIDTH{1'b0}};
                    wr_sel <= 2'd0;
                    data_cnt <= {REG_WIDTH{1'b0}};
                    for (i=0; i<4; i=i+1) begin
                        data_reg[i] <= {FF_WIDTH{1'b0}};
                        we_reg[i] <= 1'b0;
                    end
                    if (start_wr)
                        next_state <= RD_FF;
                    else
                        next_state <= INIT;
                end
                RD_FF: begin
                    finish <= 1'b0;
                    we <= {NUM_BYTES{1'b0}};                   
                    if (data_cnt >= data_size)
                        next_state <= FINISH;
                    else if (ff_empty)
                        next_state <= RD_FF;
                    else begin      
                        ff_rden <= 1'b1;                  
                        next_state <= LD_FF;
                    end
                end
                LD_FF: begin
                    ff_rden <= 1'b0;
                    next_state <= LD_ADDR;
                end
                LD_ADDR: begin
                    ff_rden <= 1'b0;
                    addr <= addr_reg << 2;
                    data_reg[wr_sel] <= ff_rd_data;
                    wr_sel <= wr_sel + 1;
                    next_state <= WR_BRAM;
                end
                WR_BRAM: begin
                    wrdata <= {data_reg[3],data_reg[2],data_reg[1],data_reg[0]};
                    we <= {NUM_BYTES{1'b1}};
                    data_cnt <= data_cnt + 1;
                    if (wr_sel == 2'd0) begin
                        addr_reg <= addr_reg + 1;
                        for (i=0; i<4; i=i+1)
                            data_reg[i] <= {FF_WIDTH{1'b0}};
                    end
                    next_state <= RD_FF;
                end
                FINISH: begin
                    finish <= 1'b1;
                    ff_rden <= 1'b0;
                    next_state <= FINISH; 
                end
                default:
                    next_state <= INIT;
            endcase
        end
    end
endmodule
