`timescale 1ns / 1ps

    module bram_ctrl 
    #(
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32,
        parameter NUM_BYTES = 4 
    )
    (
        clk,
        // BRAM side
        bram_clkb,
        bram_doutb,
        bram_addrb,
        bram_dinb,
        bram_enb,
        bram_rstb,
        bram_web,
        // User side
        wren,
        din,
        addr,
        dout
    );
    
    // Port declarations
    input clk;
    // BRAM side
    output bram_clkb;
    input [DATA_WIDTH - 1 : 0]bram_doutb;
    output [ADDR_WIDTH - 1 : 0]bram_addrb;
    output [DATA_WIDTH - 1 : 0]bram_dinb;
    output bram_enb;
    output bram_rstb;
    output [NUM_BYTES - 1 : 0]bram_web;
    // User side
    input wren;
    input [DATA_WIDTH - 1 : 0]din;
    input [ADDR_WIDTH - 1 : 0]addr;
    output [DATA_WIDTH - 1 : 0]dout;
    
    // State
    localparam INITIAL = 0;
    localparam ADDR = 1;
    localparam DATA = 3;
    
    // Internal register and wire
    
    // Assign
    assign bram_clkb = clk;
    assign bram_rstb = 1'b0;
    assign bram_enb = 1'b1;
    assign bram_addrb = addr << 2;
    assign bram_web = {4{wren}};
    assign bram_dinb = din;
    assign dout = bram_doutb;
    
    // FSM Read data
    
endmodule