module UART_tx(input logic rst_n, input logic clk, input logic trmt, 
               input logic [7:0] tx_data, output logic TX, output logic tx_done);
  
  // Declare states to be had
  typedef enum reg {IDLE, RUNNING} state_t;
  state_t state, nxt_state;
  
  // Declare variables
  logic [11:0] baud_cnt;
  logic [8:0] tx_shift_reg;
  logic [3:0] bit_cnt;
  logic init, shift, transmitting, set_done, init_or_shift;
  logic [2:0] shift_bit_mux_input, baud_cnt_mux_input;
  
  // Combine necessary variables
  assign init_or_shift = init | shift;
  assign shift_bit_mux_input = {init, shift};
  assign baud_cnt_mux_input = {init_or_shift, transmitting};
  
  // Assign shift (checks if each bit is as expected before declaring
  assign shift = &(~(baud_cnt ^ 12'hA2C));
  
  // Assign the output TX
  assign TX = tx_shift_reg[0];
  
  // Assign the state to always become the nxt_state unless rst_n is asserted
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= IDLE;
	else 
	  state <= nxt_state;
  end
  
  // Do the state logic
  always_comb begin
    nxt_state = state;
	set_done = 0;
	init = 0;
	transmitting = 0;
	case (state)
	  IDLE: if (trmt) begin
	          init = 1;
			  transmitting = 1;
			  nxt_state = RUNNING;
	        end
	  RUNNING: begin
	             transmitting = 1;
				 if (bit_cnt[3] & bit_cnt[1]) begin
				   set_done = 1;
				   nxt_state = IDLE;
				 end
			   end
	endcase
  end
  
  // Set up the shift register
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  tx_shift_reg <= 9'h000;
	else begin
      case(shift_bit_mux_input)
	    2'b00: tx_shift_reg <= tx_shift_reg;
	    2'b01: tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
	    default: tx_shift_reg <= {tx_data, 1'b0};
	  endcase
	end
  end
  
  // Set up the Baud Counter
  always_ff@(posedge clk) begin
    case(baud_cnt_mux_input)
	  2'b00: baud_cnt <= baud_cnt;
	  2'b01: baud_cnt <= baud_cnt + 1;
	  default: baud_cnt <= 12'h000;
	endcase
  end
  
  // Set up the bit counter
  always_ff@(posedge clk) begin
    case(shift_bit_mux_input)
	  2'b00: bit_cnt <= bit_cnt;
	  2'b01: bit_cnt <= bit_cnt + 1;
	  default: bit_cnt <= 4'h0;
	endcase
  end
  
  // Setup the finish detection
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  tx_done <= 0;
    else if (init)
	  tx_done <= 0;
	else if (set_done)
	  tx_done <= 1;
  end
endmodule