module SPI_mnrch(input clk, input rst_n, input MISO, input snd, input [15:0] cmd, output reg SS_n, output SCLK,
                 output MOSI, output reg done, output [15:0] resp);


  // Declare internal variables
  logic init, set_done, ld_SCLK, full, done16;
  reg [4:0] SCLK_div, bit_cntr;
  reg [15:0] shift_reg;
  
  // Declare state machine variables
  typedef enum {IDLE, SEND} state_t;
  state_t state, nxt_state;
  
  assign MOSI = shift_reg[15];
  assign resp = shift_reg;
  assign SCLK = SCLK_div[4];
  
  // Assign shft to be 2 clock cycles later than SCLK rising edge
  assign shft = &(SCLK_div ~^ 5'b10010);
  
  // Assign full to be the high just before the falling edge of SCLK
  assign full = &(SCLK_div ~^ 5'b11111);
  
  // Check if we have incremented bit_cntr 16 times (check whether we've shifted 16 times
  assign done16 = bit_cntr[4];
  
  // State assignments
  always_ff@(posedge clk) begin
    if (!rst_n) 
	  state <= IDLE;
	else 
	  state <= nxt_state;
  end
  
  // State machine combinational logic
  always_comb begin
    nxt_state = state;
	init = 0;
	set_done = 0;
	ld_SCLK = 1;
	case (state)
	  IDLE: if (snd) begin
		nxt_state = SEND;
		init = 1;
      end
	  SEND: if (done16 & full) begin
		nxt_state = IDLE;
		set_done = 1;
	  end 
	  else begin
	    ld_SCLK = 0;
	  end
	endcase
  end
  
  // Create SR ff with preset for SS_n
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  SS_n <= 1;
	else if (set_done) 
	  SS_n <= 1;
	else if (init)
	  SS_n <= 0;
  end
  
  // Create SR ff for done
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  done <= 0;
	else if (set_done) 
	  done <= 1;
	else if (init)
	  done <= 0;
  end
  
  // Create the SCLK_div register
  always_ff@(posedge clk) begin
    if (ld_SCLK)
	  SCLK_div <= 5'b10111;
	else
	  SCLK_div <= SCLK_div + 1;
  end
  
  // Create the logic for MOSI shift register
  always_ff@(posedge clk) begin
    case ({init, shft})
	  2'b00: shift_reg <= shift_reg;
	  2'b01: shift_reg <= {shift_reg[14:0], MISO};
	  default: shift_reg <= cmd;
	endcase
  end
  
  // Create the bit_cntr register
  always_ff@(posedge clk) begin
    if (init)
	  bit_cntr <= 5'h00;
	else if (shft)
	  bit_cntr <= bit_cntr + 1;
  end
endmodule