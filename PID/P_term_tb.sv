

module P_term_tb();

    logic signed [11:0] error;
    logic signed [13:0] actual_out;
    logic clk;

    localparam signed P_COEFF = 6'h10;
	// Clock generator
	always #5 clk = ~clk;
    // Use logic signed for test cases and expected outputs
    logic signed [11:0] test_error[0:2] = {1098, -939, -468}; // Convert integers to signed logic
    logic signed [13:0] expected_out[0:2] = {511 * P_COEFF, -512 * P_COEFF, -468 * P_COEFF};

    // Instantiate the Device Under Test (DUT)
    P_term iDUT(.error(error), .P_term(actual_out) ,.clk(clk));

    initial begin
        clk = 0;
        for (int i = 0; i < 3; i++) begin
            error = test_error[i];
            #1000; 
            // Display results
            $display("Test %0d: error = %0d => out = %0d (Expected: %0d)", 
                     i, error, actual_out, expected_out[i]);
            
            // Check for errors
          //  @(posedge clk);
                fork 
                @(posedge clk);
                if (actual_out !== expected_out[i]) begin
                $error("Test %0d failed: Expected %0d, got %0d", i, expected_out[i], actual_out);
                end
                join
        end
        
        // End of simulation 
        $display("YAHOO passed!");
        $finish;
    end
endmodule

