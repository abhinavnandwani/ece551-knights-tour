module KnightsTour_tb();

 localparam FAST_SIM = 1;
 
 
 /////////////////////////////
 // Stimulus of type reg //
 /////////////////////////
 reg clk, RST_n;
 reg [15:0] cmd;
 reg send_cmd;

 ///////////////////////////////////
 // Declare any internal signals //
 /////////////////////////////////
 wire SS_n,SCLK,MOSI,MISO,INT;
 wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
 wire TX_RX, RX_TX;
 logic cmd_sent;
 logic resp_rdy;
 logic [7:0] resp;
 wire IR_en;
 wire lftIR_n,rghtIR_n,cntrIR_n;
 
 //////////////////////
 // Instantiate DUT //
 ////////////////////
 KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                  .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
          .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
          .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
          .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
          .cntrIR_n(cntrIR_n));
         
 /////////////////////////////////////////////////////
 // Instantiate RemoteComm to send commands to DUT //
 ///////////////////////////////////////////////////
 RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
            .snd_cmd(send_cmd), .cmd_snt(cmd_sent), .resp_rx_rdy(resp_rdy), .resp_rx_data(resp),.resp_clr_rx_rdy());
          
 //////////////////////////////////////////////////////
 // Instantiate model of Knight Physics (and board) //
 ////////////////////////////////////////////////////
 KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                     .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
           .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
           .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 
          
  ////////////////////////////////
  //signals for task operations
  //////////////////////////////
  logic [11:0] prevErr, diffErr;
  logic [16:0] prevOmega, diffOmega;

  task compareErr (input [11:0] prev, input [11:0] now, output [11:0] compE);
    begin
      compE = now - prev; 
    end
  endtask

  task compareOm(input [16:0] prev, input [16:0] now, output [16:0] compE);
    begin
      compE = now - prev; 
    end
  endtask

 always begin
        clk = 0;
        RST_n = 0;
        cmd = 16'h0000;
        send_cmd = 0;
        
        @(negedge clk);
        RST_n = 1;

        fork
            begin: timeoutSetup
                repeat (1000000) @(posedge clk);
                $display("Timed out waiting for Nemo_setup");
                $stop();
            end
            begin
                @(posedge iPHYS.iNEMO.NEMO_setup);
                disable timeoutSetup;
                $display("NEMO_setup asserted");
            end
        join

        @(negedge clk);
        cmd = 16'h2000; //Callibrate command
        send_cmd = 1;

        @(negedge clk);
        send_cmd = 0;
        fork
            begin: timeoutCal
                repeat (1000000) @(posedge clk);
                $display("Timed out waiting for cal_done");
                $stop();
            end
            begin
                @(posedge iDUT.cal_done);
                disable timeoutCal;
                $display("cal_done asserted");
            end
        join
        @(posedge resp_rdy);
        @(negedge clk);

        cmd = 16'h5BF1;
        send_cmd = 1;

        @(negedge clk);
        send_cmd = 0;

        repeat (2) @(negedge iDUT.iCMD.cntrIR);

        $display("Test passed for Latch Liberation front");
        $stop();
    end

    always 
        #5 clk <= ~clk;
endmodule