/**
 * This module tests the tour logic from every possible black square.
 */

import tb_tasks::*;
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
        .clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
        .snd_cmd(send_cmd), .cmd_snt(cmd_sent), .resp_rx_rdy(resp_rdy),
        .resp_rx_data(resp), .resp_clr_rx_rdy()
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
    logic [2:0] countCntr;
    logic [1:0] countLft, countRght;
    int i, j, k, h;
    logic [3:0] val;
    logic [3:0] cM [23:0];
    logic b[4:0][4:0];
    logic [4:0] count;
    logic [3:0] partCMD1, partCMD2, sumParts;

    /**
     * Main simulation process.
     */
    always begin
        clk = 0;
        RST_n = 0;
        cmd = 16'h0000;
        send_cmd = 0;
        countCntr = 0;
        countLft = 0;
        countRght = 0;
        count = 0;
        
        @(negedge clk);
        RST_n = 1;

        nemosetup(clk, iPHYS.iNEMO.NEMO_setup);
        calibrateDUT(clk, iDUT.cal_done, send_cmd, cmd);

        for (int k = 0; k < 5; k++) begin
            for (int h = 0; h < 5; h++) begin
                @(posedge resp_rdy);
                @(negedge clk);
                sumParts = k + h;
                if (sumParts[0] == 1) begin
                    continue; // Filter non-black squares.
                end
                count = 5'h00;
                partCMD1 = k;
                partCMD2 = h;

                cmd = {8'h60, partCMD1, partCMD2};
                $display("%d %d %h", k, h, cmd);
                send_cmd = 1;

                @(negedge clk);
                send_cmd = 0;

                // Check proper handing off to tour cmd.
                repeat(49) @(posedge iDUT.iTC.send_resp);
                cM = iDUT.iTL.chosen_moves;
                b = iDUT.iTL.board;
                $display("-----------");

                for (int i = 0; i < 24; i++) begin
                    val = 8'h00;
                    for (int j = 0; j < 3; j++) begin
                        val = {val, cM[i][j]};
                    end
                    $display("%d : %h", i, val);
                end

                for (int i = 0; i < 5; i++) begin
                    for (int j = 0; j < 5; j++) begin
                        if (b[i][j] == 1) begin
                            count = count + 1;
                        end
                    end
                end

                assert (count == 5'd25) $display("All squares were visited");
                else begin
                    $display("%d squares were visited", count);
                    $stop();
                end
            end
        end
        $display("Tests done for latch liberation front");
        $stop();
    end

    /**
     * Clock generation.
     */
    always 
        #5 clk <= ~clk;
endmodule
