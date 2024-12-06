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



    // task 6 : transmission with BLE //
    
    task automatic verifyCoordinates(
    	input logic [14:0] expected_x,
    	input logic [14:0] expected_y,
    	input logic [14:0] xx,
    	input logic [14:0] yy
    );
    	// Define the range as +/- 0.5 * 4096
    	localparam signed [14:0] tolerance = 15'd2048;

    	// Print the expected and actual coordinates
    	$display("Verifying Coordinates at time %0t", $time);
    	$display("Expected X: %0d, Y: %0d", expected_x, expected_y);
    	$display("Actual   X: %0d, Y: %0d", xx, yy);

    	// Check X coordinate
    	if ((xx < (expected_x - tolerance)) || (xx > (expected_x + tolerance))) begin
        	$error("X coordinate out of range: Expected [%0d ± %0d], Got %0d at time %0t",
            	expected_x, tolerance, xx, $time);
   	 end else begin
        	$display("X coordinate is within the expected range.");
    	end

    	// Check Y coordinate
    	if ((yy < (expected_y - tolerance)) || (yy > (expected_y + tolerance))) begin
        	$error("Y coordinate out of range: Expected [%0d ± %0d], Got %0d at time %0t",
            	expected_y, tolerance, yy, $time);
    	end else begin
     	   	$display("Y coordinate is within the expected range.");
    	end
    endtask

endpackage



