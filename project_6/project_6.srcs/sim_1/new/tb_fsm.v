`timescale 1ns / 1ps

module tb_fsm;

    // 1. Declare signals
    reg clk;
    reg pbin;
    reg [15:0] physical_sw;
    wire [15:0] physical_leds;

    // 2. Instantiate the Unit Under Test (UUT)
    fsm uut (
        .clk(clk),
        .pbin(pbin),
        .physical_sw(physical_sw),
        .physical_leds(physical_leds)
    );

    // 3. Generate 100 MHz System Clock (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Test Stimulus (Matches Task 4 Requirements)
    initial begin
        // Initialize everything to 0
        pbin = 1'b0;
        physical_sw = 16'd0;
        #100;

        // --- STEP A: Apply Reset ---
        $display("--- System Reset ---");
        pbin = 1'b1;
        #200; // Hold button down
        pbin = 1'b0;
        #500; // Wait for debouncer to clear

        // --- STEP B: Apply Zero Switch Values ---
        // Lab Req: "Apply zero switch values" -> Should stay in IDLE
        $display("--- Testing Zero Switches (Should stay in IDLE) ---");
        physical_sw = 16'd0;
        #1000;

        // --- STEP C: Apply Non-Zero Switch Values & Observe Countdown ---
        // Lab Req: "Apply non-zero switch values" -> "Observe LED countdown behavior"
        $display("--- Setting Switches to 4 (Starting Countdown) ---");
        physical_sw = 16'd4;
        
        // Wait for the countdown to finish (4 -> 3 -> 2 -> 1 -> DONE)
        // **CRITICAL:** The delay required here depends entirely on your clock_divider! 
        // We will wait a long time to let the simulation run through the cycles.
        #10000; 

        // --- STEP D: Return to IDLE from DONE ---
        // FSM requires switches to be zeroed out to exit the DONE state
        $display("--- Zeroing Switches to reset FSM back to IDLE ---");
        physical_sw = 16'd0;
        #1000;

        // --- STEP E: Press Reset DURING Countdown ---
        // Lab Req: "Press reset during countdown to verify immediate reset"
        $display("--- Starting new countdown with Switches = 5 ---");
        physical_sw = 16'd5;
        
        // Wait just long enough for it to start counting...
        #3000; 
        
        $display("--- Pushing Reset Button Mid-Countdown! ---");
        pbin = 1'b1;
        #200;
        pbin = 1'b0;
        #1000;

        $display("Simulation Complete.");
        $finish;
    end

    // 5. Monitor State and LED Changes in the TCL Console
    always @(uut.current_state or physical_leds) begin
        case (uut.current_state)
            2'b00: $display("Time: %0t ns | State: IDLE  | LEDs (Counter): %d", $time, physical_leds);
            2'b01: $display("Time: %0t ns | State: COUNT | LEDs (Counter): %d", $time, physical_leds);
            2'b10: $display("Time: %0t ns | State: DONE  | LEDs (Counter): %d", $time, physical_leds);
        endcase
    end

endmodule