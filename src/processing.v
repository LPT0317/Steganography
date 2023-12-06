`timescale 1ns / 1ps

module pixel_processing
		#(
			parameter FF_DATA_WIDTH = 8
		)
    (
        input clk,
        input rst_n,
        input mode,
        // FIFO pixel input
        input [FF_DATA_WIDTH-1 : 0]ff_pixel_data,
        input ff_pixel_empty,
        output reg ff_pixel_rd,
        // FIFO message input
        input [FF_DATA_WIDTH-1 : 0]ff_mess_data,
        input ff_mess_empty,
        output reg ff_mess_rd,
        // FIFO output
        input ff_full,
        output reg [FF_DATA_WIDTH-1 : 0]ff_data,
        output reg ff_wr
    );
    
    // Mode define
    localparam MODE_EMB = 1'b0;
		localparam MODE_EXT = 1'b1;
    // General state
    localparam INITIAL = 0;
    // Reading FF state
    localparam WAIT_FF = 1;
    localparam RD_FF = 2;
    localparam WAIT_NEXT = 3;
    // Processing state
    localparam START = 1;
    localparam WAIT_DATA = 2;
    localparam PIX_PRE_PROCESS = 3;
    localparam F_CALCULATION = 4;
    localparam COMPARE_F = 5;
    localparam F4_CALCULATION = 6;
    localparam EMBEDDED = 7;
    localparam WR_DATA = 8;
    // Writing FF state
    localparam WAIT_OUTPUT = 1;
    localparam TAKE_DATA = 2;
    localparam WR_FF = 3;
    
    // Internal signal
		reg rd_pixel;
		reg rd_mess;
		reg pixel_fn;
		reg mess_fn;
		reg process_fn;
		reg rd_data;
			
		// Internal register
		reg [FF_DATA_WIDTH-1 : 0]pixel[2:0];
		reg [3:0]message[1:0];
		reg [1:0]pixel_counter;
		reg [31:0]g_chanel[2:0];
		reg [31:0]secret;
		reg ps_counter;
		reg [31:0]res_f;
		reg [31:0]res_s;
		reg [31:0]res_f4[2:0];
		reg [FF_DATA_WIDTH-1 : 0]pixel_emb[2:0];
		reg [FF_DATA_WIDTH-1 : 0]mess_ext;
		reg [FF_DATA_WIDTH-1 : 0]pixel_output[2:0];
		reg [FF_DATA_WIDTH-1 : 0]mess_output;
		reg [1:0]wr_counter;
    
    /* -------------------------------------------------------
		// Reading pixel block
    // ------------------------------------------------------- */ 
    wire [1:0] pix_curr;
    reg [1:0] pix_next;
    assign pix_curr = pix_next;
    always @(posedge clk)
    	if (!rst_n) begin
    		pix_next <= INITIAL;
			end
			else begin
    		case (pix_curr)
    			INITIAL: begin
    				ff_pixel_rd <= 0;
    				pixel[0] <= 0;
    				pixel[1] <= 0;
    				pixel[2] <= 0;
    				pixel_counter <= 0;
    				pixel_fn <= 0;
    				if (rd_pixel)
    					pix_next <= WAIT_FF;
						else
    					pix_next <= INITIAL;
    			end
    			WAIT_FF: begin
						pixel_fn <= 0;
    				if (ff_pixel_empty) begin
    					ff_pixel_rd <= 0;
    					pix_next <= WAIT_FF;
    				end
    				else begin
							ff_pixel_rd <= 1;
							pix_next <= RD_FF;
    				end
    			end
    			RD_FF: begin
    				ff_pixel_rd <= 0;
    				pixel[pixel_counter] <= ff_pixel_data;
    				pixel_counter <= pixel_counter + 1;
    				if (pixel_counter + 1 == 3)
    					pix_next <= WAIT_NEXT;
						else
    					pix_next <= WAIT_FF;
    			end
    			WAIT_NEXT: begin
    				pixel_fn <= 1;
    				pixel_counter <= 0;
    				if (rd_pixel)
    					pix_next <= WAIT_FF;
						else
    					pix_next <= WAIT_NEXT; 
    			end
    			default:
    				pix_next <= INITIAL;
    		endcase
			end
			
		/* -------------------------------------------------------
		// Reading message block
		// ------------------------------------------------------- */
	 	wire [1:0] mess_curr;
		reg [1:0] mess_next;
		assign mess_curr = mess_next;
		always @(posedge clk)
			if (!rst_n) begin
				mess_next <= INITIAL;
			end
			else begin
				case (mess_curr)
					INITIAL: begin
						ff_mess_rd <= 0;
						message[0] <= 0;
						message[1] <= 0;
						mess_fn <= 0;
						if (rd_mess)
							mess_next <= WAIT_FF;
						else
							mess_next <= INITIAL;
					end
					WAIT_FF: begin
						mess_fn <= 0;
						if (ff_mess_empty) begin
							ff_mess_rd <= 0;
							mess_next <= WAIT_FF;
						end
						else begin
							ff_mess_rd <= 1;
							mess_next <= RD_FF;
						end
					end
					RD_FF: begin
						ff_mess_rd <= 0;
						message[0] <= ff_mess_data[7:4];
						message[1] <= ff_mess_data[3:0];
						mess_next <= WAIT_NEXT;
					end
					WAIT_NEXT: begin
						mess_fn <= 1;
						if (rd_mess)
							mess_next <= WAIT_FF;
						else
							mess_next <= WAIT_NEXT; 
					end
					default:
    				mess_next <= INITIAL;
				endcase
			end
			
		/* -------------------------------------------------------
		// Processing block
		// ------------------------------------------------------- */
		wire [4:0] ps_curr;
		reg [4:0] ps_next;
		assign ps_curr = ps_next;
		always @(posedge clk)
			if (!rst_n) begin
				ps_next <= INITIAL;
			end
			else begin
				case (ps_curr)
					INITIAL: begin
						for (integer i=0; i<3; i=i+1)
							g_chanel[i] <= 0;
						secret <= 0;
						rd_pixel <= 0;
						rd_mess <= 0;
						ps_counter <= 0;
						res_f <= 0;
						process_fn <= 0;
						ps_next <= START;
					end
					START: begin
						process_fn <= 0;
						if (mode == MODE_EMB) begin
							rd_pixel <= 1;
							rd_mess <= 1;
						end
						else begin
							rd_pixel <= 1;
							rd_mess <= 0;
						end
						ps_next <= WAIT_DATA;
					end
					WAIT_DATA: begin
						process_fn <= 0;										
						if (mode == MODE_EMB && pixel_fn && mess_fn) begin
							for (integer i=0; i<3; i=i+1)
								g_chanel[i] <= {24'b0,{pixel[i]}};
							secret <= {28'b0,{message[ps_counter]}};
							rd_pixel <= 1;
							rd_mess <= 1;
							ps_next <= PIX_PRE_PROCESS;
						end
						else if (mode == MODE_EXT && pixel_fn) begin
							for (integer i=0; i<3; i=i+1)
								g_chanel[i] <= {24'b0,{pixel[i]}};
							rd_pixel <= 1;
							rd_mess <= 0;
							ps_next <= F_CALCULATION;					
						end
						else begin
							rd_pixel <= 0;
							rd_mess <= 0;
							ps_next <= WAIT_DATA;			
						end
					end
					PIX_PRE_PROCESS: begin
						for (integer i=0; i<3; i=i+1) begin
							if (g_chanel[i] == 255)
								g_chanel[i] <= 254;
							else if (g_chanel[i] == 0)
								g_chanel[i] <= 1;
							else
								g_chanel[i] <= g_chanel[i];
						end
						ps_next <= F_CALCULATION;
					end
					F_CALCULATION: begin
						res_f <= (g_chanel[0] + g_chanel[1] * 3 + g_chanel[2] * 9) % 27;
						if (mode == MODE_EMB)
							ps_next <= COMPARE_F;
						else
							ps_next <= WR_DATA;
					end
					COMPARE_F: begin
						if (res_f == secret) begin
							ps_next <= WR_DATA;
						end
						else begin
							res_s <= ((secret - res_f) + 27) % 27;
							ps_next <= F4_CALCULATION;
						end
					end
					F4_CALCULATION: begin
						res_f4[0] <= (res_s - 1) % 3;
						res_f4[1] <= ((res_s - 2) / 3) % 3;
						res_f4[2] <= ((res_s - 5) / 9) % 3;
						ps_next <= EMBEDDED;
					end
					EMBEDDED: begin
						for (integer i=0; i<3; i=i+1) begin
							if (res_f4[i] == 0 && res_s > (3**i - 1) / 2)
								g_chanel[i] <= g_chanel[i] + 1;
							else if (res_f4[i] == 1 && res_s > (3**i - 1) / 2)
								g_chanel[i] <= g_chanel[i] - 1;
							else
								g_chanel[i] <= g_chanel[i];
						end
						ps_next <= WR_DATA;
					end
					WR_DATA: begin
						if (mode == MODE_EMB) begin
							for (integer i=0; i<3; i=i+1)
								pixel_emb[i] <= g_chanel[i];
							process_fn <= 1;
						end
						else if (mode == MODE_EXT && ps_counter == 0) begin
							process_fn <= 0;
							ps_counter <= 1;
							mess_ext[7:4] <= res_f[3:0];
						end
						else if (mode == MODE_EXT && ps_counter == 1) begin
							process_fn <= 1;
							ps_counter <= 0;
							mess_ext[3:0] <= res_f[3:0];
						end
						if (mode == MODE_EMB && rd_data) begin
							ps_next <= WAIT_DATA;
						end
						else if (mode == MODE_EXT && rd_data && ps_counter == 1) begin
							ps_next <= WAIT_DATA;
						end
						else
							ps_next <= WR_DATA;
					end
					default:
						ps_next <= INITIAL;
				endcase
			end
			
		/* -------------------------------------------------------
		// Writing data output
		// ------------------------------------------------------- */
		wire [1:0] wr_curr;
		reg [1:0] wr_next;
		assign wr_curr = wr_next;
		always @(posedge clk)
			if (!rst_n)
				wr_next <= INITIAL;
			else begin
				case (wr_curr)
					INITIAL: begin
						rd_data <= 0;
						ff_wr <= 0;
						ff_data <= 0;
						for (integer i=0; i<3; i=i+1)
							pixel_output[i] <= 0;
						mess_output <= 0;
						wr_counter <= 0;
						wr_next <= WAIT_OUTPUT;
					end
					WAIT_OUTPUT: begin
						ff_wr <= 0;
						if (process_fn == 1 && mode == MODE_EMB) begin
							rd_data <= 1;
							for (integer i=0; i<3; i=i+1)
								pixel_output[i] <= pixel_emb[i];
							wr_next <= WR_FF;
						end
						else if (process_fn == 1 && mode == MODE_EXT) begin
							rd_data <= 1;
							mess_output <= mess_ext;
							wr_next <= WR_FF;
						end
						else begin
							rd_data <= 0;
							wr_next <= WAIT_OUTPUT;
						end
					end
					WR_FF: begin
						rd_data <= 0;
						if (!ff_full && mode == MODE_EMB && wr_counter + 1 < 3) begin
							ff_wr <= 1;
							ff_data <= pixel_output[wr_counter];
							wr_counter <= wr_counter + 1;
							wr_next <= WR_FF;
						end
						else if (!ff_full && mode == MODE_EMB && wr_counter + 1 == 3) begin
							ff_wr <= 1;
							ff_data <= pixel_output[wr_counter];
							wr_counter <= 0;
							wr_next <= WAIT_OUTPUT;
						end
						else if (!ff_full && mode == MODE_EXT) begin
							ff_wr <= 1;
							ff_data <= mess_output;
							wr_next <= WAIT_OUTPUT;
						end
						else begin						
							ff_wr <= 0;
							wr_next <= WR_FF;
						end
					end
					default:
						wr_next <= INITIAL;
				endcase
			end
endmodule
