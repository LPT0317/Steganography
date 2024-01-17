`timescale 1ns / 1ps
module steganography #
    (
        parameter DATA_WIDTH = 32,
        parameter ADDR_WIDTH = 32,
        parameter NUM_BYTES = 4,
        parameter REG_WIDTH = 32,
        parameter FF_WIDTH = 8
    )
    (        
        input sys_clk,
        output ps_enb,
		// DEBUG SIGNAL
		output [REG_WIDTH-1 : 0] debug_data1,
		output [REG_WIDTH-1 : 0] debug_data2,
        // Register bank        
		(* X_INTERFACE_INFO = "xilinx.com:user:register_signal:1.0 SLAVE_SIGNAL control_signal" *)
		input [REG_WIDTH-1 : 0] control_signal,
		(* X_INTERFACE_INFO = "xilinx.com:user:register_signal:1.0 SLAVE_SIGNAL picture_size" *)
		input [REG_WIDTH-1 : 0] picture_size,
		(* X_INTERFACE_INFO = "xilinx.com:user:register_signal:1.0 SLAVE_SIGNAL message_size" *)
		input [REG_WIDTH-1 : 0] message_size,
		(* X_INTERFACE_INFO = "xilinx.com:user:register_signal:1.0 SLAVE_SIGNAL respond_signal" *)
		output [REG_WIDTH-1 : 0] respond_signal,
		// BRAM IN IMAGE
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEA EN" *)
		output image_ena,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEA DOUT" *)
		input [DATA_WIDTH-1 : 0] image_rddataa,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEA WE" *)
		output [NUM_BYTES-1 : 0] image_wea,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEA ADDR" *)
		output [ADDR_WIDTH-1 : 0] image_addra,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEA CLK" *)
		output image_clka,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEA RST" *)
		output image_rsta,
		// BRAM IN SECRET
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETA EN" *)
		output secret_ena,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETA DOUT" *)
		input [DATA_WIDTH-1 : 0] secret_rddataa,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETA WE" *)
		output [NUM_BYTES-1 : 0] secret_wea,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETA ADDR" *)
		output [ADDR_WIDTH-1 : 0] secret_addra,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETA CLK" *)
		output secret_clka,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETA RST" *)
		output secret_rsta,
		// BRAM OUT IMAGE
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEB EN" *)
		output image_enb,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEB DIN" *)
		output [DATA_WIDTH-1 : 0] image_wrdatab,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEB WE" *)
		output [NUM_BYTES-1 : 0] image_web,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEB ADDR" *)
		output [ADDR_WIDTH-1 : 0] image_addrb,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEB CLK" *)
		output image_clkb,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IMAGEB RST" *)
		output image_rstb,
		// BRAM OUT SECRET
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETB EN" *)
		output secret_enb,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETB DIN" *)
		output [DATA_WIDTH-1 : 0] secret_wrdatab,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETB WE" *)
		output [NUM_BYTES-1 : 0] secret_web,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETB ADDR" *)
		output [ADDR_WIDTH-1 : 0] secret_addrb,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETB CLK" *)
		output secret_clkb,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_SECRETB RST" *)
		output secret_rstb
    );
    
    // CONTROL SIGNAL
    wire out_finish;
    wire rst_n;
    wire start;
    wire out_sel;
    wire mode;
    wire [REG_WIDTH-1 : 0] image_size;
    wire [REG_WIDTH-1 : 0] secret_size;
    wire [REG_WIDTH-1 : 0] output_size;
    
    // FIFO IMAGE
    wire ff_image_full;
    wire ff_image_empty;
    wire ff_image_wren;
    wire ff_image_rden;
    wire [FF_WIDTH-1 : 0] ff_image_wrdata;
    wire [FF_WIDTH-1 : 0] ff_image_rddata;
    
    // FIFO SECRET
    wire ff_secret_full;
    wire ff_secret_empty;
    wire ff_secret_wren;
    wire ff_secret_rden;
    wire [FF_WIDTH-1 : 0] ff_secret_wrdata;
    wire [FF_WIDTH-1 : 0] ff_secret_rddata;
    
    //FIFO OUT
    wire ff_out_full;
    wire ff_out_empty;
    wire ff_out_wren;
    wire ff_out_rden;
    wire [FF_WIDTH-1 : 0] ff_out_wrdata;
    wire [FF_WIDTH-1 : 0] ff_out_rddata;
    
    // OUTPUT 
    /*wire o_clk;
    wire [DATA_WIDTH-1 : 0] o_wrdata;
    wire [ADDR_WIDTH-1 : 0] o_addr;
    wire [NUM_BYTES-1 : 0] o_we;*/
    
    
    assign image_rsta = 1'b0;
    assign image_ena = 1'b1;
    assign image_rstb = 1'b0;
    assign image_enb = 1'b1;
    assign secret_rsta = 1'b0;
    assign secret_ena = 1'b1;
    assign secret_rstb = 1'b0;
    assign secret_enb = 1'b1;
    
    // DEBUG
    assign debug_data2[0] = out_sel;
    assign debug_data2[1] = ff_image_empty;
    assign debug_data2[2] = ff_secret_empty;
    assign debug_data2[3] = ff_out_empty;
    
    
    control_unit control_unit  
        (.control_signal(control_signal),
        .picture_size(picture_size),
        .message_size(message_size),
        .respond_signal(respond_signal),
        .out_finish(out_finish),
        .reset(rst_n),
        .start(start),
        .sgp_mode(mode),
        .ps_enb(ps_enb),
        .out_sel(out_sel),
        .pixel_size(image_size),
        .secret_size(secret_size),
        .output_size(output_size)
        );
    
    ctrl_rd_bram rd_bram_image
        (.clk(sys_clk),
		.rst_n(rst_n),
		.finish(),
		.start(start),
		.data_size(image_size),
		.bram_clk(image_clka),
		.rddata(image_rddataa),
		.addr(image_addra),
		.we(image_wea),
		.ff_full(ff_image_full),
		.ff_wren(ff_image_wren),
		.ff_wr_data(ff_image_wrdata)
        );
    ctrl_rd_bram rd_bram_secret
        (.clk(sys_clk),
		.rst_n(rst_n),
		.finish(),
		.start(start),
		.data_size(secret_size),
		.bram_clk(secret_clka),
		.rddata(secret_rddataa),
		.addr(secret_addra),
		.we(secret_wea),
		.ff_full(ff_secret_full),
		.ff_wren(ff_secret_wren),
		.ff_wr_data(ff_secret_wrdata)
        );
    fifo ff_image
        (.clk(sys_clk),
		.rst_n(rst_n),
		.rden(ff_image_rden),
		.dout(ff_image_rddata),
		.empty(ff_image_empty),
		.wren(ff_image_wren),
		.din(ff_image_wrdata),
		.full(ff_image_full)
        );
    fifo ff_secret
        (.clk(sys_clk),
		.rst_n(rst_n),
		.rden(ff_secret_rden),
		.dout(ff_secret_rddata),
		.empty(ff_secret_empty),
		.wren(ff_secret_wren),
		.din(ff_secret_wrdata),
		.full(ff_secret_full)
        );
    sgpp sgpp_1
        (.clk(sys_clk),
        .rst_n(rst_n),
        .start(start),
        .sgp_mode(mode),
        .debug_data(debug_data1),
        .ff_image_empty(ff_image_empty),
        .ff_rdimage(ff_image_rddata),
        .ff_image_rden(ff_image_rden),
        .ff_secret_empty(ff_secret_empty),
        .ff_rdsecret(ff_secret_rddata),
        .ff_secret_rden(ff_secret_rden),
        .ff_out_full(ff_out_full),
        .ff_out_wrdata(ff_out_wrdata),
        .ff_out_wren(ff_out_wren)
        );
    fifo ff_out
        (.clk(sys_clk),
		.rst_n(rst_n),
		.rden(ff_out_rden),
		.dout(ff_out_rddata),
		.empty(ff_out_empty),
		.wren(ff_out_wren),
		.din(ff_out_wrdata),
		.full(ff_out_full)
        );
    /*test_ff test_1
        (.clk(sys_clk),
        .rst_n(rst_n),
        .active(start),
        .ff_rd_data(ff2_rddata),
        .ff_empty(ff2_empty),
        .ff_rden(ff2_rden),
        .data(debug_data)
        );*/
    ctrl_wr_bram wr_bram_1
        (.clk(sys_clk),
		.rst_n(rst_n),
		.finish(out_finish),
		.sel(out_sel),
		.start(start),
		.data_size(output_size),
		.image_clk(image_clkb),
		.image_wrdata(image_wrdatab),
		.image_addr(image_addrb),
		.image_we(image_web),
		.secret_clk(secret_clkb),
		.secret_wrdata(secret_wrdatab),
		.secret_addr(secret_addrb),
		.secret_we(secret_web),
		.ff_empty(ff_out_empty),
		.ff_rd_data(ff_out_rddata),
		.ff_rden(ff_out_rden)
        );
endmodule
