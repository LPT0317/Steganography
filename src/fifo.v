`timescale 1ns / 1ps

module fifo_buffer
	#(
		parameter FF_DEPTH = 16,
		parameter DATA_WIDTH = 8
	)
	(
		input clk,
		input rst_n,
		// Read FIFO
		input rden,
		output reg [DATA_WIDTH-1:0] dout,
		output empty,
		// Write FIFO
		input wren,
		input [DATA_WIDTH-1:0] din,
		output full
	);

	localparam FF_ADDR_W = $clog2(FF_DEPTH);
	
	reg [DATA_WIDTH-1:0]mem[FF_DEPTH-1:0];
	reg [FF_ADDR_W:0] rdptr;
	reg [FF_ADDR_W:0] wrptr;
	
	assign empty = (rdptr == wrptr);
	assign full = ({!rdptr[FF_ADDR_W],rdptr[FF_ADDR_W-1:0]} == wrptr);

	always @(posedge clk)
		if (!rst_n)
			wrptr <= 0;
		else begin
			if (wren && !full) begin
			mem[wrptr[FF_ADDR_W-1:0]] <= din;
			wrptr <= wrptr + 1;
		end
	end

always @(posedge clk)
	if (!rst_n) begin
		rdptr <= 0;
		dout <= 0;
	end
	else begin
		if (rden && !empty) begin
		dout <= mem[rdptr[FF_ADDR_W-1:0]];
		rdptr <= rdptr + 1;
		end
	end
endmodule