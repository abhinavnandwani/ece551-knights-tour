
module reset_synch(
  input clk,         // Clock signal
  input RST_n,       // Asynchronous active-low reset
  output rst_n       // Synchronized reset output
);

  logic FF_1, FF_2;

  always_ff @(negedge !clk, negedge RST_n)
    if (!RST_n)
      FF_1 <= 1'b0;
    else
      FF_1 <= 1'b1;

  always_ff @(negedge clk, negedge RST_n)
    if (!RST_n)
      FF_2 <= 1'b0;
    else
      FF_2 <= FF_1;

  // Assign the synchronized reset to the output
  assign rst_n = FF_2;

endmodule

