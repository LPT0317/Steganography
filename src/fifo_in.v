`timescale 1ns / 1ps

    module fifo_in
    #(
        parameter DATA_WIDTH = 32,
        parameter ADDR_WIDTH = 3,
        parameter PIXEL_WIDTH = 8        
    )
    (
        clk,
        rst,
        // Reading
        dout1,
        dout2,
        dout3,
        rd_req,
        rd_vld,
        // Writing
        din,
        wr_req,
        wr_vld
    );
    
    // Port declarations
    input clk;
    input rst;
    // Reading
    input rd_req;
    output [PIXEL_WIDTH-1 : 0]dout1;
    output [PIXEL_WIDTH-1 : 0]dout2;
    output [PIXEL_WIDTH-1 : 0]dout3;
    output rd_vld;
    // Writing
    input [DATA_WIDTH-1 : 0]din;
    input wr_req;
    output wr_vld;
    
    //Local Parameter
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    
    // Internal register
    reg [PIXEL_WIDTH-1 : 0]mem[FIFO_DEPTH - 1 : 0];
    reg [ADDR_WIDTH : 0]rd_ptr;
    reg [ADDR_WIDTH : 0]wr_ptr;
    reg [ADDR_WIDTH : 0]counter;
    wire [ADDR_WIDTH-1 : 0]full_data;
    
    wire [ADDR_WIDTH-1 : 0]wr_addr1;
    wire [ADDR_WIDTH-1 : 0]wr_addr2;
    wire [ADDR_WIDTH-1 : 0]wr_addr3; 
    wire [ADDR_WIDTH-1 : 0]wr_addr4;    
    wire [ADDR_WIDTH-1 : 0]rd_addr1;
    wire [ADDR_WIDTH-1 : 0]rd_addr2;
    wire [ADDR_WIDTH-1 : 0]rd_addr3;
    
    reg [DATA_WIDTH-1 : 0]data_out1;
    reg [DATA_WIDTH-1 : 0]data_out2;
    reg [DATA_WIDTH-1 : 0]data_out3;
    
    wire rd_en;
    wire wr_en;
    
    // Assign
    assign dout1 = data_out1;
    assign dout2 = data_out2;
    assign dout3 = data_out3;
    
    assign full_data = ~0;
    assign rd_vld = (counter > 2) & (rd_ptr != wr_ptr);
    assign wr_vld = (counter[ADDR_WIDTH-1 : 0] <= (full_data-3)) & (counter[ADDR_WIDTH] != 1'b1);
    assign wr_en = wr_vld & wr_req;
    assign rd_en = rd_vld & rd_req;
    assign wr_addr1 = wr_ptr[ADDR_WIDTH-1 : 0];
    assign wr_addr2 = wr_ptr[ADDR_WIDTH-1 : 0] + 1;
    assign wr_addr3 = wr_ptr[ADDR_WIDTH-1 : 0] + 2; 
    assign wr_addr4 = wr_ptr[ADDR_WIDTH-1 : 0] + 3; 
    assign rd_addr1 = rd_ptr[ADDR_WIDTH-1 : 0];  
    assign rd_addr2 = rd_ptr[ADDR_WIDTH-1 : 0] + 1;   
    assign rd_addr3 = rd_ptr[ADDR_WIDTH-1 : 0] + 2;
    
    // Memory
    always @(posedge clk) begin
        if (!rst) begin
            for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
                mem[i] <= 0;
            end      
            counter <= 0;
            rd_ptr <= 0;
            wr_ptr <= 0;
            data_out1 <= 0;
            data_out2 <= 0;
            data_out3 <= 0;
        end
        else begin
            if (wr_en) begin
                mem[wr_addr1] <= din[DATA_WIDTH-1:DATA_WIDTH-8];
                mem[wr_addr2] <= din[DATA_WIDTH-9:DATA_WIDTH-16];
                mem[wr_addr3] <= din[DATA_WIDTH-17:DATA_WIDTH-24];
                mem[wr_addr4] <= din[DATA_WIDTH-25:DATA_WIDTH-32];
                counter <= counter + 4;
                wr_ptr <= wr_ptr + 4;
            end
            else if (rd_en) begin                
                data_out1 <= mem[rd_addr1];
                data_out2 <= mem[rd_addr2];
                data_out3 <= mem[rd_addr3];
                counter <= counter - 3;
                rd_ptr <= rd_ptr + 3;
            end             
            else begin
                for (integer i=0; i<FIFO_DEPTH; i=i+1) begin
                    mem[i] <= mem[i];
                end
            end            
        end
    end
endmodule