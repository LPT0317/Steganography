`timescale 1ns / 1ps

module control_unit
#(		
		parameter REG_WIDTH = 32
	)
	(
		// Register bank
		input [REG_WIDTH-1 : 0] control_signal,
		input [REG_WIDTH-1 : 0] picture_size,
		input [REG_WIDTH-1 : 0] message_size,
		output reg [REG_WIDTH-1 : 0] respond_signal,
		
		// Control signal
		input out_finish,
		output reset,
		output start,
		output sgp_mode,
		output ps_enb,
		output reg out_sel,
		output reg [REG_WIDTH-1 : 0] pixel_size,
		output reg [REG_WIDTH-1 : 0] secret_size,
		output reg [REG_WIDTH-1 : 0] output_size
	);
	
	/* NOTE
	// signal 0: reset
	// signal 1: start
	// signal 2: sgp mode
	// signal 3: ps_enb
	*/	
	assign reset = ~control_signal[0];
	assign start = control_signal[1];
	assign sgp_mode = control_signal[2];
	assign ps_enb = control_signal[3];
	
	always @(*) begin
		if (out_finish)
			respond_signal[0] <= 1;
		else
			respond_signal[0] <= 0;
	end
	
	always @(*) begin
	   case (sgp_mode)
	       1'b0: begin
	           pixel_size <= (message_size * 6);
	           secret_size <= message_size;
	           output_size <= (message_size * 6);
	           out_sel <= 1'b0;
	       end
	       1'b1: begin
	           pixel_size <= (message_size * 6);
	           secret_size <= 0;
	           output_size <= message_size;
	           out_sel <= 1'b1;
	       end
	   endcase
	end
endmodule