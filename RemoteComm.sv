module RemoteComm(input snd_cmd, input [15:0] cmd, input clk, input rst_n, input RX, output reg cmd_sent, 
                  output resp_rdy, output [7:0] resp, output TX);

  // Declare internal states
  typedef enum {IDLE, FIRST_BIT, SECOND_BIT} state_t;
  state_t state, nxt_state;
  
  // Declare internal variables
  logic trmt, rx_rdy, tx_done, set_cmd_snt, sel, clr_rx_rdy;
  logic [7:0] tx_data, rx_data, intermediate_tx_data;
  
  // Assign the tx_data to be a mux to choose between the upper byte or lower byte
  assign tx_data = sel ? cmd[15:8] : intermediate_tx_data;
  
  // Assign the resp output
  assign resp = rx_data;
  assign resp_rdy = rx_rdy;
  
  // Instantiate UART machine
  UART transceiver(.*);
  
  // Run the state machine to ensure correct functionality
  always_comb begin
    nxt_state = state;
    trmt = 0;
	set_cmd_snt = 0;
	sel = 0;
	case (state)
	  // Check if the command has been sent, otherwise hold values
	  IDLE: if (snd_cmd) begin
	    nxt_state = FIRST_BIT;
		sel = 1;
		trmt = 1;
	  end 
	  else begin
	    sel = 1;
	  end
	  // Check if the first bit is finished
	  FIRST_BIT: if (tx_done) begin
	    nxt_state = SECOND_BIT;
		sel = 0;
		trmt = 1;
	  end
	  // Check if the second bit is finished
	  SECOND_BIT: if (tx_done) begin
	    nxt_state = IDLE;
		set_cmd_snt = 1;
	  end
	  default: nxt_state = IDLE;
	endcase
  end
  
  // Do the basic state logic
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  state <= IDLE;
	else
	  state <= nxt_state;
  end
  
  // Design the flip flop holding the lower bit
  always_ff@(posedge clk) begin
    if (snd_cmd)	
	  intermediate_tx_data <= cmd[7:0];
  end
  
  // Design the SR logic for cmd_snt
  always_ff@(posedge clk) begin
    if (!rst_n)
	  cmd_sent <= 1'b0;
	else if (snd_cmd)
	  cmd_sent <= 1'b0;
	else if (set_cmd_snt)
	  cmd_sent <= 1'b1;
  end
endmodule