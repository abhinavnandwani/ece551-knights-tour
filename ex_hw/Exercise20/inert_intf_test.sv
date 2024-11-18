

module inert_intf_test(
  input clk,
  input RST_n,
  input MISO,
  input INT,
  output SS_n,
  output SCLK,
  output MOSI,
  output [7:0] LED
);

  logic rst_n;
  logic strt_cal, cal_done;
  logic sel;
  logic [11:0] heading;

  reset_synch iRST_n(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

  inert_intf iINERT(
    .clk(clk),
    .rst_n(rst_n),
    .MISO(MISO),
    .INT(INT),
    .strt_cal(strt_cal),
    .moving(1'b1),         	// Enable yaw integration
    .lftIR(1'b0),          	// Guardrail sensors inactive
    .rghtIR(1'b0),
    .cal_done(cal_done),
    .heading(heading),
    .rdy(),			// leave unconnected
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI)
  );

  typedef enum logic [1:0] { IDLE, CAL, DISP } state_t;  
  state_t next_state, state;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;

  always_comb begin
    strt_cal = 1'b0;
    sel = 1'b0;
    next_state = state;
  
    case (state)
      IDLE: begin
          next_state = CAL;
	  strt_cal = 1'b1;
        end
      CAL: begin
        sel = 1'b1;
        if (cal_done)
 	  next_state = DISP;
	end
      DISP:
	// Do nothing
        sel = 1'b0;
      default: next_state = IDLE; 
    endcase
  end

  assign LED = sel ? 8'hA5 : heading[11:4];

endmodule
