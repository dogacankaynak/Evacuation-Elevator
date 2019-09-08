`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.12.2018 17:59:41
// Design Name: 
// Module Name: top
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


module top(
    input clk, reset_timer, reset_system, execute,

    // testing
    // input add1, add2, // add3, del1, del2, del3,
    
    //matrix  4x4 keypad
    output [3:0] keyb_row,
    input  [3:0] keyb_col,

    // FPGA pins for 8x8 display
    output reset_out, //shift register's reset
    output OE,  //output enable, active low 
    output SH_CP,  //pulse to the shift register
    output ST_CP,  //pulse to store shift register
    output DS,  //shift register's serial input data
    output [7:0] col_select, // active column, active high

    //7-segment signals
    output a, b, c, d, e, f, g, dp, 
    output [3:0] an
    );

    // for testing
    // logic sync_add1, sync_add2; // sync_add3, sync_del1, sync_del2, sync_del3; 

    // ButtonSync bs1(clk, 0, add1, sync_add1);
    // ButtonSync bs2(clk, 0, add2, sync_add2);
    // ButtonSync bs3(clk, 0, add3, sync_add3);
    // ButtonSync bs4(clk, 0, del1, sync_del1);
    // ButtonSync bs5(clk, 0, del2, sync_del2);
    // ButtonSync bs6(clk, 0, del3, sync_del3);

    
    logic [2:0] col_num;
    // initial value for RGB images:
    //    image_???[0]     : left column  .... image_???[7]     : right column
    //    image_???[?]'MSB : top line     .... image_???[?]'LSB : bottom line
    logic [0:7] [7:0] image_red = 
    {8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000};
    logic [0:7] [7:0]  image_green = 
    {8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000};
    logic [0:7] [7:0]  image_blue = 
    {8'b00000011, 8'b00000011, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000};

    // This module displays 8x8 image on LED display module. 
    display_8x8 display_8x8_0(
        .clk(clk),
        
        // RGB data for display current column
        .red_vect_in(image_red[col_num]),
        .green_vect_in(image_green[col_num]),
        .blue_vect_in(image_blue[col_num]),
        
        .col_data_capture(), // unused
        .col_num(col_num),
        
        // FPGA pins for display
        .reset_out(reset_out),
        .OE(OE),
        .SH_CP(SH_CP),
        .ST_CP(ST_CP),
        .DS(DS),
        .col_select(col_select)   
    );
    
    
    //matrix keypad scanner
    logic [3:0] key_value;
    logic key_valid;
    keypad4X4 keypad4X4_inst0(
        .clk(clk),
        .keyb_row(keyb_row), // just connect them to FPGA pins, row scanner
        .keyb_col(keyb_col), // just connect them to FPGA pins, column scanner
        .key_value(key_value), //user's output code for detected pressed key: row[1:0]_col[1:0]
        .key_valid(key_valid)  // user's output valid: if the key is pressed long enough (more than 20~40 ms), key_valid becomes '1' for just one clock cycle.
    );
    
    typedef enum logic [3:0] { init, waitForInput, up, check, down, done, waitTwoSec, evacuate} stype;
    stype cur_s = init;
    stype next_s;
    
    // variables
    logic [3:0] [3:0] numOfPass = {4'd0, 4'd0, 4'd0, 4'd0};
    logic [5:0] totalPass;
    assign totalPass = numOfPass[1] + numOfPass[2] + numOfPass[3];
    logic [1:0] floor = 2'd0;

    logic reset = 1, stop = 0, turn = 1, direction = 1;
    Timer timer(clk, {reset | reset_timer}, stop, turn, direction,
                a, b, c, d, e, f, g, dp, // just connect them to FPGA pins (individual LEDs).
                an );

    
    // flipflop
    always_ff@ (posedge clk) begin
        if (reset_system)
            cur_s <= init;
        else 
            cur_s <= next_s;
    end
    

    logic [11:0] passOfFloor1 = 12'd0;
    logic [11:0] passOfFloor2 = 12'd0;
    logic [11:0] passOfFloor3 = 12'd0;

    
    logic [2:0] elevatorSize = 3'd4;
    logic [31:0] moveCounter = 32'd0;
    
    
    // next and output states;
    always_ff@ (negedge clk) begin
        case(cur_s)
            init: begin

                reset <= 1;
                stop <= 1;

                numOfPass <= {4'd0, 4'd0, 4'd0, 4'd0};
                
                passOfFloor1 <= 12'd0;
                passOfFloor2 <= 12'd0;
                passOfFloor3 <= 12'd0;

                floor <= 2'd0;
                elevatorSize <= 3'd4;
                moveCounter <= 32'd0;
                
                

                image_red <= 
                {8'b00000000, 8'b00000000, 
                {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};

                image_blue <= 
                {8'b00000011, 8'b00000011, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000};
                
                next_s <= waitForInput;
            end
            
            waitForInput: begin

                image_red <= 
                {8'b00000000, 8'b00000000, 
                {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};

                if (key_valid == 1'b1) begin
                    case(key_value)
                        4'b01_00: if (numOfPass[1] < 4'd12) begin
                            passOfFloor1[numOfPass[1]] <= 1;
                            numOfPass[1] <= numOfPass[1] + 1;
                        end
                        4'b10_00: if (numOfPass[2] < 4'd12) begin
                            passOfFloor2[numOfPass[2]] <= 1;
                            numOfPass[2] <= numOfPass[2] + 1;
                        end
                        4'b11_00: if (numOfPass[3] < 4'd12) begin
                            passOfFloor3[numOfPass[3]] <= 1;
                            numOfPass[3] <= numOfPass[3] + 1;
                        end

                        4'b01_01: if (numOfPass[1] > 4'd0) begin
                            passOfFloor1[numOfPass[1] - 1] <= 0;
                            numOfPass[1] <= numOfPass[1] - 1;
                        end
                        4'b10_01: if (numOfPass[2] > 4'd0) begin
                            passOfFloor2[numOfPass[2] - 1] <= 0;
                            numOfPass[2] <= numOfPass[2] - 1;
                        end
                        4'b11_01: if (numOfPass[3] > 4'd0) begin
                            passOfFloor3[numOfPass[3] - 1] <= 0;
                            numOfPass[3] <= numOfPass[3] - 1;
                        end
                    endcase
                end
                // for testing
                // else if (sync_add1) begin
                //     passOfFloor1[numOfPass[1]] <= 1;
                //     numOfPass[1] <= numOfPass[1] + 1;
                // end
                // else if (sync_add2) begin
                //     passOfFloor2[numOfPass[2]] <= 1;
                //     numOfPass[2] <= numOfPass[2] + 1;
                // end
                // else if (sync_add3) begin
                //     passOfFloor3[numOfPass[3]] <= 1;
                //     numOfPass[3] <= numOfPass[3] + 1;
                // end
                // else if (sync_del1) begin
                //     passOfFloor1[numOfPass[1] - 1] <= 0;
                //     numOfPass[1] <= numOfPass[1] - 1;
                // end
                // else if (sync_del2) begin
                //     passOfFloor2[numOfPass[2] - 1] <= 0;
                //     numOfPass[2] <= numOfPass[2] - 1;
                // end
                // else if (sync_del3) begin
                //     passOfFloor3[numOfPass[3] - 1] <= 0;
                //     numOfPass[3] <= numOfPass[3] - 1;
                // end // end of testing
                else if (execute && totalPass > 0) next_s <= up;
            end
            up: begin

                reset <= 0;
                stop <= 0;
                direction <= 1;
                turn <= 1;

                // time should be 300000000
                if (moveCounter > 32'd300000000)
                    if (totalPass > 0) begin
                        image_blue <= {image_blue[0] << 2, image_blue[1] << 2, image_blue[2:7]};
                        image_red <= {image_red[0] << 2, image_red[1] << 2, image_red[2:7]};
                        floor <= floor + 1;
                        moveCounter <= 32'd0;
                        next_s <= check;
                    end
                    else next_s <= done;
                else 
                    moveCounter <= moveCounter + 1;
            end
            check: begin
                if (elevatorSize > 0) begin
                    case(floor)
                        2'd1: begin
                            if (numOfPass[1] > 0) begin
                                if (elevatorSize > numOfPass[1]) begin
                                    elevatorSize <= elevatorSize - numOfPass[1];
                                    passOfFloor1 <= passOfFloor1 >> numOfPass[1];
                                    numOfPass[1] <= 4'd0;
                                end
                                else begin
                                    numOfPass[1] <= numOfPass[1] - elevatorSize;
                                    passOfFloor1 <= passOfFloor1 >> elevatorSize;
                                    elevatorSize <= 4'd0;
                                end
                                next_s <= waitTwoSec;
                            end
                            else next_s <= up;
                        end
                        2'd2: begin
                            if (numOfPass[2] > 0) begin
                                if (elevatorSize > numOfPass[2]) begin
                                    elevatorSize <= elevatorSize - numOfPass[2];
                                    passOfFloor2 <= passOfFloor2 >> numOfPass[2];
                                    numOfPass[2] <= 4'd0;
                                end
                                else begin
                                    numOfPass[2] <= numOfPass[2] - elevatorSize;
                                    passOfFloor2 <= passOfFloor2 >> elevatorSize;
                                    elevatorSize <= 4'd0;
                                end
                                next_s <= waitTwoSec;
                            end
                            else next_s <= up;
                        end
                        2'd3: begin
                            if (numOfPass[3] > 0) begin
                                if (elevatorSize > numOfPass[3]) begin
                                    elevatorSize <= elevatorSize - numOfPass[3];
                                    passOfFloor3 <= passOfFloor3 >> numOfPass[3];
                                    numOfPass[3] <= 4'd0;
                                end
                                else begin
                                    numOfPass[3] <= numOfPass[3] - elevatorSize;
                                    passOfFloor3 <= passOfFloor3 >> elevatorSize;
                                    elevatorSize <= 4'd0;
                                end
                                next_s <= waitTwoSec;
                            end
                            else next_s <= up;
                        end
                    endcase
                end
                else begin
                    next_s <= down;
                end
            end
            waitTwoSec: begin
                case(elevatorSize)
                    3'd4: begin
                        image_blue <= {8'b00000011 << (2 * floor), 8'b00000011 << (2 * floor), image_blue[2:7]};
                        image_red <= {8'b00000000 << (2 * floor), 8'b00000000 << (2 * floor),
                        {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                        {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                        {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                        {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                        {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                        {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}}; // not important
                    end
                    3'd3: begin
                        image_blue <= {8'b00000001 << (2 * floor), 8'b00000011 << (2 * floor), image_blue[2:7]};
                        image_red <= {8'b00000010 << (2 * floor), 8'b00000000 << (2 * floor),
                        {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                        {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                        {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                        {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                        {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                        {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};
                    end
                    3'd2: begin
                        image_blue <= {8'b00000001 << (2 * floor), 8'b00000001 << (2 * floor), image_blue[2:7]};
                        image_red <= {8'b00000010 << (2 * floor), 8'b00000010 << (2 * floor), 
                        {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                        {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                        {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                        {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                        {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                        {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};
                    end
                    3'd1: begin
                        image_blue <= {8'b00000000 << (2 * floor), 8'b00000001 << (2 * floor), image_blue[2:7]};
                        image_red <= {8'b00000011 << (2 * floor), 8'b00000010 << (2 * floor),
                        {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                        {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                        {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                        {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                        {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                        {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};
                    end
                    3'd0: begin
                        image_blue <= {8'b00000000 << (2 * floor), 8'b00000000 << (2 * floor), image_blue[2:7]};
                        image_red <= {8'b00000011 << (2 * floor), 8'b00000011 << (2 * floor),
                        {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                        {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                        {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                        {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                        {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                        {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};
                    end
                    
                endcase
                
                turn <= 0;

                // time should be 200000000
                if (moveCounter > 32'd200000000) begin
                    moveCounter <= 32'd0;
                    if (elevatorSize > 0 && totalPass > 0)
                        next_s <= up;
                    else
                        next_s <= down;
                end
                else begin
                    moveCounter <= moveCounter + 1;
                end
            end

            down: begin

                reset <= 0;
                stop <= 0;
                direction <= 0;
                turn <= 1;

                if (floor == 2'd0)
                    next_s <= evacuate;
                // time should be 300000000
                else if (moveCounter > 32'd300000000) begin
                
                    moveCounter <= 32'd0;
                    if (floor > 0) begin
                        image_blue <= {image_blue[0] >> 2, image_blue[1] >> 2, image_blue[2:7]};
                        image_red <= {image_red[0] >> 2, image_red[1] >> 2, image_red[2:7]};
                        floor <= floor - 1;
                        next_s <= down;
                    end
                    else next_s <= evacuate;
                end
                else 
                    moveCounter <= moveCounter + 1;
            end

            evacuate: begin

                turn <= 0;

                // time should be 200000000
                if (moveCounter > 32'd200000000) begin

                    moveCounter <= 32'd0;
                    image_red <= 
                    {8'b00000000, 8'b00000000, 
                    {passOfFloor3[1:0], passOfFloor2[1:0], passOfFloor1[1:0], 2'b00}, 
                    {passOfFloor3[3:2], passOfFloor2[3:2], passOfFloor1[3:2], 2'b00}, 
                    {passOfFloor3[5:4], passOfFloor2[5:4], passOfFloor1[5:4], 2'b00}, 
                    {passOfFloor3[7:6], passOfFloor2[7:6], passOfFloor1[7:6], 2'b00}, 
                    {passOfFloor3[9:8], passOfFloor2[9:8], passOfFloor1[9:8], 2'b00}, 
                    {passOfFloor3[11:10], passOfFloor2[11:10], passOfFloor1[11:10], 2'b00}};

                    image_blue <= 
                    {8'b00000011, 8'b00000011, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000};

                    if (totalPass > 0)
                        next_s <= up;
                    else
                        next_s <= done;
                        
                    elevatorSize  <= 3'd4;
                end
                else
                    moveCounter <= moveCounter + 1;
            end
            done: begin
                if (moveCounter > 32'd100000000)
                    stop <= 1;
                else 
                    moveCounter <= moveCounter + 1;
            end
        endcase
    end
    
endmodule
