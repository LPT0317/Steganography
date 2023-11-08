`timescale 1ns / 1ps

module fifo_out
    #(
        parameter DATA_WIDTH = 32,
        parameter ADDR_WIDTH = 3,
        parameter PIXEL_WIDTH = 8,
        localparam FIFO_DEPTH = 1 << ADDR_WIDTH
    )
    (
        clk,
        rst,
        // Reading
        dout,
        rd_req,
        rd_vld,
        // Writing
        din1,
        din2,
        din3,
        wr_req,
        wr_vld
    );
    
    // Port declarations
    input clk;
    input rst;
    // Reading
    input rd_req;
    output [DATA_WIDTH-1 : 0]dout;
    output rd_vld;
    // Writing
    input [PIXEL_WIDTH-1 : 0]din1;
    input [PIXEL_WIDTH-1 : 0]din2;
    input [PIXEL_WIDTH-1 : 0]din3;
    input wr_req;
    output wr_vld;
    
    // Internal register
    reg [PIXEL_WIDTH-1 : 0]mem[FIFO_DEPTH - 1 : 0];
    reg [ADDR_WIDTH : 0]rd_ptr;
    reg [ADDR_WIDTH : 0]wr_ptr;
    reg [ADDR_WIDTH : 0]counter;
    wire [ADDR_WIDTH-1 : 0]full_data;
    
    wire [ADDR_WIDTH-1 : 0]wr_addr1;
    wire [ADDR_WIDTH-1 : 0]wr_addr2;
    wire [ADDR_WIDTH-1 : 0]wr_addr3;    
    wire [ADDR_WIDTH-1 : 0]rd_addr1;
    wire [ADDR_WIDTH-1 : 0]rd_addr2;
    wire [ADDR_WIDTH-1 : 0]rd_addr3;  
    wire [ADDR_WIDTH-1 : 0]rd_addr4;   
    
    reg [DATA_WIDTH-1 : 0]data_out;
    
    wire rd_en;
    wire wr_en;
    
    // Assign
    assign dout = data_out;
    assign full_data = ~0;
    assign rd_vld = (counter > 3) & (rd_ptr != wr_ptr);
    assign wr_vld = (counter[ADDR_WIDTH-1 : 0] <= (full_data-2)) & (counter[ADDR_WIDTH] != 1'b1);
    assign wr_en = wr_vld & wr_req;
    assign rd_en = rd_vld & rd_req;
    assign wr_addr1 = wr_ptr[ADDR_WIDTH-1 : 0];
    assign wr_addr2 = wr_ptr[ADDR_WIDTH-1 : 0] + 1;
    assign wr_addr3 = wr_ptr[ADDR_WIDTH-1 : 0] + 2;   
    assign rd_addr1 = rd_ptr[ADDR_WIDTH-1 : 0];  
    assign rd_addr2 = rd_ptr[ADDR_WIDTH-1 : 0] + 1;   
    assign rd_addr3 = rd_ptr[ADDR_WIDTH-1 : 0] + 2;   
    assign rd_addr4 = rd_ptr[ADDR_WIDTH-1 : 0] + 3; 
    
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
        end
        else begin
            if (wr_en) begin
                mem[wr_addr1] <= din1;
                mem[wr_addr2] <= din2;
                mem[wr_addr3] <= din3;
                counter <= counter + 3;
                wr_ptr <= wr_ptr + 3;
            end
            else if (rd_en) begin
                data_out <= {mem[rd_addr1],mem[rd_addr2],mem[rd_addr3],mem[rd_addr4]};
                counter <= counter - 4;
                rd_ptr <= rd_ptr + 4;
            end             
            else begin
                for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
                    mem[i] <= mem[i];
                end
            end            
        end
    end
endmodule