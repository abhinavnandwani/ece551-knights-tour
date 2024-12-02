module Dterm(clk,rst_n,err_vld,err_sat,D_term);
	
	input clk,rst_n,err_vld;
	input signed [9:0] err_sat;
	output signed [12:0] D_term;
	
	
	localparam signed D_COEFF = 5'h07;
	logic signed [9:0] q1,q2,q3,prev_err,D_diff;
	logic signed [7:0] sat_D_diff;
	
	logic signed [9:0] err_sat_ff;
	logic signed err_vld_ff;

	always @(posedge clk) begin

		err_sat_ff <= err_sat;
		err_vld_ff <= err_vld;
		
	end
	
	
	assign prev_err = q3;
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n) begin
			q1 <= 0;
			q2 <= 0;
			q3 <= 0;
		end else if (err_vld_ff) begin
			q1 <= err_sat_ff;
			q2 <= q1;
			q3 <= q2;
		end
	assign D_diff = err_sat_ff - prev_err;

	
	assign sat_D_diff = (D_diff[9] == 1'b0 && (|D_diff[8:7] == 1'b1)) ? 8'b01111111:
					(D_diff[9] == 1'b0 && (&D_diff[8:7] == 1'b0)) ? D_diff[7:0]:
					(D_diff[9] == 1'b1 && (&D_diff[8:7] == 1'b0)) ? 8'b10000000:{D_diff[9],D_diff[6:0]};
					
	

	assign D_term = D_COEFF*sat_D_diff;
	

endmodule