module PID(clk, rst_n, moving, err_vld, error, frwrd, lft_spd, rght_spd);

  input logic clk, rst_n, moving, err_vld;
  input logic [11:0] error;
  input logic [9:0] frwrd;
  output logic [10:0] lft_spd, rght_spd;
  
  // Declare internal signals
  logic [9:0] err_sat;
  logic [13:0] d_extend, i_extend, p_extend, PID, p_term;
  logic [12:0] d_term;
  logic [8:0] i_term;
  logic signed [10:0] sum_left, sum_right, res_left, res_right;
  
  // Saturator Block 
  logic maxPositive, maxNegative;

  assign err_sat[9] = error[11];
  
  // Check Maximum Values
  assign maxPositive = (~error[11]) & (|error[10:9]);
  assign maxNegative = (error[11] & (~&error[10:9]));
  
  // Check if the two bits being truncated away reach the maximum value, forces the smaller bits to 0 if it's negative, forces the smaller bits to 1 if it's positive
  assign err_sat[8] = (error[8] | maxPositive) & (~maxNegative); 
  assign err_sat[7] = (error[7] | maxPositive) & (~maxNegative); 
  assign err_sat[6] = (error[6] | maxPositive) & (~maxNegative); 
  assign err_sat[5] = (error[5] | maxPositive) & (~maxNegative); 
  assign err_sat[4] = (error[4] | maxPositive) & (~maxNegative); 
  assign err_sat[3] = (error[3] | maxPositive) & (~maxNegative); 
  assign err_sat[2] = (error[2] | maxPositive) & (~maxNegative); 
  assign err_sat[1] = (error[1] | maxPositive) & (~maxNegative); 
  assign err_sat[0] = (error[0] | maxPositive) & (~maxNegative); 
  
  // p_term block
  localparam P_coeff = 6'h10;
  
  assign p_term = $signed(P_coeff)*err_sat;
  
  // i_term block
  logic isNotPaused, isOverflow; 
  logic [14:0] nxt_integrator, integrator, integrator_summed, integrator_intermediate, extended_err_sat;
  
  // Sign extend the error so the math functions properly
  assign extended_err_sat = {{5{err_sat[9]}}, err_sat};
  
  // Do the integrator math, running it through various mux's and the starting addition
  assign integrator_summed = integrator + extended_err_sat;
  assign integrator_intermediate = isNotPaused ? integrator_summed : integrator;
  assign nxt_integrator = moving ? integrator_intermediate : 15'h0000;
  
  // Check for overeflow logic
  // If both are 1, check if the MSB of integrator_summed is 1, if they are both 0, check if MSB of integrator_summed is 0, if both are different, no overflow
  assign isOverflow = (extended_err_sat[14] & integrator[14]) ? (~integrator_summed[14]) : ((~extended_err_sat[14] & ~integrator[14]) ? integrator_summed[14] : 1'b0);
  assign isNotPaused = ~isOverflow & err_vld;
  
  // Create output
  assign i_term = integrator[14:6];
  
  // Flip flop copied from project slides
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
	  integrator <= 15'h0000;
	else
	  integrator <= nxt_integrator;
  end
  
  // d_term block
  localparam D_COEFF = 'h07;
  logic signed [9:0] intrErr1, intrErr2, prev_err, d_diff;
  logic signed [7:0] d_sat;
  logic maxPositiveD, maxNegativeD;
  
  // Assign d_diff to be the difference
  assign d_diff = err_sat - prev_err;
  
  // Check Maximum Values
  assign maxPositiveD = (~d_diff[9]) & (|d_diff[8:7]);
  assign maxNegativeD = (d_diff[9] & (~&d_diff[8:7]));
  
  // Check if the two bits being truncated away reach the maximum value, forces the 
  //smaller bits to 0 if it's negative, forces the smaller bits to 1 if it's positive
  assign d_sat[7] = d_diff[9];
  assign d_sat[6] = (d_diff[6] | maxPositiveD) & (~maxNegativeD); 
  assign d_sat[5] = (d_diff[5] | maxPositiveD) & (~maxNegativeD); 
  assign d_sat[4] = (d_diff[4] | maxPositiveD) & (~maxNegativeD); 
  assign d_sat[3] = (d_diff[3] | maxPositiveD) & (~maxNegativeD); 
  assign d_sat[2] = (d_diff[2] | maxPositiveD) & (~maxNegativeD); 
  assign d_sat[1] = (d_diff[1] | maxPositiveD) & (~maxNegativeD); 
  assign d_sat[0] = (d_diff[0] | maxPositiveD) & (~maxNegativeD); 
  
  // multiply d_sat by D_COEFF
  assign d_term = $signed(d_sat) * $signed(D_COEFF); 
  
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
	  intrErr1 <= 10'h00;
	  intrErr2 <= 10'h00;
	  prev_err <= 10'h00;
	end
	else if (err_vld) begin
	  intrErr1 <= err_sat;
	  intrErr2 <= intrErr1;
	  prev_err <= intrErr2;
	end
  end
  
  // Do the sign extension on the 3 terms
  assign p_extend = {p_term[13], p_term[13:1]};
  assign d_extend = {d_term[12], d_term[12:0]};
  assign i_extend = {{5{i_term[8]}}, i_term[8:0]};
  
  // Sum the 3 terms
  assign PID = p_extend + d_extend + i_extend;
  
  // Create the seperation between left and right
  assign sum_left = {1'b0, frwrd} + $signed(PID[13:3]);
  assign sum_right = {1'b0, frwrd} - $signed(PID[13:3]);
  
  // Create the mux's that determine if anything is done
  assign res_left = moving ? sum_left : 11'h000;
  assign res_right = moving ? sum_right : 11'h000;
  
  // Create saturation logic
  logic overflowRight, overflowLeft;
  assign overflowLeft = (~PID[13] & res_left[10]);
  assign overflowRight = (PID[13] & res_right[10]);
  
  assign lft_spd = overflowLeft ? (11'h3FF) : res_left;
  assign rght_spd = overflowRight ? (11'h3FF) : res_right;

endmodule