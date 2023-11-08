`timescale 1ns / 1ps

module pixel_processing
#(
    parameter PIXEL_WIDTH = 32,
    parameter MESS_WIDTH = 4
)
(
    clk,
    rst,
    mode,
    start,
    g1_in,
    g2_in,
    g3_in,
    secret,
    g1_out,
    g2_out,
    g3_out,
    mess,
    vld,
    run
);
    
    // Port declaration
    input clk;
    input rst;
    input mode;
    input start;
    input [PIXEL_WIDTH - 1 : 0]g1_in;
    input [PIXEL_WIDTH - 1 : 0]g2_in;
    input [PIXEL_WIDTH - 1 : 0]g3_in;
    input [MESS_WIDTH - 1 : 0]secret;
    
    output [PIXEL_WIDTH - 1 : 0]g1_out;
    output [PIXEL_WIDTH - 1 : 0]g2_out;
    output [PIXEL_WIDTH - 1 : 0]g3_out;
    output [MESS_WIDTH - 1 : 0]mess;
    output vld;
    output run;
    
    // State
    localparam INITIAL = 4'd0;
    localparam MODE_SEL = 4'd1;
    localparam PRE = 4'd2;
    localparam CALC_F = 4'd3;
    localparam COMPARATOR = 4'd4;
    localparam CALC_S = 4'd5;
    localparam CALC_F4 = 4'd6;
    localparam EMBED = 4'd7;
    localparam VALID = 4'd8;
    
    // Internal register wire
    wire [3:0] current_state;
    reg [3:0] next_state;
    reg [PIXEL_WIDTH - 1 : 0]reg_g1_in;
    reg [PIXEL_WIDTH - 1 : 0]reg_g2_in;
    reg [PIXEL_WIDTH - 1 : 0]reg_g3_in;    
    reg [PIXEL_WIDTH - 1 : 0]reg_secret;
    reg [PIXEL_WIDTH - 1 : 0]reg_g1_out;
    reg [PIXEL_WIDTH - 1 : 0]reg_g2_out;
    reg [PIXEL_WIDTH - 1 : 0]reg_g3_out;
    reg [MESS_WIDTH - 1 : 0]reg_mess;
    reg reg_vld;
    reg reg_run;
    
    reg [PIXEL_WIDTH - 1 : 0]reg_g1;
    reg [PIXEL_WIDTH - 1 : 0]reg_g2;
    reg [PIXEL_WIDTH - 1 : 0]reg_g3;
    reg [PIXEL_WIDTH - 1 : 0]f;
    reg compare;
    reg [PIXEL_WIDTH - 1 : 0]s;
    reg [PIXEL_WIDTH - 1 : 0]f4_g1;
    reg [PIXEL_WIDTH - 1 : 0]f4_g2;
    reg [PIXEL_WIDTH - 1 : 0]f4_g3;
    reg [PIXEL_WIDTH - 1 : 0]reg_g1_calc;
    reg [PIXEL_WIDTH - 1 : 0]reg_g2_calc;
    reg [PIXEL_WIDTH - 1 : 0]reg_g3_calc;
    
    // Assign
    assign g1_out = reg_g1_out;
    assign g2_out = reg_g2_out;
    assign g3_out = reg_g3_out;
    assign mess = reg_mess;
    assign vld = reg_vld;
    assign run = reg_run;
    assign current_state = next_state;
    
    // FSM
    always @(posedge clk) begin
        if (!rst) begin
            next_state <= INITIAL;
            reg_g1_out <= 0;
            reg_g2_out <= 0;
            reg_g3_out <= 0;
            reg_mess <= 0;
            reg_vld <= 0;
            reg_run <= 0;
        end
        else begin
            case(current_state)
                INITIAL: begin
                    reg_vld <= 0;
                    reg_run <= 0;
                    if (start) 
                        next_state <= MODE_SEL;
                    else 
                        next_state <= INITIAL;
                end
                MODE_SEL: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    if (mode) begin
                        reg_g1 <= g1_in;
                        reg_g2 <= g2_in;
                        reg_g3 <= g3_in;
                        reg_secret <= 0;
                        next_state <= CALC_F;
                    end
                    else begin
                        reg_g1_in <= g1_in;
                        reg_g2_in <= g2_in;
                        reg_g3_in <= g3_in;
                        reg_secret <= {{28{1'b0}},secret};
                        next_state <= PRE;
                    end
                end
                PRE: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    if (reg_g1_in == 255)
                        reg_g1 <= 254;
                    else if (reg_g1_in == 0)
                        reg_g1 <= 1;
                    else
                        reg_g1 <= reg_g1_in;
                    if (reg_g2_in == 255)
                        reg_g2 <= 254;
                    else if (reg_g2_in == 0)
                        reg_g2 <= 1;
                    else
                        reg_g2 <= reg_g2_in;
                    if (reg_g3_in == 255)
                        reg_g3 <= 254;
                    else if (reg_g3_in == 0)
                        reg_g3 <= 3;
                    else
                        reg_g3 <= reg_g3_in;
                    next_state <= CALC_F;
                end
                CALC_F: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    f <= (reg_g1 + reg_g2 * 3 + reg_g3 * 9) % 27;
                    if (mode)
                        next_state <= VALID;
                    else
                        next_state <= COMPARATOR;
                end
                COMPARATOR: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    if (f == reg_secret) begin
                        next_state <= VALID;
                        compare <= 1;
                    end
                    else begin
                        next_state <= CALC_S;
                        compare <= 0;
                    end
                end
                CALC_S: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    s <= ((reg_secret - f) + 27) % 27;
                    next_state <= CALC_F4;
                end
                CALC_F4: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    f4_g1 <= (s - 1) % 3;
                    f4_g2 <= ((s - 2) / 3) % 3;
                    f4_g3 <= ((s - 5) / 9) % 3;
                    next_state <= EMBED;
                end
                EMBED: begin
                    reg_vld <= 0;
                    reg_run <= 1;
                    if (f4_g1 == 0 && s > 0)
                        reg_g1_calc <= reg_g1 + 1;
                    else if (f4_g1 == 1 && s > 0)
                        reg_g1_calc <= reg_g1 - 1;
                    else
                        reg_g1_calc <= reg_g1;
                    if (f4_g2 == 0 && s > 1)
                        reg_g2_calc <= reg_g2 + 1;
                    else if (f4_g2 == 1 && s > 1)
                        reg_g2_calc <= reg_g2 - 1;
                    else
                        reg_g2_calc <= reg_g2;
                    if (f4_g3 == 0 && s > 4)
                        reg_g3_calc <= reg_g3 + 1;
                    else if (f4_g3 == 1 && s > 4)
                        reg_g3_calc <= reg_g3 - 1;
                    else
                        reg_g3_calc <= reg_g3;
                    next_state <= VALID;
                end
                VALID: begin
                    reg_vld <= 1;
                    reg_run <= 0;
                    if (mode) begin
                        reg_mess <= f[MESS_WIDTH - 1 : 0];
                        reg_g1_out <= 0;
                        reg_g2_out <= 0;
                        reg_g3_out <= 0;
                    end
                    else if (!mode && compare) begin
                        reg_mess <= 0;
                        reg_g1_out <= reg_g1;
                        reg_g2_out <= reg_g2;
                        reg_g3_out <= reg_g3;                        
                    end
                    else if (!mode && !compare) begin
                        reg_mess <= 0;
                        reg_g1_out <= reg_g1_calc;
                        reg_g2_out <= reg_g2_calc;
                        reg_g3_out <= reg_g3_calc;                        
                    end
                    else begin
                        reg_mess <= 0;
                        reg_g1_out <= 0;
                        reg_g2_out <= 0;
                        reg_g3_out <= 0;
                    end
                    if (start)
                        next_state <= MODE_SEL;
                    else
                        next_state <= VALID;
                end
                default:
                    next_state <= INITIAL;
            endcase
        end
    end
    
endmodule