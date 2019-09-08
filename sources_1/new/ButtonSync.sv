`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/16/2016 12:17:37 AM
// Design Name: 
// Module Name: ButtonSync
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


module ButtonSync(
    input logic clk, reset, bi,
    output logic bo
    );

    typedef enum logic [1:0] {S0, S1, S2} statetype;
    statetype curS = S0, nextS = S0;

    always_ff@(posedge clk) begin
        if(reset)
            curS <= S0;
        else
            curS <= nextS;
    end

    always_comb
        case(curS)
            S0: if(bi) nextS <= S1; else nextS <= S0;
            S1: if(bi) nextS <= S2; else nextS <= S0;
            S2: if(bi) nextS <= S2; else nextS <= S0;
        endcase

    always_comb
        case(curS)
            S0: bo = 1'b0;
            S1: bo = 1'b1;
            S2: bo = 1'b0;
        endcase
endmodule
