/* 
    Team            : Latch Liberation Front - Abhinav, Damion, Miles, YV
    Filename        : cmd_proc.sv  
*/
module cmd_proc_tb();

    // Clock and reset signals
    logic clk, rst_n;

    // cmd_proc signals
    // Inputs    
    logic lftIR, cntrIR, rghtIR;  // Left and right are 0
    logic [15:0] cmd;
    logic cmd_rdy, clr_cmd_rdy;
    logic [11:0] heading;
    logic heading_rdy;
    logic cal_done;

    // Outputs
    logic fanfare_go;
    logic [9:0] frwrd;
    logic [11:0] error;
    logic moving;
    logic strt_cal;
    logic send_resp;

    localparam FAST_SIM = 1;

    // Instantiate cmd_proc module
    cmd_proc #(FAST_SIM) iCMD(
        .clk(clk), 
        .rst_n(rst_n),
        .cmd(cmd), 
        .cmd_rdy(cmd_rdy), 
        .clr_cmd_rdy(clr_cmd_rdy),
        .send_resp(send_resp),
        .tour_go(),
        .heading(heading),
        .heading_rdy(heading_rdy),
        .strt_cal(strt_cal), 
        .cal_done(cal_done),
        .moving(moving),
        .lftIR(lftIR), 
        .cntrIR(cntrIR), 
        .rghtIR(rghtIR),
        .fanfare_go(fanfare_go),
        .frwrd(frwrd), 
        .error(error)
    );

    // UART_wrapper signals
    logic TX_RX;
    logic RX_TX;
    logic tx_done; // Unused

    UART_wrapper iUW(
        .clk(clk), 
        .rst_n(rst_n),
        .resp_tx_data(8'hA5), 
        .resp_trmt(send_resp), 
        .cmd(cmd), 
        .clr_cmd_rdy(clr_cmd_rdy), 
        .cmd_rdy(cmd_rdy),
        .RX(TX_RX), 
        .TX(RX_TX),
        .resp_tx_done(tx_done)
    );
    
    // RemoteComm signals
    logic [15:0] cmdRC;
    logic snd_cmd;
    logic resp_rdy;
    logic cmd_sent;

    RemoteComm iRC(
        .clk(clk), 
        .rst_n(rst_n), 
        .RX(RX_TX), 
        .TX(TX_RX), 
        .resp_rx_data(), 
        .resp_rx_rdy(resp_rdy),
        .resp_clr_rx_rdy(),
        .cmd_snt(cmd_sent),
        .cmd(cmdRC), 
        .snd_cmd(snd_cmd)
    );
    
    // Inert_intf signals
    logic INT;
    logic MISO;
    logic MOSI;
    logic SCLK;
    logic SS_n;

    inert_intf #(FAST_SIM) iINT(
        .clk(clk), 
        .rst_n(rst_n),
        .strt_cal(strt_cal), 
        .cal_done(cal_done), 
        .heading(heading),
        .rdy(heading_rdy),
        .lftIR(lftIR), 
        .rghtIR(rghtIR),
        .INT(INT),
        .SS_n(SS_n), 
        .SCLK(SCLK),
        .MOSI(MOSI), 
        .MISO(MISO),
        .moving(moving)
    );

    // SPI_iNEMO3 signals
    SPI_iNEMO3 iSPI(
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );

    // Assertions for signal integrity
    always @(posedge clk) begin
        assert(!(^frwrd === 1'bx)) else $fatal("Error: frwrd has an undefined value (x or z)");
        assert(!(^heading === 1'bx)) else $fatal("Error: heading has an undefined value (x or z)");
        assert(!(^moving === 1'bx)) else $fatal("Error: moving has an undefined value (x or z)");
        assert(!(^cal_done === 1'bx)) else $fatal("Error: cal_done has an undefined value (x or z)");
        assert(!(^cmd_rdy === 1'bx)) else $fatal("Error: cmd_rdy has an undefined value (x or z)");
        assert(!(^resp_rdy === 1'bx)) else $fatal("Error: resp_rdy has an undefined value (x or z)");
    end

    // Tests
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        cmdRC = 0; 
        snd_cmd = 0;
        lftIR = 0;
        rghtIR = 0;
        cntrIR = 0;

        @(negedge clk);
        rst_n = 1;

        @(negedge clk);
        cmdRC = 16'h2000; // Calibrate command
        snd_cmd = 1;

        @(negedge clk);
        snd_cmd = 0;

        // Test 1: Timeout tests for resp_rdy and cal_done
        fork
            begin: timeoutCal
                repeat (1100000) @(posedge clk);
                $display("Timed out waiting for cal_done");
                $stop();
            end
            begin
                @(posedge cal_done);
                disable timeoutCal;
                $display("cal_done asserted, passed");
            end
        join

        fork
            begin: timeoutRespRdy
                repeat(100000) @(posedge clk);
                $display("Timed out waiting for resp_rdy");
                $stop();
            end
            begin
                @(posedge resp_rdy);
                disable timeoutRespRdy;
                $display("resp_rdy asserted, passed");
            end
        join

        // Test 2: Move "north"
        @(negedge clk);
        cmdRC = 16'h4001;
        snd_cmd = 1;
        @(negedge clk);
        snd_cmd = 0;

        // Check initial frwrd value
        @(posedge cmd_rdy); 
        if (frwrd == 10'h000) 
            $display("frwrd is x000, passed");
        else begin
            $display("frwrd : %h should be x000, failed", frwrd);
            $stop();
        end

        // Check if frwrd is incrementing properly
        repeat (10) @(posedge heading_rdy);
        if (frwrd == 10'h120)  
            $display("frwrd is x120, passed");
        else if (frwrd == 10'h140)   // Two possible values of frwrd
            $display("frwrd is x140, passed");
        else begin
            $display("frwrd : %h should be x120 or x140, failed", frwrd);
            $stop();
        end

        // Check if moving has been asserted
        if (!moving) begin
            $display("moving should have been asserted by now, failed");
            $stop();
        end else begin
            $display("move asserted, passed");
        end

        // Checking if frwrd is saturated to max speed
        repeat(20) @(posedge heading_rdy);
        assert (frwrd == 10'h300) $display("frwrd is saturated at x300");
        else begin
            $display("frwrd : %h should be x300, failed", frwrd);
            $stop();
        end

        // First cntrIR pulse
        @(negedge clk);
        cntrIR = 1;
        @(negedge clk);
        cntrIR = 0;

        repeat (10) @(negedge clk); // Wait for a few clk cycles

        // frwrd should still be saturated
        assert (frwrd == 10'h300) $display("frwrd is saturated at x300, passed");
        else begin
            $display("frwrd : %h should be x300, failed", frwrd);
            $stop();
        end

        // Second cntrIR pulse
        @(negedge clk);
        cntrIR = 1;
        @(negedge clk);
        cntrIR = 0;

        repeat (10) @(negedge heading_rdy); // Wait for a few clk cycles

        assert (frwrd < 10'h300) $display("frwrd is decreasing, passed");
        else begin
            $display("frwrd should be decreasing, failed");
            $stop();
        end

        fork
            begin: timeoutF0
                repeat (1000000) @(posedge clk);
                $display("Timed out waiting for resp_rdy");
                $stop();
            end
            begin
                @(posedge resp_rdy);
                disable timeoutF0;
                if (frwrd !== 10'h000) begin
                    $display("frwrd : %h should be 0 by now, failed", frwrd);
                    $stop();
                end
                else $display("frwrd is 0, passed");
                if (moving) begin
                    $display("moving should be deasserted by now, failed");
                    $stop();
                end
                else $display("moving deasserted, passed");
            end
        join

        //////////////////////////////////////////
        // Test 3: Another north 1 square command with lftIR and rghtIR (Optional)
        /////////////////////////////////////////
        @(negedge clk);
        cmdRC = 16'h4001;
        snd_cmd = 1;

        @(negedge clk);
        lftIR = 1;
        snd_cmd = 0;

        repeat (500) @(negedge clk); // Observe error

        lftIR = 0; 

        repeat (500) @(negedge clk); // Observe error

        rghtIR = 1;

        repeat (500) @(negedge clk); // Observe error

        rghtIR = 0; 

        repeat (500) @(negedge clk); // Observe error

        $display("Yahoo! All tests passed");
        $stop();
    end

    // Clock generation
    always 
        #5 clk = ~clk;

endmodule
