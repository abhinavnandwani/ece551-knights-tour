module UART_wrapper(input clr_cmd_rdy, input clk, input rst_n, input RX, input trmt, input [7:0] resp,
                    output logic cmd_rdy, output TX, output tx_done, output [15:0] cmd);

  // Set up the 3-state state machine
  typedef enum {IDLE, LOAD_BIT_ONE, LOAD_BIT_TWO} state_t;
  state_t state, nxt_state;
  
  // Declare internal variables
  logic rx_rdy, clr_rdy, load_first_bit, set_cmd_rdy, clr_rx_rdy, rx_int_o, rx_int_t;
  logic [7:0] stored_value, rx_data, tx_data;
  
  // Create the cmd bus
  assign cmd = {stored_value, rx_data};

  // Declare the UART
  UART transceiver(.*);
  
  // Double flop RX for meta-stability reasons
  always_ff@(posedge clk) begin
    if (!rst_n) begin
	  rx_int_o <= 1'b1;
	  rx_int_t <= 1'b1;
	end 
	else begin
      rx_int_o <= RX;
	  rx_int_t <= rx_int_o;
	end
  end
  
  // Setup the state logic
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= IDLE;
	else 
	  state <= nxt_state;
  end
  
  // Setup the state machine
  always_comb begin
    nxt_state = state;
	clr_rdy = 0;
	load_first_bit = 0;
	set_cmd_rdy = 0;
	clr_rx_rdy = 0;
	case (state)
	  IDLE: if (!rx_int_t) begin
	          nxt_state = LOAD_BIT_ONE;
			  clr_rdy = 1;
			end
	  LOAD_BIT_ONE: if (rx_rdy) begin
	                  nxt_state = LOAD_BIT_TWO;
			          set_cmd_rdy = 1;
					  clr_rx_rdy = 1;
					  load_first_bit = 1;
	                end
	  LOAD_BIT_TWO: if (rx_rdy) begin
						  nxt_state = IDLE;
						  set_cmd_rdy = 0;
						end
	  default: nxt_state = IDLE;
	endcase
  end
  
  // Setup the cmd_rdy logic (this was not done using a SR flip flop, 
  // but rather a mealy output from the state machine which follows the same logic
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
	  cmd_rdy <= 0;
	else
	  cmd_rdy <= set_cmd_rdy;
  end
  
  // Setup the register to store the first bit
  always_ff@(posedge clk) begin
    if (load_first_bit) 
	  stored_value <= rx_data;
  end

endmodule