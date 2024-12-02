module Dterm_tb();
	
	logic clk, rst_n, err_vld,fail_count;
	logic signed [9:0] err_sat;
	logic signed [12:0] D_term;
	
	localparam signed D_COEFF = 5'h07;
	
	// Clock generator
	always #5 clk = ~clk;
	
	Dterm iDUT(.clk(clk), .rst_n(rst_n), .err_vld(err_vld), .err_sat(err_sat), .D_term(D_term));
	
	logic signed test_err_vld[0:3] = {1, 1, 1, 1};
	logic signed [9:0] test_err_sat[0:3] = {500, 70, 100, -200}; // Convert integers to signed logic
	logic signed [12:0] expected_out[0:3] = {127 * D_COEFF, -128 * D_COEFF, 30 * D_COEFF, -128 * D_COEFF};
	logic signed [12:0] last_valid_output;
	
	initial begin
		// Reset DUT
		rst_n = 0;
		clk = 0;
		err_vld = 0;
		err_sat = 0;
		fail_count = 0;

		@(negedge clk);
		rst_n = 1; // Deassert reset 

		// Run existing tests
		for (int i = 0; i < 4; i++) begin
			err_vld = test_err_vld[i];
			err_sat = test_err_sat[i];
			
			repeat (2) @(negedge clk);
			
			// Check the output
			if (D_term !== expected_out[i]) begin
				$display("Test %0d FAILED: err_sat = %0d, D_term = %0d, Expected = %0d", i, err_sat, D_term, expected_out[i]);
				fail_count++;
			end else begin
				$display("Test %0d PASSED: err_sat = %0d, D_term = %0d", i, err_sat, D_term);
			end
		end

		// New test 1: Check if D_term is 0 after 3 clock cycles
		$display("Starting D_term zero check test...");
		err_vld = 1;
		err_sat = 50; // Example input
		@(negedge clk);
		repeat (3) @(negedge clk); // Wait for 3 clock cycles
		err_vld = 0; // Deassert err_vld
		@(negedge clk);
		
		if (D_term !== 0) begin
			$display("D_term Zero Check Test FAILED: D_term = %0d, Expected = 0", D_term);
			fail_count++;
		end else begin
			$display("D_term Zero Check Test PASSED: D_term = %0d", D_term);
		end

		// New test 2: Check if err_vld = 0 hangs the pipeline
		$display("Starting freeze behavior test...");
		err_vld = 1; // Reassert err_vld
		err_sat = 100; // Example input
		@(negedge clk);
		@(negedge clk); // Wait one clock cycle
		@(negedge clk); // Wait one more clock cycle
		@(negedge clk); // Wait one more clock cycle

		// Now, deassert err_vld
		err_vld = 0;
		@(negedge clk); // Wait one more clock cycle

		// Capture the last valid D_term output
		last_valid_output = D_term;

		// Wait for additional cycles to verify the output does not change
		repeat (5) @(negedge clk);
		if (D_term !== last_valid_output) begin
			$display("Freeze Test FAILED: D_term changed after err_vld was deasserted. Current D_term = %0d, Expected = %0d", D_term, last_valid_output);
			fail_count++;
		end else begin
			$display("Freeze Test PASSED: D_term = %0d remains unchanged after err_vld = 0", D_term);
		end

		// Summary report
		if (fail_count == 0) begin
			$display("YAHOO! All tests passed!");
		end else begin
			$display("Total failed tests: %0d", fail_count);
		end

		// Finish simulation
		$finish;
	end
endmodule
