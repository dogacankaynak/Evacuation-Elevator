`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/25/2018 12:28:52 AM
// Design Name: 
// Module Name: Timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Timer(
    input clk, reset, stop, turn, direction, 

    output a, b, c, d, e, f, g, dp, // just connect them to FPGA pins (individual LEDs).
    output [3:0] an   // just connect them to FPGA pins (enable vector for 4 digits, active low)
    );

    logic [3:0] in0 = 4'h0; //initial value
    logic [3:0] in1 = 4'h0; //initial value
    logic [3:0] in2 = 4'h0; //initial value
    logic [3:0] in3 = 4'ha; //initial value
    logic [6:0] dir = 7'b1111110;

    SevSeg_4digit SevSeg_4digit_inst0(
        .clk(clk), .dir(dir),
        .in3(in3), .in2(in2), .in1(in1), .in0(in0), //user inputs for each digit (hexadecimal)
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .dp(dp), // just connect them to FPGA pins (individual LEDs).
        .an(an)   // just connect them to FPGA pins (enable vector for 4 digits active low) 
    );

    // always_ff @(posedge clk)
    logic [27:0] count1 = 28'd0;
    logic [27:0] count2 = 28'd0;


    always_ff @(posedge clk) begin
        if (reset) begin
            in0 <= 4'h0; //initial value
            in1 <= 4'h0; //initial value
            in2 <= 4'h0; //initial value
            in3 <= 4'ha; //initial value
            dir <= 7'b1111110; // 7'b1111101
            count1 <= 28'd0;
            count2 <= 28'd0;
        end
        else if (~stop) begin
            if (turn) begin
                if (count2 == 28'd25000000) begin
                    if (direction)
                        dir <= {1'b1, dir[4:0], dir[5]};
                    else
                        dir <= {1'b1, dir[0], dir[5:1]};
                    count2 <= 28'd0;
                end
                else
                    count2 <= count2 + 1;
            end

            if (count1 > 28'd100000000) begin
                if (in0 == 4'd9) begin
                    if (in1 == 4'd9) begin
                        if (in2 == 4'd9) in2 <= 4'd0;
                        else in2 <= in2 + 1;
                        in1 <= 4'd0;
                    end
                    else in1 <= in1 + 1;
                    in0 <= 4'd0;
                end
                else in0 <= in0 + 1;
                count1 <= 28'd0;
            end
            else
                count1 <= count1 + 1;
        end
    end

endmodule
