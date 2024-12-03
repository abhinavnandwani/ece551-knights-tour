/* 
    Author          : Abhinav Nandwani
    Filename        : PWM11.sv
    Description     : 
*/



module PWM11(clk,rst_n,duty,PWM_sig,PWM_sig_n);

input clk,rst_n;
input [10:0] duty;
output reg PWM_sig,PWM_sig_n;


logic drive;
logic [10:0] cnt;

assign drive = (cnt<duty) ? 1'b1:1'b0;




always_ff@(posedge clk, negedge rst_n)
	
	if (!rst_n) begin
		PWM_sig <= 1'b0;
		cnt <= 0;
	end else begin
		PWM_sig <= drive;
		cnt <= cnt +1;
	end

assign PWM_sig_n = ~PWM_sig;

endmodule