`default_nettype none
module PID(
    input wire clk,
    input wire rst_n,
    input wire err_vld,
    input wire moving,
    input wire signed [11:0] error,
    input wire [9:0] frwrd,
    output wire signed [10:0] lft_spd,
    output wire signed [10:0] rght_spd
);

    // Internal Signals for PID Calculation
    logic signed [13:0] P_term;
    logic signed [13:0] P_term_se;
    logic signed [8:0] I_term;
    logic signed [13:0] I_term_se;
    logic signed [12:0] D_term;
    logic signed [13:0] D_term_se;
    logic signed [13:0] PID, PID_ff;
    logic [9:0] frwrd_ff;
    logic moving_ff;

    //// P term ////
    localparam signed P_COEFF = 6'h10; // P Coefficient
    logic signed [9:0] error_stat;

    // Error saturation logic
    assign error_stat = (error[11] == 1'b0 && (|error[10:9] == 1'b1)) ? 10'b0111111111 :
                        (error[11] == 1'b1 && (&error[10:9] == 1'b0)) ? 10'b1000000000 : error[9:0];

    // P-term calculation
    assign P_term = error_stat * P_COEFF;

    //// I term ////
    logic signed [14:0] ex_err_stat;
    logic signed [14:0] integrator;
    logic signed [14:0] sum_integrator;
    logic signed [14:0] nxt_integrator;
    logic signed Ofl;

    // Extended error value and saturation logic for I-term
    assign ex_err_stat = {{5{error_stat[9]}}, error_stat};
    assign sum_integrator = ex_err_stat + integrator;
    assign Ofl = ~(ex_err_stat[14]^integrator[14]) & (sum_integrator[14]^ex_err_stat[14]);

    // I-term logic: Update integrator only if error is valid and no overflow
    assign nxt_integrator = (err_vld && ~Ofl) ? (moving ? sum_integrator : 15'h0000) : (moving ? integrator : 15'h0000);
    assign I_term = integrator[14:6];

    // Flop for integration (delay integrator value)
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            integrator <= 15'h0000;
        else
            integrator <= nxt_integrator;

    //// D term ////
    localparam signed D_COEFF = 5'h07; // D Coefficient
    logic signed [9:0] q1, q2, q3, prev_err, D_diff;
    logic signed [7:0] sat_D_diff;

    // Flop for differentiation logic (store previous error values)
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            q1 <= 0;
            q2 <= 0;
            q3 <= 0;
        end else if (err_vld) begin
            q1 <= error_stat;
            q2 <= q1;
            q3 <= q2;
        end

    // D-term calculation
    assign prev_err = q3;
    assign D_diff = error_stat - prev_err;

    // Saturation logic for D-term
    assign sat_D_diff = (D_diff[9] == 1'b0 && (|D_diff[8:7] == 1'b1)) ? 8'b01111111 :
                        (D_diff[9] == 1'b1 && (&D_diff[8:7] == 1'b0)) ? 8'b10000000 : D_diff[7:0];

    // D-term final calculation
    assign D_term = D_COEFF * sat_D_diff;

    //// PID generation logic (Combining P, I, D terms) ////

    assign P_term_se = {P_term[13], P_term[13], P_term[13:1]};  // Sign extension for P-term
    assign I_term_se = {{5{I_term[8]}}, I_term};  // Sign extension for I-term
    assign D_term_se = {D_term[12], D_term};  // Sign extension for D-term
    assign PID = P_term_se + I_term_se + D_term_se;

    // Pipeline (Flop the PID output and other signals for synchronization)
    always_ff @(posedge clk) begin
            PID_ff <= PID;
            frwrd_ff <= frwrd;
            moving_ff <= moving;
    end

    // Mux logic for Left and Right speed calculation
    logic signed [10:0] lft_mux;
    assign lft_mux = moving_ff ? (PID_ff[13:3] + {1'b0, frwrd_ff}) : 11'h000;

    logic signed [10:0] rght_mux;
    assign rght_mux = moving_ff ? ({1'b0, frwrd_ff} - PID_ff[13:3]) : 11'h000;

    // Final speed values with saturation logic
    assign lft_spd = (~PID_ff[13] & lft_mux[10]) ? 11'h3ff : lft_mux;
    assign rght_spd = (PID_ff[13] & rght_mux[10]) ? 11'h3ff : rght_mux;

endmodule
`default_nettype wire
