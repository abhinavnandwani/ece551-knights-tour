module reset_synch(clk, RST_n, rst_n);

  input logic clk, RST_n;
  output logic rst_n;
  logic int_rst_n;
  
  // Create the reset double flop, should be own module but eh
  always_ff@(negedge clk, negedge RST_n) begin
    if (!RST_n) begin
      int_rst_n <= 1'b0;
      rst_n <= 1'b0;
    end
    else begin
      int_rst_n <= 1'b1;
      rst_n <= int_rst_n;
    end
  end

endmodule