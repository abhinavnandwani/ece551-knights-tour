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

    logic signed [13:0] P_term;
    logic signed [13:0] P_term_se, P_term_ff, P_term_3ff;
    logic signed [8:0] I_term;
    logic signed [13:0] I_term_se, I_term_ff, I_term_3ff;
    logic signed [12:0] D_term;
    logic signed [13:0] D_term_se, D_term_ff, D_term_3ff;
    logic signed [13:0] PID;

    // Stage 1: Flop inputs to break max comb delay
    logic [9:0] frwrd_ff, frwrd_2ff, frwrd_3ff;
    logic signed [11:0] error_ff;
    logic moving_ff, err_vld_ff, err_vld_2ff, moving_2ff, moving_3ff;
    always @(posedge clk) begin
        err_vld_ff <= err_vld;
        error_ff <= error;
        moving_ff <= moving;
        frwrd_ff <= frwrd;
    end

    //// P term ////
    localparam signed P_COEFF = 6'h10;
    logic signed [9:0] error_stat, error_stat_2ff;
    assign error_stat = (error_ff[11] == 1'b0 && (|error_ff[10:9] == 1'b1)) ? 10'b0111111111 :
                        (error_ff[11] == 1'b1 && (&error_ff[10:9] == 1'b0)) ? 10'b1000000000 : error_ff[9:0];
    assign P_term = error_stat * P_COEFF;

    //// I term ////
    logic signed [14:0] ex_err_stat;
    logic signed [14:0] integrator;
    logic signed [14:0] sum_integrator;
    logic signed [14:0] nxt_integrator;
    logic signed Ofl;

    assign ex_err_stat = {{5{error_stat[9]}}, error_stat};
    assign sum_integrator = ex_err_stat + integrator;
    assign Ofl = ~(ex_err_stat[14] ^ integrator[14]) & (sum_integrator[14] ^ ex_err_stat[14]);
    assign nxt_integrator = (err_vld && ~Ofl) ? (moving_ff ? sum_integrator : 15'h0000) : (moving_ff ? integrator : 15'h0000);
    assign I_term = integrator[14:6];

    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            integrator <= 15'h0000;
        else
            integrator <= nxt_integrator;

    //// D term ////
    localparam signed D_COEFF = 5'h07;
    logic signed [9:0] q1, q2, q3, prev_err, D_diff;
    logic signed [7:0] sat_D_diff;

    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            q1 <= 0;
            q2 <= 0;
            q3 <= 0;
        end else if (err_vld_2ff) begin
            q1 <= error_stat_2ff;
            q2 <= q1;
            q3 <= q2;
        end

    assign prev_err = q3;
    assign D_diff = error_stat_2ff - prev_err;
    assign sat_D_diff = (D_diff[9] == 1'b0 && (|D_diff[8:7] == 1'b1)) ? 8'b01111111 :
                        (D_diff[9] == 1'b1 && (&D_diff[8:7] == 1'b0)) ? 8'b10000000 : D_diff[7:0];
    assign D_term = D_COEFF * sat_D_diff;

    //// Stage 3: Flop terms for alignment ////
    always @(posedge clk, negedge rst_n) begin
            D_term_se <= {D_term[12], D_term};
            P_term_ff <= P_term_se;
            I_term_ff <= I_term_se;
            err_vld_2ff <= err_vld_ff;
            moving_2ff <= moving_ff;
            frwrd_2ff <= frwrd_ff;
            error_stat_2ff <= error_stat;
    end

    // Stage 4: Final flop for D term and alignment of all terms
    always @(posedge clk) begin
        D_term_3ff <= D_term_se;
        P_term_3ff <= P_term_ff;
        I_term_3ff <= I_term_ff;
        moving_3ff <= moving_2ff;
        frwrd_3ff <= frwrd_2ff;
    end

    //// PID generation logic ////
    assign P_term_se = {P_term[13], P_term[13], P_term[13:1]};
    assign I_term_se = {{5{I_term[8]}}, I_term};

    assign PID = (P_term_3ff + I_term_3ff + D_term_3ff);

    //// Output MUX ////
    logic signed [10:0] lft_mux;
    assign lft_mux = moving_3ff ? (PID[13:3] + {1'b0, frwrd_3ff}) : 11'h000;

    logic signed [10:0] rght_mux;
    assign rght_mux = moving_3ff ? ({1'b0, frwrd_3ff} - PID[13:3]) : 11'h000;

    assign lft_spd = (~PID[13] & lft_mux[10]) ? 11'h3ff : lft_mux;
    assign rght_spd = (PID[13] & rght_mux[10]) ? 11'h3ff : rght_mux;

endmodule
`default_nettype wire
