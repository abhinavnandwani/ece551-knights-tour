module sponge_tb();
  logic clk, rst_n, go, piezo, piezo_n;
  sponge #(1) iDUT(.*);
  
  initial begin
    clk = 1;
	rst_n = 0;
	go = 0;
	repeat(2)@(posedge clk);
	rst_n = 1;
	repeat(2)@(posedge clk);
	go = 1;
	repeat(2)@(negedge clk);
	go = 0;
	repeat(8000000)@(posedge clk);
	$stop;
  end
  
  always
    #5 clk <= ~clk;
endmodule