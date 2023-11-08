`timescale 1ns / 1ps


    module fifo_mess
    #(
        parameter DATA_WIDTH = 32,
        parameter ADDR_WIDTH = 3,
        parameter MESS_WIDTH = 4
    )
    (
        clk,
        rst,
        // Reading
        dout,
        rd_req,
        empty,
        dout_vld,
        // Writing
        din,
        wr_req,
        full
    );
    
    // Port declarations
    input clk;
    input rst;
    // Reading
    input rd_req;
    output [MESS_WIDTH-1 : 0]dout;
    output empty;
    output dout_vld;
    // Writing
    input [DATA_WIDTH-1 : 0]din;
    input wr_req;
    output full;
    
    //Local Parameter    
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    
    // Internal register
    reg [DATA_WIDTH - 1 : 0]mem[FIFO_DEPTH - 1 : 0];
    reg [ADDR_WIDTH : 0] rd_ptr;
    reg [ADDR_WIDTH : 0] wr_ptr;
    reg [3 : 0]counter;
    wire wr_en;
    wire rd_en;    
    
    reg [MESS_WIDTH - 1 : 0]data_out;
    reg dout_vld_reg;
    
    // Assign
    assign dout = data_out;
    assign dout_vld = dout_vld_reg;
    assign full = ({~wr_ptr[ADDR_WIDTH],wr_ptr[ADDR_WIDTH-1:0]} == rd_ptr);
    assign empty = (wr_ptr == rd_ptr);
    
    assign wr_en = (~full & wr_req);
    assign rd_en = (~empty & rd_req);
    
    
    // Memory
    always @(posedge clk) begin
        if (!rst) begin
            for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
                mem[i] <= 0;
            end      
            counter <= 0;      
            rd_ptr <= 0;
            wr_ptr <= 0;
            data_out <= 0;
            dout_vld_reg <= 0;
        end
        else begin
            if (wr_en) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                dout_vld_reg <= 0;
                wr_ptr <= wr_ptr + 1;                
            end
            else if (rd_en) begin
                data_out <= mem[rd_ptr][MESS_WIDTH - 1 : 0];
                mem[rd_ptr] <= mem[rd_ptr] >> 4;
                dout_vld_reg <= 1;
                counter <= counter + 1;
                if (counter + 1 == 0)
                    rd_ptr <= rd_ptr + 1;
                else
                    rd_ptr <= rd_ptr;             
            end             
            else begin
                for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
                    mem[i] <= mem[i];
                end
                dout_vld_reg <= 0;
            end            
        end
    end
endmodule