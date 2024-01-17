`timescale 1ns / 1ps

module sgpp #
    (
        parameter REG_WIDTH = 32,
        parameter FF_WIDTH = 8
    )
    (
        input clk,
        input rst_n,
        input start,
        input sgp_mode,
        // DEBUG
        output [REG_WIDTH-1 : 0] debug_data,
        // FIFO IMAGE IN
        input ff_image_empty,
        input [FF_WIDTH-1 : 0] ff_rdimage,
        output reg ff_image_rden,
        // FIFO SECRET IN
        input ff_secret_empty,
        input [FF_WIDTH-1 : 0] ff_rdsecret,
        output reg ff_secret_rden,
        // FIFO OUT
        input ff_out_full,
        output reg [FF_WIDTH-1 : 0] ff_out_wrdata,
        output reg ff_out_wren
    );
    
    integer i;
    
    // Data transfer
    reg [FF_WIDTH*2-1 : 0] image_data [2 : 0];
    reg [FF_WIDTH*2-1 : 0] secret_data;
    reg [FF_WIDTH*2-1 : 0] pixel [2 : 0];
    reg [FF_WIDTH*2-1 : 0] message;
    reg [FF_WIDTH-1 : 0] wrpixel [2 : 0];
    reg [FF_WIDTH-1 : 0] wrmessage;
    
    // Data signal
    reg imagevld;
    reg secretvld;
    reg rdimage;
    reg rdsecret;
    reg sgpvalid;
    reg rdsgp;
    
    // FSM
    localparam INIT = 3'd0;
    localparam RD_FF = 3'd1;
    localparam LD_FF = 3'd2;
    localparam WR_DATA = 3'd3;
    localparam VALID = 3'd4;
    
    // Reading Image Block
    reg [1:0] image_sel;
    reg [2:0] image_next;
    wire [2:0] image_state;
    
    assign image_state = image_next;
    
    always @(posedge clk) begin
        if (!rst_n)
            image_next <= INIT;
        else begin
            case (image_state)
            INIT: begin
                ff_image_rden <= 1'b0;
                image_sel <= 2'd0;
                for (i=0; i<3; i=i+1)
                    image_data[i] <= {(FF_WIDTH*2){1'b0}};
                imagevld <= 1'b0;
                if (start)
                    image_next <= RD_FF;
                else
                    image_next <= INIT;
            end
            RD_FF: begin
                imagevld <= 1'b0;
                if (ff_image_empty)
                    image_next <= RD_FF;
                else begin
                    ff_image_rden <= 1'b1;
                    image_next <= LD_FF;
                end
            end
            LD_FF: begin
                ff_image_rden <= 1'b0;
                image_next <= WR_DATA;
            end
            WR_DATA: begin
                image_data[image_sel][FF_WIDTH-1 : 0] <= ff_rdimage;
                image_sel <= image_sel + 1;
                if (image_sel == 2'd2)
                    image_next <= VALID;
                else
                    image_next <= RD_FF;
            end
            VALID: begin
                image_sel <= 2'd0;
                imagevld <= 1'b1;
                if (rdimage)
                    image_next <= RD_FF;
                else
                    image_next <= VALID;
            end
            default:
                image_next <= INIT;
            endcase
        end
    end
    
    // Reading Secret Block
    reg [2:0] secret_next;
    wire [2:0] secret_state;
    
    assign secret_state = secret_next;
    
    always @(posedge clk) begin
        if (!rst_n)
            secret_next <= INIT;
        else begin
            case (secret_state)
            INIT: begin
                ff_secret_rden <= 1'b0;
                secret_data <= {(FF_WIDTH*2){1'b0}};
                secretvld <= 1'b0;
                if (start & !sgp_mode)
                    secret_next <= RD_FF;
                else
                    secret_next <= INIT;
            end
            RD_FF: begin
                secretvld <= 1'b0;
                if (ff_secret_empty)
                    secret_next <= RD_FF;
                else begin
                    ff_secret_rden <= 1'b1;
                    secret_next <= LD_FF;
                end
            end
            LD_FF: begin
                ff_secret_rden <= 1'b0;
                secret_next <= WR_DATA;
            end
            WR_DATA: begin
                secret_data[FF_WIDTH-1 : 0] <= ff_rdsecret;
                secret_next <= VALID;
            end
            VALID: begin
                secretvld <= 1'b1;
                if (rdsecret)
                    secret_next <= RD_FF;
                else
                    secret_next <= VALID;
            end
            default:
                secret_next <= INIT;
            endcase
        end
    end
    
    // FSM
    localparam INITIAL = 4'd0;
    localparam WAIT = 4'd1;
    localparam LOAD = 4'd2;
    localparam PRE_PROCESS = 4'd3;
    localparam EXTRACT_FUNCTION = 4'd4;
    localparam DECISION = 4'd5;
    localparam F4_1 = 4'd6;
    localparam F4_2 = 4'd7;
    localparam EMBED = 4'd8;
    localparam DATA_OUT = 4'd9;
    localparam READY = 4'd10;
    
    // Processing data
    reg [FF_WIDTH*2-1 : 0] secret;
    reg [FF_WIDTH*2-1 : 0] image [2 : 0];
    reg [FF_WIDTH*2-1 : 0] res_f;
    reg [FF_WIDTH*2-1 : 0] res_s;
    reg [FF_WIDTH*2-1 : 0] res_secret;
    reg [FF_WIDTH*2-1 : 0] res_f4 [2 : 0];
    
    // Steganography block
    reg sgp_run;
    reg [3:0] sgp_next;
    wire [3:0] sgp_state;
    
    assign sgp_state = sgp_next;
    assign debug_data[3:0] = sgp_state;
    assign debug_data[4] = imagevld;
    assign debug_data[5] = secretvld;
    assign debug_data[6] = sgp_mode & imagevld;
    assign debug_data[7] = sgp_mode && imagevld;
    assign debug_data[8] = sgp_mode;
    
    always @(posedge clk) begin
        if (!rst_n)
            sgp_next <= INITIAL;
        else begin
            case (sgp_state)
            INITIAL: begin
                rdimage <= 1'b0;
                rdsecret <= 1'b0;
                sgpvalid <= 1'b0;
                sgp_run <= 1'b0;
                for (i=0; i<3; i=i+1) begin
                   image[i] <= {(FF_WIDTH*2){1'b0}};
                   pixel[i] <= {(FF_WIDTH*2){1'b0}};
                end
                secret <= {(FF_WIDTH*2){1'b0}};
                res_secret <= {(FF_WIDTH*2){1'b0}};
                res_f <= {(FF_WIDTH*2){1'b0}};
                message <= {(FF_WIDTH*2){1'b0}};
                if (start)
                    sgp_next <= WAIT;
                else
                    sgp_next <= INITIAL;
            end
            WAIT: begin
                sgpvalid <= 1'b0;
                if (!sgp_mode && imagevld && secretvld && !sgp_run)
                    sgp_next <= LOAD;
                else if (!sgp_mode && imagevld && sgp_run)
                    sgp_next <= LOAD;
                else if (sgp_mode && imagevld)
                    sgp_next <= LOAD;
                else
                    sgp_next <= WAIT;
            end
            LOAD: begin
                rdimage <= 1'b1;
                if (!sgp_mode && !sgp_run) begin
                    secret <= secret_data;
                    rdsecret <= 1'b1;
                end
                else
                    rdsecret <= 1'b0;
                for (i=0; i<3; i=i+1)
                   image[i] <= image_data[i];
                if (sgp_mode)
                    sgp_next <= EXTRACT_FUNCTION;
                else
                    sgp_next <= PRE_PROCESS;
            end
            PRE_PROCESS: begin
                rdimage <= 1'b0;
                rdsecret <= 1'b0;
                if (sgp_run)
                    res_secret[3:0] <= secret[3:0];
                else
                    res_secret[3:0] <= secret[7:4];
                for (i=0; i<3; i=i+1) begin
                    if (image[i] == 255)
                        image[i] <= 254;
                    else if (image[i] == 0)
                        image[i] <= 1;
                    else
                        image[i] <= image[i];
                end
                sgp_next <= EXTRACT_FUNCTION;
            end
            EXTRACT_FUNCTION: begin
                rdimage <= 1'b0;
                rdsecret <= 1'b0;
                res_f <= (image[0] + image[1] * 3 + image[2] * 9) % 27;
                if (sgp_mode) 
                    sgp_next <= DATA_OUT;
                else
                    sgp_next <= DECISION;
            end
            DECISION: begin
                if (res_f == res_secret)
                    sgp_next <= DATA_OUT;
                else begin
                    res_s <= ((res_secret - res_f) + 27) % 27;
                    sgp_next <= F4_1;
                end
            end
            F4_1: begin
                res_f4[0] <= (res_s - 1);
                res_f4[1] <= (res_s - 2) / 3;
                res_f4[2] <= (res_s - 5) / 9;
                sgp_next <= F4_2;
            end
            F4_2: begin
                for (i=0; i<3; i=i+1)
                    res_f4[i] <= res_f4[i] % 3;
                sgp_next <= EMBED;
            end
            EMBED: begin
                for (i=0; i<3; i=i+1) begin
                    if (res_f4[i] == 0 && res_s > (3**i - 1) / 2)
                        image[i] <= image[i] + 1;
                    else if (res_f4[i] == 1 && res_s > (3**i - 1) / 2)
                        image[i] <= image[i] - 1;
                    else
                        image[i] <= image[i];
                end
                sgp_next <= DATA_OUT;
            end
            DATA_OUT: begin
                if (sgp_mode && !sgp_run) begin
                    message[7:4] <= res_f[3:0];
                    sgp_run <= 1'b1;
                    sgp_next <= WAIT;
                end
                else if (sgp_mode && sgp_run) begin
                    message[3:0] <= res_f[3:0];
                    sgp_run <= 1'b0;
                    sgp_next <= READY;
                end    
                else if (!sgp_run) begin
                    sgp_run <= 1'b1;
                    for (i=0; i<3; i=i+1)
                        pixel[i] <= image[i];
                    sgp_next <= READY;
               end
               else begin
                    sgp_run <= 1'b0;
                    for (i=0; i<3; i=i+1)
                        pixel[i] <= image[i];
                    sgp_next <= READY;
               end
            end
            READY: begin
                sgpvalid <= 1'b1;
                if (rdsgp)
                    sgp_next <= WAIT;
                else
                    sgp_next <= READY; 
            end
            default:
                sgp_next <= INITIAL;
            endcase
        end
    end
    
    // FSM
    localparam RD_DATA = 3'd1;
    localparam LD_DATA = 3'd2;
    localparam WR_FF = 3'd3;
    localparam CK_FF = 3'd4;
    
    // Writing Block
    reg [1:0] out_sel;
    reg [2:0] out_next;
    wire [2:0] out_state;
    
    assign out_state = out_next;
    
    always @(posedge clk) begin
        if (!rst_n)
            out_next <= INIT;
        else begin
            case (out_state)
            INIT: begin
                ff_out_wren <= 1'b0;
                rdsgp <= 1'b0;
                out_sel <= 2'd0;
                ff_out_wrdata <= {(FF_WIDTH){1'b0}};
                wrmessage <= {(FF_WIDTH){1'b0}};
                for (i=0; i<3; i=i+1)
                    wrpixel[i] <= {(FF_WIDTH){1'b0}};
                if (start)
                    out_next <= RD_DATA;
                else
                    out_next <= INIT;
            end
            RD_DATA: begin
                out_sel <= 2'd0;
                if (sgpvalid)
                    out_next <= LD_DATA;
                else
                    out_next <= RD_DATA;
            end
            LD_DATA: begin
                rdsgp <= 1'b1;
                if (sgp_mode)
                    wrmessage <= message[FF_WIDTH-1 : 0];
                else
                    for (i=0; i<3; i=i+1)
                        wrpixel[i] <= pixel[i][FF_WIDTH-1 : 0];
                out_next <= WR_FF;
            end
            WR_FF: begin
                rdsgp <= 1'b0;
                if (ff_out_full)
                    out_next <= WR_FF;
                else if (sgp_mode) begin
                    ff_out_wren <= 1'b1;
                    ff_out_wrdata <= wrmessage;
                    out_sel <= 2'd3;
                    out_next <= CK_FF;
                end
                else begin
                    ff_out_wren <= 1'b1;
                    ff_out_wrdata <= wrpixel[out_sel];
                    out_sel <= out_sel + 1;
                    out_next <= CK_FF;
                end
            end
            CK_FF: begin
                ff_out_wren <= 1'b0;
                if (out_sel == 2'd3)
                    out_next <= RD_DATA;
                else
                    out_next <= WR_FF;
            end
            endcase
        end    
    end
    
endmodule
