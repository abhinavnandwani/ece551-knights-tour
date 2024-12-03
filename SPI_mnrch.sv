/* 
    Author          : Abhinav Nandwani
    Filename        : SPI_mnrch.sv
    Description     : SPI master interface for communication with serf devices.
*/

module SPI_mnrch(
    input logic clk,
    input logic rst_n,
	input logic MISO, // bit sent BY serf to monarch
	input logic [15:0] cmd, // the command to be sent to serf 
	input logic snd, // high for 1 clk to initiate transaction. 
    output logic SS_n,
    output logic SCLK,
    output logic MOSI, // bit sent BY monarch to serf 
    output logic [15:0] resp, // the response received from serf 
    output logic done // asserted on completion of transaction, stays high until next transaction
	
);
	// control signals
	logic init; //init signifies start of transaction
	logic shft;	// shft high for 1 clk signifies 1 SCLK has passed and new bits can be transmitted.
	logic [15:0] shft_reg;
	assign resp = shft_reg;  
	assign MOSI = shft_reg[15];
	//// shift register for cmd and resp ////
	always_ff@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			shft_reg <= 0;
		else if (init) //load shift reg with cmd if start of new transaction
			shft_reg <= cmd;
		else if (shft) // shift right with MISO if ongoing transaction
			shft_reg <= {shft_reg[14:0],MISO};
	end
	
	
	//// SCLK generator ////
	logic full,ld_SCLK;
	logic [4:0] SCLK_div; // reg that counts clk until 1 SCLK has passed. 
	assign SCLK = SCLK_div[4]; // if MSB of reg is 1, high half cycle, if 0, low half cycle. 
	assign shft = (SCLK_div == 5'b10001) ? 1'b1:1'b0;
	assign full = &SCLK_div;
	always_ff@(posedge clk, negedge rst_n) 
		if(!rst_n)
			SCLK_div <= 0;
		else if (ld_SCLK) // load with "front porch"
			SCLK_div <= 5'b10111;
		else 
			SCLK_div <= SCLK_div +1'b1;
	
	
	
	//// bit counter ////
	logic [4:0] bit_cntr;
	logic done16;
	assign done16 = (bit_cntr == 5'b10000) ? 1'b1:1'b0;
	always_ff@(posedge clk, negedge rst_n)	begin
		if (!rst_n)
			bit_cntr <= 0;
		else if(init)
			bit_cntr <= 0;
		else if(shft)
			bit_cntr <= bit_cntr + 1'b1;
	end
	
	//// FSM for control ////
	logic set_done;
	
	typedef enum reg [1:0] {IDLE, TRANSMITTING, BACK_PORCH} state_t;
	state_t state, nxt_state;
	
	// state flop
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	// always comb block for next state and output logic 
	always_comb begin
	
		// default outputs //
		ld_SCLK = 1'b0; 
		set_done = 1'b0;
		init = 1'b0;
		nxt_state = state;
		
		case (state)
		
		TRANSMITTING: if(done16) nxt_state = BACK_PORCH;			
		BACK_PORCH:  if(full) begin
						set_done = 1'b1;
						nxt_state = IDLE;
						ld_SCLK = 1'b1;
					end
					
		default: begin if(snd) begin 
					nxt_state = TRANSMITTING;
					init = 1'b1;
				end
				ld_SCLK = 1'b1; // "front porch"
		end
		endcase
	end

	// flop for done signal //
	always_ff@(posedge clk, negedge rst_n)
		if(!rst_n)
			done <= 0;
		else if (init)
			done <= 0;
		else if (set_done)
			done <= 1'b1;
	
	// flop for SS_n //
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			SS_n <= 1'b1; //active low preset for SS_n cause the signal itself is active low
		else if(init)
			SS_n <= 1'b0; // activate SS_n if start of new transmission
		else if (set_done)
			SS_n <= 1'b1; //deactivate SS_n on end of transmission
endmodule

