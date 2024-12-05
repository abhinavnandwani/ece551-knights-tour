/* 
    Team            : Latch Liberation Front - Abhinav, Damion, Miles, YV
    Filename        : sponge.sv  
*/

module sponge(
    input logic clk,           // Clock input
    input logic rst_n,         // Active low reset input
    input logic go,            // Start signal
    output logic piezo,        // Piezo output
    output logic piezo_n       // Inverted piezo output
);

  // Simulation parameter to speed up simulation for testing
  parameter FAST_SIM = 1; 

  // State machine states
  typedef enum [3:0] {IDLE, D7_1, E7_1, F7_1, E7_2, F7_2, D7_2, A6, D7_3} state_t;
  state_t state, nxt_state;   // Current and next states

  // Internal signals
  logic [23:0] timer;        // Timer to control frequency duration
  logic [14:0] duty_cycle;   // Duty cycle counter
  logic [14:0] desired_signal; // Desired frequency signal value
  logic clr_timer, clr_frequency, go_calc; // Control signals to clear timer/frequency and start calculation
  
  // Assign inverted piezo signal
  assign piezo_n = ~piezo; 
  
  // Piezo control logic - creates pulse based on duty cycle
  always_comb begin
    if (!go_calc) 
      piezo = 0; // If not calculating, piezo is off
    else if (duty_cycle >= (desired_signal[14:1])) 
      piezo = 0; // If duty cycle exceeds desired signal, piezo is off
    else 
      piezo = 1; // Otherwise, piezo is on
  end

	logic [4:0] sum; //to decide addition amount
   generate
        if (FAST_SIM) assign sum = 5'b10000;
        else assign sum = 5'b00001;
    endgenerate
  
  // Timer logic to increment the timer value
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
      timer <= 24'h000000; // Reset timer
    else if (clr_timer) 
      timer <= 24'h000000; // Clear timer if requested
    else 
        timer <= timer + sum;  // Normal increment
    
  end
  
  // Duty cycle counter - increments up to desired signal value
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
      duty_cycle <= 15'h0000; // Reset duty cycle
    else if (clr_frequency)
      duty_cycle <= 15'h0000; // Clear duty cycle if requested
    else if (duty_cycle >= desired_signal)
      duty_cycle <= 15'h0000; // Reset duty cycle after it reaches desired signal
    else
      duty_cycle <= duty_cycle + 1; // Increment duty cycle
  end

  // State machine logic to control note sequence
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE; // Reset state to IDLE on reset
    else
      state <= nxt_state; // Transition to next state
  end
  
  // State machine control logic
  always_comb begin
    // Default assignments for signals
    desired_signal = 15'hxxxx; // Undefined signal by default
    nxt_state = state;         // Default next state is the current state
    clr_timer = 0;             // No clearing of timer by default
    clr_frequency = 0;         // No clearing of frequency by default
    go_calc = 0;               // No calculation by default

    case (state)
      // IDLE state: Wait for 'go' signal to start the sequence
      IDLE: begin 
        clr_timer = 1;         // Clear the timer on entering IDLE
        clr_frequency = 1;     // Clear the frequency counter
        if (go) begin
          nxt_state = D7_1;    // Start the first note (D7_1) if 'go' is asserted
        end
      end
      
      // D7_1 state: Play note D7 for specified duration
      D7_1: begin
        desired_signal = 15'd21286; // Frequency for D7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[23]) begin     // After the desired duration, transition to E7_1
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = E7_1;      // Move to E7_1 state
        end
      end

      // E7_1 state: Play note E7 for specified duration
      E7_1: begin
        desired_signal = 15'd18961; // Frequency for E7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[23]) begin     // After the desired duration, transition to F7_1
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = F7_1;      // Move to F7_1 state
        end
      end

      // F7_1 state: Play note F7 for specified duration
      F7_1: begin
        desired_signal = 15'd17895; // Frequency for F7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[23]) begin     // After the desired duration, transition to E7_2
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = E7_2;      // Move to E7_2 state
        end
      end

      // E7_2 state: Play note E7 for specified duration
      E7_2: begin
        desired_signal = 15'd18961; // Frequency for E7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[23] & timer[22]) begin
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = F7_2;      // Move to F7_2 state
        end
      end

      // F7_2 state: Play note F7 for specified duration
      F7_2: begin
        desired_signal = 15'd17895; // Frequency for F7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[22]) begin     // After the desired duration, transition to D7_2
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = D7_2;      // Move to D7_2 state
        end
      end

      // D7_2 state: Play note D7 for specified duration
      D7_2: begin 
        desired_signal = 15'd21286; // Frequency for D7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[23] & timer[22]) begin
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = A6;        // Move to A6 state
        end
      end

      // A6 state: Play note A6 for specified duration
      A6: begin
        desired_signal = 15'd28409; // Frequency for A6
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[22]) begin     // After the desired duration, transition to D7_3
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = D7_3;      // Move to D7_3 state
        end
      end

      // D7_3 state: Play note D7 for specified duration
      D7_3: begin
        desired_signal = 15'd21286; // Frequency for D7
        go_calc = 1;              // Start calculation for piezo signal
        if (timer[23]) begin     // After the desired duration, return to IDLE
          clr_timer = 1;         // Clear timer
          clr_frequency = 1;     // Clear frequency counter
          nxt_state = IDLE;      // Move back to IDLE state
        end
      end

    endcase
  end

endmodule
