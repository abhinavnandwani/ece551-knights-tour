/**
*This module tests if the basic functions of the signals are implemented properly
*/
import tb_tasks::*;
module KnightsTour_tb1();

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
  logic lftIR_n,rghtIR_n,cntrIR_n;
  
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
                .snd_cmd(send_cmd), .cmd_snt(cmd_sent), .resp_rx_rdy(resp_rdy), .resp_rx_data(resp), .resp_clr_rx_rdy());
				   
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
  logic [11:0] prevErr, diffErr, err_now;
  logic [16:0] prevOmega, diffOmega, omega_now;
  logic [10:0] linput, rinput;

  initial begin
 
    //Initialise signals
    clk = 0;
    RST_n = 0;
    cmd = 16'h0000;
    send_cmd = 0;
    prevErr = 0;
    diffErr = 0;
    diffOmega = 0;
    prevOmega = 0;
    err_now = 0;
    omega_now = 0;
    linput = 0;
    rinput = 0;
    @(negedge clk);
    RST_n = 1;

    //////////////////////////////////////////////
    //Test 1: Make sure PWM is at 50% duty cycle
    /////////////////////////////////////////////

    @(negedge clk);
    linput = iDUT.iMTR.linput;
    rinput = iDUT.iMTR.rinput;

    @(negedge clk);

    mtrOutputCheck(lftIR_n, rghtIR_n, linput, rinput);

    repeat (10) @(negedge clk);  //Buffer period to observe the PWM waveform

    //////////////////////////////////////////////////
    //Test 2: Timeout test for NEMO_setup to go high
    //////////////////////////////////////////////////
    nemosetup(clk, iPHYS.iNEMO.NEMO_setup);

    
    //////////////////////////////////////////////////
    //Test 3: Timeout tests for cal_done
    //////////////////////////////////////////////////

    calibrateDUT(clk, iDUT.cal_done, send_cmd, cmd);

    @(posedge resp_rdy);
    @(negedge clk);
    assert (resp == 8'hA5) $display("Positive acknowledgement received");
    else begin
      $display("resp should be a5"); 
      $stop();
    end

    ///////////////////////////////////////////////////
    //Test 4: Sending command to go West for 1 square
    //////////////////////////////////////////////////
    prevErr = iDUT.error;
    prevOmega = iPHYS.omega_sum;

    fork   //Does other test while we wait for omega to change and see if that change is an increase or a decrease

      begin: timeoutOmegaCheck
        repeat (5000) @(negedge clk);
        disable Wait_omega_sum_change_then_check;
        $display("Timed out waiting for omega to change");
        $stop();
      end

      begin: Wait_omega_sum_change_then_check
        while (diffOmega == 0) begin
          omega_now = iPHYS.omega_sum;
          compareOm(prevOmega, omega_now, diffOmega);
          @(negedge clk);
        end

        disable timeoutOmegaCheck;

        assert (diffOmega>17'h00000) $display("omega_sum had an increase");
        else begin
          $display("omega_sum should have ramped up");
          $stop();
        end
      end

      begin
        @(negedge clk);
        cmd = 16'h53F1;
        send_cmd = 1;

        @(negedge clk);
        send_cmd = 0;
        @(posedge cmd_sent)
        repeat (2) @(negedge clk);

        err_now = iDUT.error;
        compareErr(prevErr, err_now, diffErr);

        if (diffErr == 0) begin
          $display("Error should have changed");
          $stop();
        end

        repeat (2) @(negedge clk);
        if (iDUT.iMTR.rinput < iDUT.iMTR.linput) begin
          $display("Right duty should have a greater increase than left");
          $stop();
        end
      end
    join

    fork
      begin: timeoutCntrIR
        repeat (3000000) @(negedge clk);
        $display("Timed out waiting for cntrIR_n to fire");
        $stop();
      end

      begin
        @(negedge cntrIR_n);
        disable timeoutCntrIR;
        $display("cntrIR_n fired");
      end

      begin: timeoutConvergingHeading
        repeat (3000000) @(negedge clk);
        $display("Timed out waiting for heading to converge to desired value");
        $stop();
      end

      begin

        while (iDUT.heading!=12'h3FF) begin
          @(negedge clk);
        end

        disable timeoutConvergingHeading;
        $display("Heading converged to desired value");
      end 
    join

    repeat (500000) @(negedge clk);

    $display("Tests done! Hail Latch Liberation Front");
    $stop();
  end
  
  always
    #5 clk = ~clk;
  
endmodule

