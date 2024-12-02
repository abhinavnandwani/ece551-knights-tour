module P_term(error, P_term, clk);

	input signed [11:0] error;
	input clk;
	output signed [13:0] P_term;
	
	localparam signed P_COEFF = 6'h10;
	logic signed [9:0] error_sat,err_sat_ff;
	
	// 12 bits to 10 bits saturation 
	
	// if error[11] == 0 (positive number)
	
	// and error[10] == 1 , this means the 11'th bit is set and we can saturate to 0111111111
	// or error[10] == 0 , out = error[9:0]	
	assign error_sat = (error[11] == 1'b0 && (|error[10:9] == 1'b1)) ? 10'b0111111111:
						(error[11] == 1'b0 && (&error[10:9] == 1'b0)) ? error[9:0]:
						(error[11] == 1'b1 && (&error[10:9] == 1'b0)) ? 10'b1000000000:{error[11],error[8:0]};

	always @(posedge clk) begin

		err_sat_ff <= error_sat;
		
	end
							
    assign P_term = err_sat_ff * P_COEFF;					   

endmodule