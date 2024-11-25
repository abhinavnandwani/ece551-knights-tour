//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of robot.  Fusion correction comes    //
// from "gaurdrail" signals lftIR/rghtIR.       //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,
                  rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

  parameter FAST_SIM = 1;	// used to speed up simulation
  
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  input strt_cal;				// initiate claibration of yaw readings
  input moving;					// Only integrate yaw when going
  input lftIR,rghtIR;			// gaurdrail sensors
  
  output cal_done;				// pulses high for 1 clock when calibration done
  output signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
  output rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
  output SS_n,SCLK,MOSI;		// SPI outputs


  //////////////////////////////////
  // Declare any internal signal //
  ////////////////////////////////
  logic vld;		// vld yaw_rt provided to inertial_integrator
  logic snd, done, C_Y_H, C_Y_L, int_ff2, int_ff1;
  logic [15:0] cmd, yaw_rt, timer, resp;
  logic [7:0] resp_used, yaw_H, yaw_L;
  
  //////////////////////////////////////////////
  // Declare states for State machine set-up //
  ////////////////////////////////////////////
  typedef enum {INIT1, INIT2, INIT3, INIT4, IDLE, READ_YAW_H, READ_YAW_L} state_t;
  state_t state, nxt_state;
  
  ///////////////////////////////////////////////////////////////////
  // Do relevant assign statements to convert into useful signals //
  /////////////////////////////////////////////////////////////////
  assign resp_used = resp[7:0];
  assign yaw_rt = {yaw_H, yaw_L};

  ///////////////////////////////////////////////////////////////////
  // Create the two flip flops which will be compiled into yaw_rt //
  /////////////////////////////////////////////////////////////////
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  yaw_H <= 8'h00;
	else if (C_Y_H)
	  yaw_H <= resp_used;
  end
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  yaw_L <= 8'h00;
	else if (C_Y_L)
	  yaw_L <= resp_used;
  end

  ////////////////////////////////
  // Set up the timer to count //
  //////////////////////////////
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  timer <= 16'h0000;
	else 
	  timer <= timer + 1;
  end


  ////////////////////////////
  // Double flop interrupt //
  //////////////////////////
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
	  int_ff1 <= 0;
	  int_ff2 <= 0;
	end
	else begin
	  int_ff1 <= INT;
	  int_ff2 <= int_ff1;
    end
  end

  /////////////////////////////////////
  // Create the state machine setup //
  ///////////////////////////////////
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= INIT1;
	else 
	  state <= nxt_state;
  end
  
  /////////////////////////////////////
  // Actually run the state machine //
  ///////////////////////////////////
  always_comb begin
    nxt_state = state;
	cmd = 16'h8000; // Set to always be reading from a register so no unexpected writes occur
	snd = 0;
	C_Y_H = 0;
	C_Y_L = 0;
	vld = 0;
	case (state)
	  INIT1: 
	    if (&timer) begin
		  nxt_state = INIT2;
		  snd = 1;
		  cmd = 16'h0D02;
		end
	  INIT2:
	    if (done) begin
		  nxt_state = INIT3;
		  snd = 1;
		  cmd = 16'h1160;
		end
	  INIT3:
	    if (done) begin
		  nxt_state = INIT4;
		  snd = 1;
		  cmd = 16'h1440;
		end
      INIT4: // This state exists to act as a buffer between the infinite loop and the set-up phase,
	         // making sure that every initialized variable is set before we begin reading
	    if (done) begin
		  nxt_state = IDLE;
		end
		else begin
		  vld = 1;
		end
	  IDLE:
	    if (int_ff2) begin
		  nxt_state = READ_YAW_L;
		  snd = 1;
		  cmd = 16'hA6xx;
		end
	  READ_YAW_L:
	    if (done) begin
		  nxt_state = READ_YAW_H;
		  snd = 1;
		  C_Y_L = 1;
		  cmd = 16'hA7xx;
		end
	  READ_YAW_H:
	    if (done) begin
		  nxt_state = IDLE;
		  C_Y_H = 1;
		  vld = 1;
		end
	endcase
  end

  ///////////////////////////////
  // Initiate SPI_mnrch block //
  /////////////////////////////
  SPI_mnrch iTRAN(.*);
  
 
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces a heading reading         //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),.vld(vld),
                           .rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
                           .rghtIR(rghtIR),.heading(heading));
						   

endmodule
	  