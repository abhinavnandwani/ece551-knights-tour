module sponge(clk, rst_n, go, piezo, piezo_n);

  parameter FAST_SIM = 1; // Fun parameter to make me not go insane

  typedef enum {IDLE, D7_1, E7_1, F7_1, E7_2, F7_2, D7_2, A6, D7_3} state_t;
  state_t state, nxt_state;

  // Declare inputs
  input logic clk, rst_n, go;
  
  // Declare outputs
  output logic piezo, piezo_n;
  
  // Declare internal signals
  logic [23:0] timer;
  logic [14:0] duty_cycle;
  logic [14:0] desired_signal;
  logic clr_timer, clr_frequency, go_calc; //, E7_counter, E7_counter_inc;
  
  assign piezo_n = ~piezo; // Definition
  
  // Create the logic which creates Piezo (which is high for half of duty_cycle's length
  always_comb begin
    if (!go_calc) 
	  piezo = 0;
	else if (duty_cycle >= (desired_signal[14:1]))
	  piezo = 0;
	else 
	  piezo = 1;
  end
  
  // Create timer and reset
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  timer <= 24'h000000;
	else if (clr_timer) 
	  timer <= 24'h000000;
	else begin
	  if (FAST_SIM)
	    timer <= timer + 16;
      else
		timer <= timer + 1;
	end
  end
  
  // Create the counter for the duty_cycle
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  duty_cycle <= 15'h0000;
	else if (clr_frequency)
	  duty_cycle <= 15'h0000;
	else if (duty_cycle >= desired_signal)
	  duty_cycle <= 15'h0000;
	else
	  duty_cycle <= duty_cycle + 1;
  end

  // Create the state machine basic functionality
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;
  end
  
  // Create a ff to store E7_counter
  /* always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  E7_counter <= 1'b0;
	else if (E7_counter_inc)
	  E7_counter <= 1'b1;
  end */
  
  // Create the state machines switching logic
  // This is a relatively complicated state machine, meant to play notes through
  // go_calc at the frequency desired_signal in the order D7, E7, F7, E7, F7, D7, A6, D7
  // At various specified duration. Designed for 50MHz clock
  always_comb begin
    desired_signal = 15'hxxxx;
    nxt_state = state;
	clr_timer = 0;
	clr_frequency = 0;
	go_calc = 0;
	//E7_counter_inc = 0;
	case (state)
	  IDLE: begin 
	    clr_timer = 1;
		clr_frequency = 1;
	    if (go) begin
	      nxt_state = D7_1;
		end
	  end
	  D7_1: begin
	    desired_signal = 15'd21286;
	    go_calc = 1;
		if (timer[23]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
		  nxt_state = E7_1;
		end
	  end
	  E7_1: begin
	    desired_signal = 15'd18961;
	    go_calc = 1;
		if (timer[23]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
		  nxt_state = F7_1;
		end
	  end
	  F7_1: begin
	    desired_signal = 15'd17895;
	    go_calc = 1;
		if (timer[23]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
	      //E7_counter_inc = 1;
	      nxt_state = E7_2;
	    end
	  end
	  E7_2: begin
	    desired_signal = 15'd18961;
	    go_calc = 1;
		if (timer[23] & timer[22]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
		  nxt_state = F7_2;
		end
	  end
	  F7_2: begin
	    desired_signal = 15'd17895;
	    go_calc = 1;
		if (timer[22]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
	      //E7_counter_inc = 1;
	      nxt_state = D7_2;
	    end
	  end
	  D7_2: begin 
	    desired_signal = 15'd21286;
	    go_calc = 1;
		if (timer[23] & timer[22]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
		  nxt_state = A6;
		end
	  end
	  A6: begin
	    desired_signal = 15'd28409;
		go_calc = 1;
		if (timer[22]) begin 
		  clr_timer = 1;
		  clr_frequency = 1;
		  nxt_state = D7_3;
		end
	  end
	  D7_3: begin
	    desired_signal = 15'd21286;
	    go_calc = 1;
		if (timer[23]) begin
		  clr_timer = 1;
		  clr_frequency = 1;
		  nxt_state = IDLE;
		end
	  end
	endcase
  end
endmodule
