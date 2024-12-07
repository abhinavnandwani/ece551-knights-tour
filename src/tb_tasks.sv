package tb_tasks;



    // task 1 : nemo setup //
    task automatic nemosetup(ref clk, NEMO_setup);
        fork
            begin: timeoutSetup
                repeat (100000) @(posedge clk);
                $display("Timed out waiting for Nemo_setup");
                $stop();
            end
            begin
                @(posedge NEMO_setup);
                disable timeoutSetup;
                $display("NEMO_setup asserted");
            end
        join
    endtask

    // task 2 : calibrate //
    task automatic calibrateDUT (ref clk, cal_done,send_cmd,[15:0] cmd);

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
                @(posedge cal_done);
                disable timeoutCal;
                $display("cal_done asserted");
            end
        join
    endtask

    task automatic waitRespRdy(ref clk, resp_rdy);
        fork
            begin: TimeoutRespRdy
                repeat (1000000) @(negedge clk);
                $display("Timed out waiting for resp rdy");
                $stop();
            end
            begin
                @(posedge resp_rdy);
                disable TimeoutRespRdy;
                $display("resp_rdy asserted");
            end
        join
    endtask

    // task 3: compare err change//
    task automatic compareErr (ref [11:0] prev, [11:0] now, output logic [11:0] compE);
        begin
        compE = now - prev; 
        end
    endtask

    // task 4: compare omega_sum change//
    task automatic compareOm(ref [16:0] prev, [16:0] now, output logic [16:0] compE);
        begin
        compE = now - prev; 
        end
    endtask

    //task 6: MTR output checks//
    task automatic mtrOutputCheck(ref lftIR_n, rghtIR_n, [10:0] linput, [10:0] rinput);
        begin
            if (lftIR_n !== 1) begin
                $display("Since wheels are not moving, lftIR_n should be 1");
                $stop();
            end

            if (rghtIR_n !== 1) begin
                $display("Since wheels are not moving, rghtIR_n should be 1");
                $stop();
            end

            assert (linput == 11'h400) $display("Duty cycle for left is at 50 percent at reset");
            else begin
                $display("Duty cycle for left is not at 50 per cent at reset %h", linput);
                $stop();
            end

            assert (rinput == 11'h400) $display("Duty cycle for right is at 50 percent at reset");
            else begin
                $display("Duty cycle for right is not at 50 per cent at reset");
                $stop();
            end
        end
    endtask

    // task 3 : tour with a initial x,y //
    task automatic startTour (ref clk, send_cmd,[15:0] cmd,input [3:0] x_start, [3:0] y_start);
      
        @(negedge clk);
        cmd = {8'h60,x_start,y_start};
        send_cmd = 1;
        @(negedge clk);
        send_cmd = 0; 
    endtask

    // task 4 : move the robot //

    task automatic moveKnight (ref clk, send_cmd,[15:0] cmd,input [7:0] heading, [2:0] squares);
      
        @(negedge clk);
        cmd = {8'h40,heading,1'b0,squares};
        send_cmd = 1;
        @(negedge clk);
        send_cmd = 0; 
    endtask

    // task 5 : move with fanfare //
    task automatic moveFanfare (ref clk, send_cmd,[15:0] cmd,input [7:0] heading, [2:0] squares);
      
        @(negedge clk);
        cmd = {8'h50,heading,1'b0,squares};
        send_cmd = 1;
        @(negedge clk);
        send_cmd = 0; 
    endtask



    // task 6 : Heading converging or not//
    logic [11:0] diff;
    task automatic checkConvHeading(ref [12:0] desiredHeading, [11:0] heading);
        diff = desiredHeading[11:0] - heading;
        if (diff[11]) begin
            if ((~diff) + 1 > 12'h064) begin
                $display("Heading has not converged to the expected value");
                $stop();
            end
        end
        else begin
            if (diff > 12'h064) begin
                $display("Heading has not converged to the expected value");
                $stop();
            end
        end
        $display("Heading has converged at %h", heading); 
    endtask


endpackage


