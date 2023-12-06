`timescale 1ns / 1ps

module pixel_processing_tb;

localparam MODE_EMB = 1'b0;
localparam MODE_EXT = 1'b1;

reg clk;
reg rst_n;
reg mode;
// FIFO pixel input
reg [7 : 0]ff_pixel_data;
reg ff_pixel_empty;
wire ff_pixel_rd;
// FIFO message input
reg [7 : 0]ff_mess_data;
reg ff_mess_empty;
wire ff_mess_rd;
// FIFO output
reg ff_full;
wire [7 : 0]ff_data;
wire ff_wr;

pixel_processing dut (.clk(clk),
											.rst_n(rst_n),
											.mode(mode),
											.ff_pixel_data(ff_pixel_data),
											.ff_pixel_empty(ff_pixel_empty),
											.ff_pixel_rd(ff_pixel_rd),
											.ff_mess_data(ff_mess_data),
											.ff_mess_empty(ff_mess_empty),
											.ff_mess_rd(ff_mess_rd),
											.ff_full(ff_full),
											.ff_data(ff_data),
											.ff_wr(ff_wr)										  
										 );
	
always #5 clk = ~clk;

initial begin
	clk <= 1;
	rst_n <= 0;
	mode <= 0;
	ff_pixel_data <= 232;
	ff_pixel_empty <= 0;
	ff_mess_data <= 8'h20;
	ff_mess_empty <= 0;
	ff_full <= 0;
	#10;
	rst_n <= 1;
	#50;
	ff_pixel_data <= 82;
	#20;
	ff_pixel_data <= 142;
	#10;
	ff_mess_empty <= 1;
	ff_pixel_empty <= 1;
	#500 $finish;
end
endmodule