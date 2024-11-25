module UART_rx(input clk, input rst_n, input RX, input clr_rdy, 
               output logic [7:0] rx_data, output reg rdy);
  
  // Setup the states used for the state machine
  typedef enum reg {IDLE, RECEIVING} state_t;
  state_t state, nxt_state; 
   
  // Declare internal signals and flip-flops
  logic [11:0] baud_cnt;
  logic [8:0] rx_shift_reg;
  logic [3:0] bit_cnt;
  logic [1:0] bit_cnt_mux, baud_cnt_mux;
  logic shift, start, start_or_shift, receiving, set_rdy, rx_int_o, rx_int_t;
  
  // Assign important internal variables
  assign bit_cnt_mux = {start, shift};
  assign baud_cnt_mux = {start_or_shift, receiving};
  assign start_or_shift = start | shift;
  assign shift = &(~(baud_cnt ^ 12'h000));
  
  // Assign important external variables
  assign rx_data = rx_shift_reg[7:0];
  
  // Create the flips flops stabilizing the RX input
  always_ff@(posedge clk) begin
    if (!rst_n) begin
	  rx_int_o <= 1;
	  rx_int_t <= 1;
	end
	else begin
      rx_int_o <= RX;
	  rx_int_t <= rx_int_o;
	end
  end
  
  // Assign the state to always become the nxt_state unless rst_n is asserted
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= IDLE;
	else 
	  state <= nxt_state;
  end
  
  // Create the state machine logic
  always_comb begin
    nxt_state = state;
	start = 0;
	set_rdy = 0;
	receiving = 0;
	case (state)
	  IDLE: if (!rx_int_t) begin
	          nxt_state = RECEIVING;
			  start = 1;
			  receiving = 1;
	        end
	  RECEIVING: if (rx_int_t & bit_cnt[3] & bit_cnt[1]) begin
	               nxt_state = IDLE;
				   set_rdy = 1;
	             end 
				 else begin
				   receiving = 1;
				 end
	endcase
  end
  
  // Create the flip flop block for rx_shift_reg
  always_ff@(posedge clk) begin
    if (shift)
	  rx_shift_reg <= {rx_int_t, rx_shift_reg[8:1]};
  end
  
  // Create the counter for baud_cnt
  always_ff@(posedge clk) begin
    case (baud_cnt_mux)
	  2'b00: baud_cnt <= baud_cnt;
	  2'b01: baud_cnt <= baud_cnt - 1;
	  default: baud_cnt <= 12'hA2C;
	endcase
  end
  
  // Create the counter for bit_cnt
  always_ff@(posedge clk) begin
    case (bit_cnt_mux)
	  2'b00: bit_cnt <= bit_cnt;
	  2'b01: bit_cnt <= bit_cnt + 1;
	  default: bit_cnt <= 4'h0;
	endcase
  end
  
  // Create the logic for output rdy
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
	  rdy <= 0;
	else if (start | clr_rdy)
	  rdy <= 0;
	else if (set_rdy)
	  rdy <= 1;
  end
endmodule