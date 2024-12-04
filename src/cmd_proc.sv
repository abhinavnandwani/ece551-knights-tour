/* 
    Team            : Latch Liberation Front - Abhinav, Damion, Miles, YV
    Filename        : cmd_proc.sv  
*/

module cmd_proc(
    input clk,                        // 50MHz clock
    input rst_n,                      // Asynchronous active-low reset
    input [15:0] cmd,                 // Command from BLE
    input cmd_rdy,                    // Command ready
    output logic clr_cmd_rdy,         // Mark command as consumed
    output logic send_resp,           // Command finished, send response via UART_wrapper/BT
    output logic strt_cal,            // Initiate calibration of gyro
    input cal_done,                   // Calibration of gyro done
    input signed [11:0] heading,      // Heading from gyro
    input heading_rdy,                // Pulse high for valid heading reading
    input lftIR,                      // Nudge error +
    input cntrIR,                     // Center IR reading (line passed)
    input rghtIR,                     // Nudge error -
    output reg signed [11:0] error,   // Error to PID (heading - desired_heading)
    output reg [9:0] frwrd,           // Forward speed register
    output logic moving,              // Asserted when moving (enables yaw integration)
    output logic tour_go,             // Pulse to initiate TourCmd block
    output logic fanfare_go           // Kick off "Charge!" fanfare on piezo
);

    parameter FAST_SIM = 1; // Speeds up simulation

    //// Forward Register Logic ////
    logic inc_frwrd, dec_frwrd, clr_frwrd;
    logic [7:0] inc;
    logic zero, max_spd, en;

    // Increment logic based on simulation speed //
    generate
        if (FAST_SIM) assign inc = inc_frwrd ? 8'h20 : (dec_frwrd ? 8'hC0 : 8'h00);
        else assign inc = inc_frwrd ? 8'h03 : (dec_frwrd ? 8'hFA : 8'h00);
    endgenerate

    assign max_spd = &frwrd[9:8]; // Detect maximum speed
    assign zero = ~|frwrd;        // Detect zero speed
    assign en = heading_rdy && ((inc_frwrd && ~max_spd) || (dec_frwrd && ~zero));

    // Forward register behavior //
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            frwrd <= 10'h000;
        else if (clr_frwrd)
            frwrd <= 0;
        else if (en)
            frwrd <= frwrd + inc;
    end

    //// Counting Squares ////
    logic move_cmd, move_done;
    logic [3:0] desired_squares;

    // Number of squares to move //
    always_ff @(posedge clk) 
         if (move_cmd)
            desired_squares <= {cmd[2:0], 1'b0};
    

    // Center IR rise edge detection //
    logic cntrIR_ff, cntrIR_3ff, cntrIR_2ff, cntrIR_rise;
    always_ff @(posedge clk or negedge rst_n) 
        if (!rst_n)
            {cntrIR_3ff, cntrIR_2ff, cntrIR_ff} <= 0;
        else
            {cntrIR_3ff, cntrIR_2ff, cntrIR_ff} <= {cntrIR_2ff, cntrIR_ff, cntrIR};
    

    assign cntrIR_rise = ~cntrIR_3ff & cntrIR_2ff;

    // Line counter logic //
    logic [3:0] line_counter;

    always_ff @(posedge clk or negedge rst_n) 
        if (!rst_n)
            line_counter <= 0;
        else if (move_cmd)
            line_counter <= 0;
        else if (cntrIR_rise)
            line_counter <= line_counter + 1'b1;
    

    assign move_done = !(desired_squares - line_counter);

    //// PID Interface ////
    logic signed [12:0] desired_heading;

    // Desired heading logic //
    always_ff @(posedge clk or negedge rst_n) 
        if (!rst_n)
            desired_heading <= 0;
        else if (move_cmd) 
            if (cmd[11:4] == 0)
                desired_heading <= 0;
            else
                desired_heading <= {cmd[11:4], 4'b1111};
        
    

    // Error nudge logic //
    logic [11:0] nudge_left, nudge_right;
    logic err_nudge;

    generate
        if (FAST_SIM) begin
            assign nudge_left = lftIR ? 12'h1FF : 12'h000;
            assign nudge_right = rghtIR ? 12'hE00 : 12'h000;
        end 
        else begin
            assign nudge_left = lftIR ? 12'h05F : 12'h000;
            assign nudge_right = rghtIR ? 12'hFA1 : 12'h000;
        end
    endgenerate

    assign err_nudge = nudge_left + nudge_right;
    assign error = heading - desired_heading + err_nudge;

    //// Control FSM ////
    typedef enum logic [2:0] {IDLE, CALIBRATE, MOVE_I, MOVE_II, MOVE_III} state_t;
    state_t state, nxt_state;

    // State register //
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // FSM logic //
    always_comb begin

        // default outputs //
        clr_cmd_rdy = 0;
        strt_cal = 0;
        move_cmd = 0;
        fanfare_go = 0;
        clr_frwrd = 0;
        inc_frwrd = 0;
        dec_frwrd = 0;
        moving = 0;
        tour_go = 0;
        send_resp = 0;
        nxt_state = state;

        case (state)
        CALIBRATE: begin  // Wait for gyro calibration to complete, then return to IDLE
            if (cal_done) begin
                send_resp = 1'b1;
                nxt_state = IDLE;
            end
        end
        MOVE_I: begin  // Wait for error to settle within range
            moving = 1'b1;
            clr_frwrd = 1'b1; // To keep forward register stable
            if ((error < $signed(12'h02C)) && (error > $signed(12'hFD4)))
                nxt_state = MOVE_II;
        end
        MOVE_II: begin // Increment forward speed and monitor movement progress
            moving = 1'b1;
            inc_frwrd = 1'b1;
            if (move_done) begin
                fanfare_go = cmd[12];
                nxt_state = MOVE_III;
            end
        end
        MOVE_III: begin // Decrement forward speed and return to IDLE when speed reaches zero
            moving = 1'b1;
            dec_frwrd = 1'b1;
            if (zero) begin
                send_resp = 1'b1;
                nxt_state = IDLE;
            end
        end
        default: begin // IDLE: wait for a new command and handle it
            if (cmd_rdy) begin
                clr_cmd_rdy = 1'b1;
                casex (cmd[15:12]) // case for opcode
                4'b0010: begin nxt_state = CALIBRATE; strt_cal = 1'b1; end
                4'b010x: begin nxt_state = MOVE_I; move_cmd = 1'b1; end
                4'b0110: tour_go = 1'b1; // Hand off to tour module
                
                default: nxt_state = state; // alpha particle collision handling
                endcase
            end
        end
        endcase
    end

endmodule
