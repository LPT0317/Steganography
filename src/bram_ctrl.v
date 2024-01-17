`timescale 1ns / 1ps

module bram_ctrl #
    (
        parameter ADDR_WIDTH = 32,
		parameter DATA_WIDTH = 32,
		parameter NUM_BYTES = 4
    )
    (
        input ps_enb,
		// BRAM PORTA interface
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *)
		output reg en,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *)
		input [DATA_WIDTH-1 : 0] rddata,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *)
		output reg [DATA_WIDTH-1 : 0] wrdata,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *)
		output reg [NUM_BYTES-1 : 0] we,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *)
		output reg [ADDR_WIDTH-1 : 0] addr,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *)
		output reg clk,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTA RST" *)
		output reg rst,
		// BRAM control with ps
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA EN" *)
		input ps_en,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA DOUT" *)
		output reg [DATA_WIDTH-1 : 0] ps_dout,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA DIN" *)
		input [DATA_WIDTH-1 : 0] ps_din,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA WE" *)
		input [NUM_BYTES-1 : 0] ps_we,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA ADDR" *)
		input [ADDR_WIDTH-1 : 0] ps_addr,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA CLK" *)
		input ps_clk,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLA RST" *)
		input ps_rst,
		// BRAM control with pl
		(* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 262144,READ_WRITE_MODE READ_WRITE" *)
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB EN" *)
		input pl_en,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB DOUT" *)
		output reg [DATA_WIDTH-1 : 0] pl_dout,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB DIN" *)
		input [DATA_WIDTH-1 : 0] pl_din,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB WE" *)
		input [NUM_BYTES-1 : 0] pl_we,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB ADDR" *)
		input [ADDR_WIDTH-1 : 0] pl_addr,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB CLK" *)
		input pl_clk,
		(* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_CTRLB RST" *)
		input pl_rst
    );
    
    always @(*) begin
        case (ps_enb)
        1'b0: begin
            clk <= pl_clk;
			addr <= pl_addr;
			wrdata <= pl_din;
			en <= pl_en;
			rst <= pl_rst;
			we <= pl_we;
			pl_dout <= rddata;
        end
        1'b1: begin
            clk <= ps_clk;
			addr <= ps_addr;
			wrdata <= ps_din;
			en <= ps_en;
			rst <= ps_rst;
			we <= ps_we;
			ps_dout <= rddata;
        end
        endcase
    end
endmodule
