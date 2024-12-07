/* 
    Author          : Abhinav Nandwani
    Filename        : UART_tx.sv
    Description     : 
*/




module UART_tx(clk,rst_n,TX,trmt,tx_data,tx_done);
	
	//inputs 
	input clk,rst_n,trmt;
	input [7:0] tx_data; //data to transmit

	output TX; // transmitter's single "bit" output
	output logic tx_done; //signals completetion to wrapper
	
	
	
	logic [3:0] bit_cnt;
	logic [11:0] baud_cnt;
	logic [8:0] tx_shift_reg;
	logic shift;
	logic set_done,init,transmitting;
	

	
	
	// BIT COUNTER
	always_ff@(posedge clk)
		if (!rst_n)
			bit_cnt <= 0;
		else begin
		 if (init) 
			bit_cnt <= 0;
		else if(shift) 
			bit_cnt <= bit_cnt +1; //every time shit is asserted, a complete bit has been received. 
		end
	
	
	//BAUD COUNTER
	assign shift = (baud_cnt == 2604) ? 1'b1:1'b0; //shit every 2604 cycles (baud rate)
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			baud_cnt <= 0;
		else begin
		// init has priority over shift
		if (init || shift)
			baud_cnt <= '0;
		else if(transmitting) //cnt till 2604 
			baud_cnt <= baud_cnt +1;
		end
	
	
	//SHIFT REG
	assign TX = tx_shift_reg[0];
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			tx_shift_reg <= 9'b111111111;
		else if (init) //init with data 
			tx_shift_reg <= {tx_data,1'b0};
		else if (shift) //send one bit at a time
			tx_shift_reg <= {1'b1,tx_shift_reg[8:1]};
			
	
	
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			tx_done <= 0;
		else if(init || transmitting)
			tx_done <= 0;
		else if(set_done) //if FSM asserts set_done, transmistter signals completion to wrapper. 
			tx_done <= 1'b1;
	
	//// FSM for control logic ////
	typedef enum reg {IDLE,TRANSMITING} state_t; // enumerated type for readability //
	state_t state, nxt_state;

	// state register in flop //
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else 
			state <= nxt_state;
	
	//// next state and output logic in comb ////
	always_comb begin
		
		nxt_state = state;
		init = 0;
		transmitting = 0;
		set_done = 0;
		case (state) inside 
            // we "transmit" data to the receiver for "10" bits, each bit takes almost 2604 cycles, start bit 1302. 
			TRANSMITING: if (bit_cnt < 10) // counts the bits
							transmitting = 1;
						else begin // if 10 bits transmiteed (1 byte + start end) we IDLE
							transmitting = 0;
							set_done = 1'b1;
							nxt_state = IDLE;
						end
			default: if (trmt) begin 	// trmt asserted high indicates start transmitting
					init = 1;
					nxt_state = TRANSMITING;
					end 
		endcase
	end
	    
		
endmodule
