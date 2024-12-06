/* 
    Author          : Abhinav Nandwani
    Filename        : MtrDrv.sv
    Description     : 
*/




module MtrDrv(clk,rst_n,lft_spd,rght_spd,lftPWM1,lftPWM2,rghtPWM1,rghtPWM2);

    input signed [10:0] lft_spd,rght_spd;
    input clk,rst_n;
    output lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;

    logic [10:0]linput,rinput;

    assign linput = lft_spd + 11'h400;
    assign rinput = rght_spd + 11'h400;

    PWM11 pwml(.clk(clk),.rst_n(rst_n),.duty(linput),.PWM_sig(lftPWM1),.PWM_sig_n(lftPWM2));
    PWM11 pwmr(.clk(clk),.rst_n(rst_n),.duty(rinput),.PWM_sig(rghtPWM1),.PWM_sig_n(rghtPWM2));

endmodule