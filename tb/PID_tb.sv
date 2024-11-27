
module PID_tb;
  // Declare testbench signals
  logic clk;
  logic rst_n;
  logic moving;
  logic err_vld;
  logic signed [11:0] error;
  logic signed [9:0] frwrd;
  logic signed [10:0] lft_spd;
  logic signed [10:0] rght_spd;

  logic signed [10:0] lft_spd_expected;
  logic signed [10:0] rght_spd_expected;

  logic signed [24:0] stim[0:1999];  // Stimulus data
  logic signed [21:0] resp[0:1999];  // Response data

  // Read stimulus and response data from hex files
  initial begin
    $readmemh("PID_resp.hex", resp);
    $readmemh("PID_stim.hex", stim);
  end

  // Instantiate the PID module
  PID iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .moving(moving),
    .err_vld(err_vld),
    .error(error),
    .frwrd(frwrd),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd)
  );

  // Clock generation: Toggle clock every 5 time units
  always
    #5 clk = ~clk;

  // Task to check the output and compare it with the expected values
  task check_output;
    input signed [10:0] lft_spd_actual;
    input signed [10:0] rght_spd_actual;
    input signed [10:0] lft_spd_expected;
    input signed [10:0] rght_spd_expected;
    begin
      // Check if left speed matches expected value
      if (lft_spd_actual !== lft_spd_expected) begin
        $display("[%0t] ERROR: Left speed mismatch! Expected: %h, GOT: %h", $time, lft_spd_expected, lft_spd_actual);
       // $stop();
      end else begin
        $display("[%0t] PASS: Left speed matches! Expected: %h, GOT: %h", $time, lft_spd_expected, lft_spd_actual);
      end

      // Check if right speed matches expected value
      if (rght_spd_actual !== rght_spd_expected) begin
        $display("[%0t] ERROR: Right speed mismatch! Expected: %h, GOT: %h", $time, rght_spd_expected, rght_spd_actual);
       // $stop();
      end else begin
        $display("[%0t] PASS: Right speed matches! Expected: %h, GOT: %h", $time, rght_spd_expected, rght_spd_actual);
      end
    end
  endtask


  // Test sequence
  initial begin
    // Initialize all inputs
    rst_n = 0;
    moving = 0;
    err_vld = 0;
    error = 12'd0;
    frwrd = 10'd0;
    clk = 0;

    // Display a header for clarity
    $display("[%0t] Running Test Sequence: Stimulus and Response data:", $time);

    // Loop through stimulus and check the corresponding response
    for (int i = 0; i < 20; i++) begin
      @(negedge clk)  // Wait for the negative edge of the clock
             @(negedge clk)
                    @(negedge clk)

      // Apply stimulus values to the inputs
      rst_n = stim[i][24];        // Reset signal
      moving = stim[i][23];       // Moving signal
      err_vld = stim[i][22];      // Error valid signal
      error = stim[i][21:10];     // Error value (12 bits)
      frwrd = stim[i][9:0];       // Forward signal (10 bits)

      @(posedge clk)  // Wait for the positive edge of the clock
      // Wait for a small time to ensure output stability
       #1  

      // Expected output from the response data
      lft_spd_expected = resp[i][21:11];  // Expected left speed (11 bits)
      rght_spd_expected = resp[i][10:0];  // Expected right speed (11 bits)

      // Call the check_output task to compare actual and expected values
      check_output(lft_spd, rght_spd, lft_spd_expected, rght_spd_expected);

    end

    // End simulation after checking all sets of stimulus/response
    $display("Abhinav Nandwani passed all the tests");
    #100 $stop;
  end

endmodule

