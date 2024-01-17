`timescale 1ns / 1ps

module ctrl_rd_bram #
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
		// Register bank
		input start,
		input [REG_WIDTH-1 : 0] data_size,
		// BRAM Interface
		output bram_clk,
		input [DATA_WIDTH-1 : 0] rddata,
		output reg [ADDR_WIDTH-1 : 0] addr,
		output [NUM_BYTES-1 : 0] we,
		// FIFO In Interface
		input ff_full,
		output reg ff_wren,
		output reg [FF_WIDTH-1 : 0] ff_wr_data
    );
    
    // Internal data and signal
    reg [ADDR_WIDTH-1 : 0] addr_reg;
    reg [FF_WIDTH-1 : 0] data_reg [3 : 0];
    reg [1 : 0] wr_sel;
    reg [REG_WIDTH-1 : 0] data_cnt;
    wire start_rd;
    
    assign we = {NUM_BYTES{1'b0}};
    assign start_rd = (start && (data_size > 0));
    assign bram_clk = clk; 
    
    // FSM
    localparam INIT = 3'd0;
    localparam LD_ADDR = 3'd1;
    localparam RD_BRAM = 3'd2;
    localparam WAIT_BRAM = 3'd3;
    localparam WR_FF = 3'd4;
    localparam LD_FF = 3'd5;
    localparam FINISH = 3'd6;
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
                addr <= {ADDR_WIDTH{1'b0}};
                ff_wren <= 1'b0;
                ff_wr_data <= {FF_WIDTH{1'b0}};
                addr_reg <= {ADDR_WIDTH{1'b0}};
                for (i=0; i<4; i=i+1)
                    data_reg[i] <= {FF_WIDTH{1'b0}};
                wr_sel <= 2'd0;
                data_cnt <= {REG_WIDTH{1'b0}};
                if (start_rd)
                    next_state <= LD_ADDR;
                else
                    next_state <= INIT;
            end
            LD_ADDR: begin
                ff_wren <= 1'b0;
                finish <= 1'b0;
                if (data_cnt >= data_size) begin
                    next_state <= FINISH;
                end
                else begin
                    addr <= addr_reg << 2;
                    next_state <= WAIT_BRAM;
                end
            end
            WAIT_BRAM: begin
                next_state <= RD_BRAM;
            end
            RD_BRAM: begin
                addr_reg <= addr_reg + 1;
                data_reg[0] <= rddata[7:0];
                data_reg[1] <= rddata[15:8];
                data_reg[2] <= rddata[23:16];
                data_reg[3] <= rddata[31:24];
                next_state <= WR_FF;
            end
            WR_FF: begin
                if (data_cnt >= data_size) begin
                    ff_wren <= 1'b0;
                    next_state <= FINISH;
                end
                else if (ff_full) begin
                    ff_wren <= 1'b0;
                    ff_wr_data <= {FF_WIDTH{1'b0}};
                    next_state <= WR_FF;
                end
                else if (wr_sel != 2'd3) begin
                    data_cnt <= data_cnt + 1;
                    wr_sel <= wr_sel + 1;
                    ff_wren <= 1'b1;
                    ff_wr_data <= data_reg[wr_sel];
                    next_state <= LD_FF;
                end
                else begin
                    data_cnt <= data_cnt + 1;
                    wr_sel <= wr_sel + 1;
                    ff_wren <= 1'b1;
                    ff_wr_data <= data_reg[wr_sel];
                    next_state <= LD_ADDR;
                end
            end
            LD_FF: begin
                ff_wren <= 1'b0;
                next_state <= WR_FF;
            end
            FINISH: begin
                finish <= 1'b1;
                next_state <= FINISH;  
            end
            default:
                next_state <= INIT;
            endcase
        end
    end
endmodule
