module inter_intf_tb;

    // Testbench signals
    logic clk, rst_n, MISO, INT, strt_cal;
    logic cal_done, rdy, SS_n, SCLK, MOSI;
    logic signed [11:0] heading;

    // Instantiate the inert_intf module
    inert_intf iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .MISO(MISO),
        .INT(INT),
        .strt_cal(strt_cal),
        .moving(1'b1),         // Enable yaw integration
        .lftIR(1'b0),          // Guardrail sensors inactive
        .rghtIR(1'b0),
        .cal_done(cal_done),
        .heading(heading),
        .rdy(rdy),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI)
    );

    // Instantiate the SPI_iNEMO2 model
    SPI_iNEMO2 iNEMO2 (
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );

    // Clock generation: 10 ns clock period (100 MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        strt_cal = 0;

        @(negedge clk) rst_n = 1'b1;  // Deassert reset

        // Step 2: Wait for NEMO_setup signal to be asserted (simulate with timeout)
        fork
            // Wait for NEMO_setup signal
            begin : wait_for_nemo_setup
                @(posedge iNEMO2.NEMO_setup);
                $display("NEMO_setup asserted at time %t", $time);
                disable timeout_nemo_setup;  // Disable the timeout if setup is successful
            end
            
            // Timeout after 1,000,000 clock cycles
            begin : timeout_nemo_setup
                repeat(100000) @(posedge clk);
                $display("Timeout: NEMO_setup not asserted.");
                $stop;  // Pause simulation on timeout
            end
        join

        // Step 3: Assert strt_cal for one clock cycle after NEMO setup
        @(negedge clk) strt_cal = 1;
        @(negedge clk) strt_cal = 0;

        // Step 4: Wait for cal_done to be asserted (with a long timeout)
        fork
            // Wait for cal_done signal
            begin : wait_for_cal_done
                @(posedge cal_done);
                $display("Calibration completed at time %t", $time);
                disable timeout_cal_done;  // Disable the timeout if calibration is done
            end
            
            // Timeout after 1 million cycles if cal_done doesn't assert
            begin : timeout_cal_done
                repeat(1000000) @(posedge clk);
                $display("Timeout: cal_done not asserted within 1 million cycles.");
                $stop;  // Pause simulation on timeout
            end
        join

        // Step 5: Let the DUT run for 8 million more clock cycles
        for (int i = 0; i < 8000000; i = i + 1) begin
            @(posedge clk);  // Wait for each clock cycle
        end

        // End simulation and print final heading
        $display("Final heading at time %t: %d", $time, heading);
        $stop;  // Final stop for inspection
    end

endmodule
