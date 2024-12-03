module RemoteComm(input clk, input rst_n, input [15:0] cmd, input snd_cmd, input RX,
			output logic cmd_snt, output logic TX, output logic [7:0] resp, output logic resp_rdy);
typedef enum logic [1:0] {IDLE, BYTEHIGH, BYTELOW} state_t;
state_t state, nxt_state;

logic trmt, tx_done, rx_rdy, clr_rx_rdy;
logic sel_high, set_cmd_snt;
logic [7:0] tx_data, ffLSB7, rx_data;

//Mux
assign tx_data = (sel_high? cmd[15:8] : ffLSB7);

UART uart0(.*, .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(1'b0));

//Initialise states flipflop
always_ff @(posedge clk, negedge rst_n) begin
if (!rst_n) 
	state <= IDLE;
else
	state <= nxt_state;
end

//Mux input at 0 flipflop
always_ff @(posedge clk) begin
	if (snd_cmd) 
		ffLSB7 <= cmd[7:0]; 
end

//SR flipflop
always_ff @(posedge clk, negedge rst_n) begin
if (!rst_n)
	cmd_snt <= 1'b0;
else if (snd_cmd) 
	cmd_snt <= 1'b0;
else if (set_cmd_snt)
	cmd_snt <= 1'b1;
end

//SM logic 
always_comb begin
	nxt_state = state;
	set_cmd_snt = 0;
	sel_high = 0;
	trmt = 0;

	case (state)
		IDLE:
			if (snd_cmd) begin
				sel_high = 1;
				trmt = 1;
				nxt_state = BYTEHIGH;
		end
		BYTEHIGH: begin
			sel_high = 1;
			if (tx_done) begin
				sel_high = 0;
				trmt = 1;
				nxt_state = BYTELOW;
			end
		end
		BYTELOW:
			if (tx_done) begin
				set_cmd_snt = 1;
				nxt_state = IDLE;
			end
		default: nxt_state = IDLE;
	endcase
end

endmodule