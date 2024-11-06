//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.       //
// This application uses only the Z-axis gyro for   //
// robot heading, with fusion correction from       //
// "guardrail" signals (lftIR/rghtIR).              //
//////////////////////////////////////////////////////
module inert_intf (
    input wire clk, rst_n,             // Clock and active-low reset
    input wire MISO,                   // SPI input from inertial sensor
    input wire INT,                    // Measurement ready interrupt
    input wire strt_cal,               // Start calibration for yaw readings
    input wire moving,                 // Enable yaw integration only when moving
    input wire lftIR, rghtIR,          // Guardrail sensors
    output wire cal_done,              // High pulse when calibration completes
    output wire signed [11:0] heading, // Robot heading (000=Orig, 3FF=90 CCW, 7FF=180 CCW)
    output wire rdy,                   // High pulse when new data is ready
    output wire SS_n, SCLK, MOSI       // SPI outputs
);

  parameter FAST_SIM = 1; // Speed up simulation


  logic [15:0] cmd, resp;        // SPI command and response
  logic [15:0] yaw_rf;           // Holds the yaw reading
  logic C_Y_L;      // Yaw rate low

  logic snd, done;               // SPI control signals
  logic vld;                     // Valid yaw reading signal for inertial_integrator
  logic [15:0] timer;            // Timer for delay
  logic INT_FF1, INT_FF2;        // Double-flop synchronization for INT

  // State Encoding
  typedef enum logic [2:0] { INIT1, INIT2, INIT3, INFLOOP, YAWL, YAWH } state_t; //only 6 states needed for our optimization
  state_t state, next_state;

  ///////////////////////////////////////
  // Timer Logic                       //
  // Simple 16-bit counter increments  //
  // every clock cycle until reset.    //
  ///////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      timer <= 16'd0;
    else
      timer <= timer + 1;
  end

  //////////////////////////////////////
  // SPI Interface Instantiation      //
  //////////////////////////////////////
  SPI_mnrch spi_interface (
    .clk(clk),
    .rst_n(rst_n),
    .snd(snd),
    .cmd(cmd),
    .done(done),
    .resp(resp),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO)
  );

  ////////////////////////////////////////////////////////////////
  // State Machine to Handle Initialization and Data Retrieval  //
  ////////////////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= INIT1;
    else
      state <= next_state;
  end

  // Next State and Output Logic
  always_comb begin
    // Default values for outputs and control signals
    next_state = state;
    snd = 0;
    vld = 0;
    C_Y_L = 0;
    cmd = 0;

    case (state)

      INIT2: begin
        // Configuring gyro for 416Hz data rate, �250�/sec range
        cmd = 16'h1160;
        if (done) begin
          snd = 1'b1;
          next_state = INIT3;
        end
      end

      INIT3: begin
        // Enabling gyro rounding
        cmd = 16'h1444;
        if (done) begin
          snd = 1'b1;
          next_state = INFLOOP;
        end
      end

      INFLOOP: begin
        // Waiting for new data
        if (INT_FF2) begin
          snd = 1'b1;
          cmd[15:8] = 8'hA6; // Read yaw rate low byte
          next_state = YAWL;
        end
      end

      YAWL: begin
        if (done) begin
          C_Y_L = 1;
          snd = 1'b1;
          cmd[15:8] = 8'hA7; // Read yaw rate high byte
          next_state = YAWH;
        end
      end

      YAWH: begin //signal C_Y_H omitted for our optimization, only vld needed
        if (done) begin 
          vld = 1'b1; // Valid yaw reading for inertial_integrator
          next_state = INFLOOP;
        end
      end

      // default state is INIT1
      default: begin
        // Initializing interrupt on data ready
        cmd = 16'h0D02;
        if (&timer) begin
          snd = 1'b1;
          next_state = INIT2;
        end
      end
    endcase
  end


  ////////////////////////////////////////////////
  // Instantiate Angle Engine                   //
  // Processes angular rate readings to produce //
  // a heading reading.                         //
  ////////////////////////////////////////////////

  inertial_integrator #(FAST_SIM) iINT (
    .clk(clk),
    .rst_n(rst_n),
    .strt_cal(strt_cal),
    .vld(vld),
    .rdy(rdy),
    .cal_done(cal_done),
    .yaw_rt(yaw_rf),
    .moving(moving),
    .lftIR(lftIR),
    .rghtIR(rghtIR),
    .heading(heading)
  );


  // INT DOUBLE FLOP for meta stability //
  always_ff @(posedge clk, negedge rst_n) 
      if (!rst_n)
        {INT_FF1,INT_FF2} <= 2'b0;
      else
        {INT_FF2,INT_FF1} <= {INT_FF1, INT};

  


  // HOLDING REGISTERS // 

  //  we have an optimization where we only store the low (first) byte and only use 1 8-bit flop insetad of 2
  logic [7:0] flopped_yaw_l;
  
  // store the first (low) byte //
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      flopped_yaw_l <= 0;
    else if (C_Y_L)
      flopped_yaw_l <= resp[7:0];
  

  assign yaw_rf = {resp[7:0], flopped_yaw_l};


endmodule
