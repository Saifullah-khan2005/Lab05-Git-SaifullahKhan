`timescale 1ns / 1ps

module fsm (
    input wire clk,             // 100MHz system clock
    input wire pbin,            // Physical reset button
    input wire [15:0] physical_sw, // 16 physical switches
    output wire [15:0] physical_leds // 16 physical LEDs
);

    // 1. Clean the physical reset button (Debouncer)
    wire rst_clean;
    debouncer rst_db (
        .clk(clk),
        .pbin(pbin), 
        .pbout(rst_clean)   
    ); 

    // 2. Generate the 1-second countdown tick (Clock Divider)
    wire slow_clk;
    clock_divider ticker (
        .clk_in(clk),       
        .rst(rst_clean),    
        .clk_out(slow_clk)  // 1Hz clock for 1-second countdown
    );

    // 3. FSM State Definitions
    localparam IDLE  = 2'b00;
    localparam COUNT = 2'b01;
    localparam DONE  = 2'b10;

    reg [1:0] current_state, next_state;
    reg [15:0] counter;

    // 4. Sequential Logic (State Memory & Data Path)
    // Triggered by the 1Hz slow clock OR immediately by the reset button
    always @(posedge slow_clk or posedge rst_clean) begin
        if (rst_clean) begin
            // IMMEDIATE RESET: Wipes the state and counter instantly
            current_state <= IDLE;
            counter <= 16'd0;
        end else begin
            current_state <= next_state;
            
            // FSM Datapath actions based on current state
            if (current_state == IDLE) begin
                counter <= physical_sw; // Continuously load switch value
            end 
            else if (current_state == COUNT) begin
                counter <= counter - 1; // Decrement by 1 every slow_clk cycle
            end
        end
    end

    // 5. Combinational Logic (Next State Calculation)
    always @(*) begin
        case (current_state)
            IDLE: begin
                // "Apply zero and non-zero switch values"
                // If switches are non-zero, start the countdown
                if (physical_sw > 16'd0)
                    next_state = COUNT;
                else
                    next_state = IDLE;
            end
            
            COUNT: begin
                // Stop counting when we are about to hit 0
                if (counter == 16'd1) 
                    next_state = DONE;
                else
                    next_state = COUNT;
            end
            
            DONE: begin
                // Wait for the user to flip all switches back to 0 before restarting
                if (physical_sw == 16'd0)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // 6. Output Logic
    assign physical_leds = counter;

endmodule