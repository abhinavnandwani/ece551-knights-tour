module cmd_proc(clk,rst_n,cmd,cmd_rdy,clr_cmd_rdy,send_resp,strt_cal,
            cal_done,heading,heading_rdy,lftIR,cntrIR,rghtIR,error,
            frwrd,moving,tour_go,fanfare_go);
                
    parameter FAST_SIM = 1;		// speeds up incrementing of frwrd register for faster simulation
        
    input clk,rst_n;					// 50MHz clock and asynch active low reset
    input [15:0] cmd;					// command from BLE
    input cmd_rdy;					// command ready
    output logic clr_cmd_rdy;			// mark command as consumed
    output logic send_resp;			// command finished, send_response via UART_wrapper/BT
    output logic strt_cal;			// initiate calibration of gyro
    input cal_done;					// calibration of gyro done
    input signed [11:0] heading;		// heading from gyro
    input heading_rdy;				// pulses high 1 clk for valid heading reading
    input lftIR;						// nudge error +
    input cntrIR;						// center IR reading (have I passed a line)
    input rghtIR;						// nudge error -
    output reg signed [11:0] error;	// error to PID (heading - desired_heading)
    output reg [9:0] frwrd;			// forward speed register
    output logic moving;				// asserted when moving (allows yaw integration)
    output logic tour_go;				// pulse to initiate TourCmd block
    output logic fanfare_go;			// kick off the "Charge!" fanfare on piezo



    //// forward register ////

    logic inc_frwrd, dec_frwrd, clr_frwrd;
    // other variables
    logic heading_rdy;


    logic [7:0] inc;
    logic zero, max_spd, en;
    // If inc_frwrd is high, pick between 0x20 and 0x03; otherwise, 
    // if dec_frwrd is high pick double 0x20 and 0x03 otherwise 0
    generate
      if (FAST_SIM) begin
          assign inc = inc_frwrd ? 8'h20 : (dec_frwrd ? 8'hC0 : 8'h00);
      end else begin
          assign inc = inc_frwrd ? 8'h03 : (dec_frwrd ? 8'hFA : 8'h00);
      end
    endgenerate
    

    assign max_spd = &frwrd[9:8];
    assign zero = ~|frwrd;
    // Enable if increasing and not at max speed, or decreasing and not at zero
    assign en = heading_rdy && ((inc_frwrd && ~max_spd) || (dec_frwrd && ~zero));

    always_ff @(posedge clk or negedge rst_n) 
    if (!rst_n)
        frwrd <= 10'h000;
    else if (clr_frwrd)
        frwrd <= 0;
    else if (en)
        frwrd <= frwrd + inc;



    //// counting squares ////
    logic move_cmd,move_done;

    // flop for no. of squares to move //
    logic [3:0] desired_sqaures;
    always_ff@(posedge clk, negedge rst_n)
        if (!rst_n)
            desired_sqaures <= 0;
        else if (move_cmd) //en
            desired_sqaures <= {cmd[2:0],1'b0};



    // cntrIR rise edge detector
    logic cntrIR_ff, cntrIR_3ff,cntrIR_2ff,cntrIR_rise;
    always_ff@(posedge clk, negedge rst_n)
        if (!rst_n)
            {cntrIR_3ff,cntrIR_2ff,cntrIR_ff} <= 0;
        else 
            {cntrIR_3ff,cntrIR_2ff,cntrIR_ff} <= {cntrIR_2ff,cntrIR_ff,cntrIR};
    
    assign cntrIR_rise = ~cntrIR_3ff & cntrIR_2ff;

    // line counter flop //
    logic [3:0] line_counter;
    always_ff@(posedge clk, negedge rst_n) begin
        if (!rst_n)
            line_counter <= 0;
        else if (move_cmd) //clr 
            line_counter <= 0;
        else if (cntrIR_rise)
            line_counter <= line_counter + 1'b1;
    end
    
    assign move_done = !(desired_sqaures - line_counter) ? 1'b1 : 1'b0; 


    //// PID interface ////

    // desired_heading flop //
    logic signed [12:0] desired_heading;
    always_ff@(posedge clk, negedge rst_n)
        if(!rst_n)
            desired_heading <= 0;
        else if (move_cmd)
            if (cmd[11:4] == 0) //non zero check  
                desired_heading <= 0;
            else 
                desired_heading <= {cmd[11:4], 4'b1111};

    // err_nudge logic //
    logic [11:0] nudge_left, nudge_right;
    logic err_nudge;
    generate
    if (FAST_SIM) begin
          assign nudge_left  = lftIR  ? 12'h1FF : 12'h000;
          assign nudge_right = rghtIR ? 12'hE00 : 12'h000;
      end else begin
          assign nudge_left  = lftIR  ? 12'h05F : 12'h000;
          assign nudge_right = rghtIR ? 12'hFA1 : 12'h000;
      end
    endgenerate

    assign err_nudge = nudge_left + nudge_right;

    assign error = heading - desired_heading + err_nudge;




    //// control FSM ////
    typedef enum logic [2:0] {IDLE, CALIBRATE, MOVE_I, MOVE_II, MOVE_III} state_t;
    state_t state, nxt_state;

    // state flop //
    always_ff@(posedge clk, negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else 
            state <= nxt_state;

    always_comb begin
        clr_cmd_rdy = 0;
        strt_cal = 0;
        move_cmd = 0;
        fanfare_go = 0;
        clr_frwrd = 0;
        inc_frwrd = 0;
        dec_frwrd = 0;
        moving = 1'b0;
        send_resp = 0;
        nxt_state = state;
     

        case (state)

        CALIBRATE : if (cal_done) begin send_resp = 1'b1; nxt_state = IDLE; end
        MOVE_I : begin
                    moving = 1'b1;
                    clr_frwrd = 1'b1;
                    if ((error < $signed(12'h02C)) && (error > $signed(12'hfd4))) 
                        nxt_state = MOVE_II; 
        end
        MOVE_II : begin
                    moving = 1'b1;
                    inc_frwrd = 1'b1;
                    if (move_done) begin
                        fanfare_go = cmd[12];
                        nxt_state = MOVE_III;
                    end
        end
        MOVE_III : begin
                    moving = 1'b1;
                    dec_frwrd = 1'b1;
                    if (zero) begin
                         send_resp = 1'b1;
                         nxt_state = IDLE;
                    end
        end             
        // IDLE state //
        default : if (cmd_rdy) begin
                    clr_cmd_rdy = 1'b1;
                    casex(cmd[15:12])
                    4'b0010 : begin nxt_state = CALIBRATE; strt_cal =  1'b1; end
                    4'b010x : begin nxt_state = MOVE_I; move_cmd = 1'b1; end
                    4'b0110 : tour_go = 1'b1; // hand off to tour module
                    default : nxt_state = state;
                    endcase
        end 
        endcase
    end
    endmodule