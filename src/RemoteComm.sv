/* 
    Author          : Abhinav Nandwani
    Filename        : RemoteComm.sv
    Description     : This module takes a 16-bit command and sends it as two 8-bit bytes over UART 
*/
`default_nettype none
module RemoteComm(
	input wire clk,    
	input wire rst_n,
	input wire snd_cmd,
	input wire [15:0] cmd, // data inputs
	input wire RX, //for UART when in receiving mode
	input wire resp_clr_rx_rdy,
	output wire TX, // TX is a single bit being sent.
	output reg cmd_snt, // cmd_snt asserts high when the entire 16 bits have been transmitted. 
	output wire resp_rx_rdy,    	//rx outputs 
	output wire [7:0] resp_rx_data

	);
	

	logic byte_sel; // if high transmitting cmd[15:8], [7:0] otherwise
	logic trmt; //sent to UART to initiate transmission

	logic tx_done; //output of UART, indicates completion of a transmission
	logic [7:0] tx_data; // data for the UART to trasnmit
	logic [7:0] low_b; // for flop to store low bit 


	logic set_cmd_snt;

	assign tx_data = byte_sel ? cmd[15:8] : low_b; //if byte_sel high - send high byte
												   // if byte sel low - send low byte from flop
	
	// UART inputs //
	
	
	UART iUART(
		.clk(clk),
		.rst_n(rst_n),
		.RX(RX),
		.TX(TX),
		.rx_rdy(resp_rx_rdy),
		.clr_rx_rdy(resp_clr_rx_rdy),
		.rx_data(resp_rx_data),
		.trmt(trmt),
		.tx_data(tx_data),
		.tx_done(tx_done)
		);

	
	//// flop for cmd with snd_cmd en ////
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			low_b <= 0;
		else if (snd_cmd) //sync en
			low_b <= cmd[7:0];
	
	
	
	typedef enum reg [1:0]{IDLE, HIGH_BYTE, LOW_BYTE} state_t;
	state_t state, nxt_state;
	//// flop for state ////
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	//// always comb block for next state and output logic ////
	always_comb begin
		// default outputs 
		byte_sel = 1'b1;
		trmt = 1'b0;
		set_cmd_snt = 1'b0;
		nxt_state = state;


		// TODO using 3 states for now, please check if can be done in 2.

		case (state)
			HIGH_BYTE: if(tx_done) begin
				byte_sel = 1'b0; //uncommented case byte_sel is default high 
				trmt = 1'b1;
				nxt_state = LOW_BYTE;
			end

			LOW_BYTE: if(tx_done) begin
				set_cmd_snt = 1'b1;
				nxt_state = IDLE;
	
			end

			// default is BYTE1 //
			default: if(snd_cmd) begin 
						trmt = 1'b1;
						nxt_state = HIGH_BYTE;
			end

		endcase
	end

		

	//// SR flop for cmd_snt ////
	always@(posedge clk, negedge rst_n)
		if(!rst_n)
			cmd_snt <= 1'b0;
		else if(snd_cmd) //R
			cmd_snt <= 1'b0;
		else if(set_cmd_snt) //S
			cmd_snt <= 1'b1;
		
	
endmodule
`default_nettype wire

	