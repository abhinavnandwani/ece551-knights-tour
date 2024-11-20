/* 
    Team            : Latch Liberation Front - Abhinav, Damion, Miles, YV
    Filename        : inter_intf_tb.sv  
*/

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

    // Task to reset the DUT
    task reset_dut();
        begin
            @(negedge clk) rst_n = 1'b0;  // Assert reset
            @(negedge clk) rst_n = 1'b1;  // Deassert reset
        end
    endtask

    // Task to wait for a signal with a timeout
    // Inputs: signal (the signal to wait for), timeout (the timeout in clock cycles)
    task wait_for_signal_with_timeout(logic signal, integer timeout);
        begin
            fork
                // Wait for signal to be asserted
                begin
                    @(posedge signal);
                    $display("%s asserted at time %t", signal, $time);
                    disable timeout_wait;  // Disable timeout if signal is asserted
                end
                // Timeout after a certain number of cycles
                begin
                    repeat(timeout) @(posedge clk);
                    $display("Timeout: %s not asserted within %d cycles.", signal, timeout);
                    $stop;  // Pause simulation on timeout
                end
            join
        end
    endtask

    // Task to assert a signal for one clock cycle
    // Input: signal (signal to be asserted)
    task assert_signal_for_one_cycle(logic signal);
        begin
            @(negedge clk) signal = 1'b1;  // Assert signal
            @(negedge clk) signal = 1'b0;  // Deassert signal
        end
    endtask

    // Task to run for a certain number of cycles
    // Input: num_cycles (number of clock cycles to wait)
    task run_for_cycles(integer num_cycles);
        begin
            for (int i = 0; i < num_cycles; i = i + 1) begin
                @(posedge clk);  // Wait for each clock cycle
            end
        end
    endtask

    // Initial block to start the simulation
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        strt_cal = 0;

        // Reset DUT
        reset_dut();

        // Step 2: Wait for NEMO_setup signal to be asserted (simulate with timeout)
        wait_for_signal_with_timeout(iNEMO2.NEMO_setup, 100000);  // Timeout after 1,000,000 cycles

        // Step 3: Assert strt_cal for one clock cycle after NEMO setup
        assert_signal_for_one_cycle(strt_cal);

        // Step 4: Wait for cal_done to be asserted (with a long timeout)
        wait_for_signal_with_timeout(cal_done, 1000000);  // Timeout after 1,000,000 cycles

        // Step 5: Let the DUT run for 8 million more clock cycles
        run_for_cycles(8000000);  // Run for 8 million cycles

        // End simulation and print final heading
        $display("Final heading at time %t: %d", $time, heading);
        $stop;  // Final stop for inspection
    end

endmodule
