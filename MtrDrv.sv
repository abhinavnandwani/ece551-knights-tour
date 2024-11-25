module MtrDrv(input clk, input rst_n, input logic [10:0] lft_spd, 
                input logic [10:0] rght_spd, output leftPWM1, 
                output leftPWM2, output rightPWM1, output rightPWM2);
	
	logic [10:0] dR, dL;
	
	pwm LeftMotor(.clk(clk), .rst_n(rst_n), .duty(dL), .pwm_sig(leftPWM1), .pwm_sig_n(leftPWM2));
	pwm Right(.clk(clk), .rst_n(rst_n), .duty(dR), .pwm_sig(rightPWM1), .pwm_sig_n(rightPWM2));
	
	assign dR = 11'h400 + rght_spd;
	assign dL = 11'h400 + lft_spd;

endmodule