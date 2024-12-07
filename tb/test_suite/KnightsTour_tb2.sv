/**
 * This module tests the behavior of cntrIR and verifies if the knight obeys the move command sent through the Bluetooth module properly.
 */
module KnightsTour_tb();

    localparam FAST_SIM = 1;

    /**
     * Stimulus of type reg.
     */
    reg clk, RST_n;
    reg [15:0] cmd;
    reg send_cmd;

    /**
     * Declare internal signals.
     */
    wire SS_n, SCLK, MOSI, MISO, INT;
    wire lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;
    wire TX_RX, RX_TX;
    logic cmd_sent, resp_rdy;
    logic [7:0] resp;
    wire IR_en;
    wire lftIR_n, rghtIR_n, cntrIR_n;

    /**
     * Instantiate DUT.
     */
    KnightsTour iDUT(
        .clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
        .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
        .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
        .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
        .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
        .cntrIR_n(cntrIR_n)
    );

    /**
     * Instantiate RemoteComm to send commands to DUT.
     */
    RemoteComm iRMT(
        .clk(clk), .rst_n(RST_n), .RX(TX_RX), .TX(RX_TX), .cmd(cmd),
        .snd_cmd(send_cmd), .cmd_snt(cmd_sent), .resp_rx_rdy(resp_rdy), .resp_rx_data(resp), .resp_clr_rx_rdy()
    );

    /**
     * Instantiate model of Knight Physics (and board).
     */
    KnightPhysics iPHYS(
        .clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO),
        .MOSI(MOSI), .INT(INT), .lftPWM1(lftPWM1), .lftPWM2(lftPWM2),
        .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2), .IR_en(IR_en),
        .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n), .cntrIR_n(cntrIR_n)
    );

    /**
     * Test logic variables.
     */
    logic [1:0] count; // Count variable to track cntrIR rise events

    /**
     * Main simulation process.
     */
    always begin
        clk = 0;
        RST_n = 0;
        cmd = 16'h0000;
        send_cmd = 0;
        count = 0;

        @(negedge clk);
        RST_n = 1;

        nemosetup(clk, iPHYS.iNEMO.NEMO_setup); // Wait for NEMO setup

        calibrateDUT(clk, iDUT.cal_done, send_cmd, cmd); // Wait for calibration

        @(posedge resp_rdy);
        @(negedge clk);

        cmd = 16'h5BF1;
        send_cmd = 1;

        @(negedge clk);
        send_cmd = 0;

        fork 
            begin: CountCntrIRrise
                while (count >= 0) begin
                    @(posedge iDUT.iCMD.cntrIR);
                    count = count + 1;
                    @(negedge clk);
                end
            end
            begin: timeoutRespRdy
                repeat (10000000) @(negedge clk);
                $display("Timed out waiting for resp_rdy");
            end
            begin
                @(posedge resp_rdy);
                disable timeoutRespRdy;
                disable CountCntrIRrise;
                assert (resp == 8'hA5) $display("Positive acknowledgement received");
                else begin
                    $display("Positive acknowledgement not received");
                    $stop();
                end
            end
        join

        assert (count == 2'b10) $display("cntrIR rose 2 times");
        else begin
            $display("Mistake: cntrIR rose %d times", count);
            $stop();
        end

        repeat (150000) @(negedge clk); // Observe

        $display("Test passed for Latch Liberation front");
        $stop();
    end

    /**
     * Clock generation.
     */
    always 
        #5 clk <= ~clk;
endmodule
