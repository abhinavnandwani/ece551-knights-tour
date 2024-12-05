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
        cmd = {8'h40,heading,1'0,squares};
        send_cmd = 1;
        @(negedge clk);
        send_cmd = 0; 
    endtask

    // task 5 : move with fanfare //
    task automatic moveFanfare (ref clk, send_cmd,[15:0] cmd,input [7:0] heading, [2:0] squares);
      
        @(negedge clk);
        cmd = {8'h50,heading,1'0,squares};
        send_cmd = 1;
        @(negedge clk);
        send_cmd = 0; 
    endtask



    // task 6 : transmission with BLE //



