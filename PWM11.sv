module pwm(input clk, input rst_n, input [10:0] duty, output reg pwm_sig, output pwm_sig_n);
  // Create internal variables
  logic [10:0] cnt;
  logic cnt_lower;
  
  assign pwm_sig_n = ~pwm_sig;
  
  // Create counter to count clock cycles
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n) 
	  cnt <= 11'h000;
	else
	  cnt <= cnt + 1;
	  
  // Assign the output in synchronus fashion
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n) 
	  pwm_sig <= 1'b0;
	else
	  pwm_sig <= cnt_lower;
  
  // Create logic for checking when to switch
  always_comb begin
    if (cnt < duty) 
	  cnt_lower = 1'b1;
	else
	  cnt_lower = 1'b0;
  end
  
endmodule