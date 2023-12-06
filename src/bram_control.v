`timescale 1ns / 1ps

module bram_control
	#(
		parameter ADDR_WIDTH = 32,
		parameter DATA_WIDTH = 32,
		parameter REG_WIDTH = 32,
		parameter NUM_BYTES = 4
	)
	(
		input bram_mode,
		// BRAM PORTA interface
		output reg [ADDR_WIDTH-1:0] bram_addr,
		output reg bram_clk,
		output reg [DATA_WIDTH-1:0] bram_din,
		input [DATA_WIDTH-1:0] bram_dout,
		output reg bram_en,
		output reg [NUM_BYTES-1:0] bram_we,
		output reg bram_rst,  
		// BRAM control with ps
		input [ADDR_WIDTH-1:0] bram_ctrl_addr,
		input bram_ctrl_clk,
		input [DATA_WIDTH-1:0] bram_ctrl_din,
		output reg [DATA_WIDTH-1:0] bram_ctrl_dout,
		input bram_ctrl_en,
		input bram_ctrl_rst,
		input [NUM_BYTES-1:0] bram_ctrl_we,
		// BRAM control with pl
		input [ADDR_WIDTH-1:0] pl_addr,
		input pl_clk,
		input [DATA_WIDTH-1:0] pl_din,
		output reg [DATA_WIDTH-1:0] pl_dout,
		input [NUM_BYTES-1:0] pl_we
	);

	always @(*)
		if (bram_mode) begin
			bram_clk = pl_clk;
			bram_addr = pl_addr;
			bram_din = pl_din;
			bram_en = 1'b1;
			bram_rst = 1'b0;
			bram_we = pl_we;
			pl_dout = bram_dout;
		end
		else begin
			bram_clk = bram_ctrl_clk;
			bram_addr = bram_ctrl_addr;
			bram_din = bram_ctrl_din;
			bram_en = bram_ctrl_en;
			bram_rst = bram_ctrl_rst;
			bram_we = bram_ctrl_we;
			bram_ctrl_dout = bram_dout; 
		end
	endmodule
