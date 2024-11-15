
module cmd_proc_tb();

    logic clk, rst_n;

    ///////////////////
    //cmd_proc signals 
    ///////////////////

    //Inputs    
    logic lftIR, cntrIR, rghtIR;  //Left and right are 0
    logic [15:0] cmd;
    logic cmd_rdy, clr_cmd_rdy;
    logic [11:0] heading;
    logic heading_rdy;
    logic cal_done;

    //Outputs
    logic fanfare_go;
    logic [9:0] frwrd;
    logic [11:0] error;
    logic moving;
    logic strt_cal;
    logic tour_go;
    logic send_resp;

    //cmd_proc module
    cmd_proc iCMD(.clk(clk), .rst_n(rst_n),
                    .cmd(cmd), .cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy),
                    .send_resp(send_resp),
                    .tour_go(tour_go),
                    .heading(heading),
                    .heading_rdy(heading_rdy),
                    .strt_cal(strt_cal), .cal_done(cal_done),
                    .moving(moving),
                    .lftIR(lftIR), .cntrIR(cntrIR), .rghtIR(rghtIR),
                    .fanfare_go(fanfare_go),
                    .frwrd(frwrd), 
                    .error(error));

    ///////////////////////
    //UART_wrapper signals
    //////////////////////

    //Inputs
    logic TX_RX;
    logic respIN;   //resp is A5

    //Outputs
    logic RX_TX;
    logic tx_done; //Unused

    UART_wrapper iUW(.clk(clk), .rst_n(rst_n),
                        .resp_tx_data(8'hA5), .resp_trmt(send_resp), 
                        .cmd(cmd), .clr_cmd_rdy(clr_cmd_rdy), .cmd_rdy(cmd_rdy),
                        .RX(TX_RX), .TX(RX_TX),
                        .resp_tx_done(tx_done));
    
    /////////////////
    //RomCom signals
    /////////////////

    //Inputs 
    logic [15:0] cmdRC;
    logic snd_cmd;

    //Outputs
    logic [7:0] resp;
    logic resp_rdy;
    logic cmd_sent;

    RemoteComm iRC(.clk(clk), .rst_n(rst_n), 
                    .RX(RX_TX), .TX(TX_RX), 
                    .resp_rx_data(resp), .resp_rx_rdy(resp_rdy),
                    .cmd_snt(cmd_sent), .resp_clr_rx_rdy(),
                    .cmd(cmdRC), .snd_cmd(snd_cmd));
    
    /////////////////////
    //inert_intf signals
    /////////////////////

    //Inputs 
    logic INT;
    logic MISO;
    
    //Outputs
    logic MOSI;
    logic SCLK;
    logic SS_n;

    inert_intf iINT(.clk(clk), .rst_n(rst_n),
                    .strt_cal(strt_cal), .cal_done(cal_done), 
                    .heading(heading),
                    .rdy(heading_rdy),
                    .lftIR(lftIR), .rghtIR(rghtIR),
                    .INT(INT),
                    .SS_n(SS_n), .SCLK(SCLK),
                    .MOSI(MOSI), .MISO(MISO),
                    .moving(moving));

    /////////////////////
    //SPI_iNEMO3 signals
    /////////////////////

    //Inputs 

    //Outputs

    SPI_iNEMO3 iSPI(.SS_n(SS_n),
                    .SCLK(SCLK),
                    .MISO(MISO),
                    .MOSI(MOSI),
                    .INT(INT));

//tests
always begin
    clk = 0;
    rst_n = 0;
    cmdRC = 16'h2000; //Calibrate command
    snd_cmd = 0;
    cntrIR = 0;
    lftIR = 0;
    rghtIR = 0;
    cntrIR = 1;

    @(negedge clk);
    rst_n = 1;
    snd_cmd = 1;

    @(negedge clk);
    snd_cmd = 0;

    //////////////////////////////////////////////////
    //Test 1: Timeout tests for resp_rdy and cal_done
    //////////////////////////////////////////////////
    fork
        begin: timeoutCal
            repeat (1100000) @(posedge clk);
            $display("Timed out waiting for cal_done");
            $stop();
        end
        begin
            @(posedge cal_done);
            disable timeoutCal;
            $display("cal_done asserted");
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
            $display("resp_rdy asserted");
        end
    join

    ///////////////////////
    //Test 2: Move "north"
    ///////////////////////
    cmdRC = 16'h4001;
    @(negedge clk);
    snd_cmd = 1;
    @(negedge clk);
    snd_cmd = 0;

    //Check initial frwrd value
    @(posedge cmd_sent); //pdf mentioned to wait cmd_sent
    assert (frwrd == 10'h000) $display("frwrd is x000");
    else begin
        $display("frwrd should be x000");
      //  $stop();
    end

    //Check if frwrd is incrementing properly
    repeat (10) @(posedge heading_rdy);
    if (frwrd == 10'h120)  
        $display("frwrd is x120");
    else if (frwrd == 10'h140)   //Two possible values of frwrd
        $display("frwrd is x140");
    else begin
        $display("frwrd should be x120 or x140");
        $stop();
    end

    //Check if moving has been asserted
    if (!moving) begin
        $display("moving should have been asserted by now");
        $stop();
    end

    //Checking if frwrd is saturated to max speed
    repeat(25) @(posedge heading_rdy);
    assert (frwrd == 10'h300) $display("frwrd is sturated at x300");
    else begin
        $display("frwrd should be x300");
        $stop();
    end

    //First cntrIR pulse
    @(negedge clk);
    cntrIR = 1;
    @(negedge clk);
    cntrIR = 0;

    //frwrd should still be saturated
    repeat (10) @(negedge clk);

    assert (frwrd == 10'h300) $display("frwrd is sturated at x300");
    else begin
        $display("frwrd should be x300");
        $stop();
    end

    //Second cntrIR pulse
    @(negedge clk);
    cntrIR = 1;
    @(negedge clk);
    cntrIR = 0;

    repeat (4) @(negedge clk);

    assert (frwrd != 10'h300) $display("frwrd is decreasing");
    else begin
        $display("frwrd should be decreasing");
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
            if (frwrd !== 10'h000) begin
                $display("frwrd should be 0 by now");
                $stop();
            end
            if (moving) begin
                $display("moving should be deasserted by now");
                $stop();
            end
        end
    join

    //////////////////////////////////////////
    //Test 3: Another north 1 square command with lftIR and rghtIR ----Optional 
    /////////////////////////////////////////

    //Adding a pulse to lftIR and rghtIR should give a significant disturbance in error
    @(negedge clk);
    cmdRC = 16'h4001;
    snd_cmd = 1;

    @(negedge clk);
    lftIR = 1;
    snd_cmd = 0;

    repeat (500) @(negedge clk); //Observe error

    lftIR = 0; 

    repeat (500) @(negedge clk); //Observe error

    rghtIR = 1;

    repeat (500) @(negedge clk); //Observe error

    rghtIR = 0; 

    repeat (500) @(negedge clk); //Observe error

    $display("Yahoo! all tests passed");
    $stop();
end


//clock time period 10
always 
    #5 clk <= ~clk;
    

endmodule