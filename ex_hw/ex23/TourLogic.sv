module TourLogic(
    input clk, rst_n,            // 50MHz clock and active low async reset
    input [2:0] x_start, y_start,// Starting position on 5x5 board
    input go,                    // Start calculation of solution
    input [4:0] indx,            // Index of move to read out
    output logic done,           // Pulses high when solution is complete
    output [7:0] move            // Move addressed by indx (1 of 24 moves)
);

    // Registers to represent the board and control signals
    reg [4:0] board[0:4][0:4];   // 5x5 board to track visited positions
    reg [7:0] last_move[0:23];   // Last move tried for each index
    reg [7:0] poss_moves[0:23];  // Possible moves from each position (8-bit one hot)
    reg [7:0] move_try;          // Next move to try
    reg [4:0] move_num;          // Current move number
    reg [2:0] xx, yy;            // Current x and y position
    reg zero, init, update_position, backup; // Control signals for board updates

    // State machine for controlling the Knight's tour
    typedef enum reg [2:0] {IDLE, INIT, TRY_MOVE, BACKTRACK, COMPLETE} state_t;
    state_t state, nxt_state;

    // State transition logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // Control signal generation and next state logic
    always_comb begin
        // Default values
        zero = 0;
        init = 0;
        update_position = 0;
        backup = 0;
        done = 0;
        nxt_state = state;

        case (state)
            IDLE: begin
                if (go) begin
                    zero = 1;
                    nxt_state = INIT;
                end
            end
            INIT: begin
                init = 1;
                xx = x_start;
                yy = y_start;
                move_num = 0;
                nxt_state = TRY_MOVE;
            end
            TRY_MOVE: begin
                // Check if current move is valid
                move_try = poss_moves[move_num] & ~last_move[move_num];
                if (move_try != 0) begin
                    update_position = 1;
                    nxt_state = TRY_MOVE;
                end else if (move_num == 23) begin
                    done = 1;
                    nxt_state = COMPLETE;
                end else begin
                    backup = 1;
                    nxt_state = BACKTRACK;
                end
            end
            BACKTRACK: begin
                if (move_num > 0) begin
                    move_num = move_num - 1;
                    xx = xx - off_x(last_move[move_num]);
                    yy = yy - off_y(last_move[move_num]);
                    nxt_state = TRY_MOVE;
                end else begin
                    nxt_state = COMPLETE;
                end
            end
            COMPLETE: begin
                done = 1;
                nxt_state = IDLE;
            end
        endcase
    end

    // Update board state
    always_ff @(posedge clk) begin
        if (zero) begin
            board <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
        end else if (init) begin
            board[x_start][y_start] <= 5'h1; // Mark starting position
        end else if (update_position) begin
            board[xx][yy] <= move_num + 2; // Mark current position as visited
        end else if (backup) begin
            board[xx][yy] <= 5'h0; // Mark current position as unvisited
        end
    end

    // Function to calculate possible moves from a given position
    function [7:0] calc_poss(input [2:0] xpos, ypos);
        begin
            calc_poss = 8'b0;
            if (xpos > 1 && ypos > 0) calc_poss[0] = 1; // Move 0
            if (xpos > 0 && ypos > 1) calc_poss[1] = 1; // Move 1
            if (xpos < 4 && ypos > 1) calc_poss[2] = 1; // Move 2
            if (xpos < 3 && ypos > 0) calc_poss[3] = 1; // Move 3
            if (xpos < 3 && ypos < 4) calc_poss[4] = 1; // Move 4
            if (xpos < 4 && ypos < 3) calc_poss[5] = 1; // Move 5
            if (xpos > 0 && ypos < 3) calc_poss[6] = 1; // Move 6
            if (xpos > 1 && ypos < 4) calc_poss[7] = 1; // Move 7
        end
    endfunction

    // Functions to calculate move offsets
    function signed [2:0] off_x(input [7:0] try);
        case (try)
            8'b00000001: off_x = -2;
            8'b00000010: off_x = -1;
            8'b00000100: off_x = 1;
            8'b00001000: off_x = 2;
            8'b00010000: off_x = 2;
            8'b00100000: off_x = 1;
            8'b01000000: off_x = -1;
            8'b10000000: off_x = -2;
            default: off_x = 0;
        endcase
    endfunction

    function signed [2:0] off_y(input [7:0] try);
        case (try)
            8'b00000001: off_y = -1;
            8'b00000010: off_y = -2;
            8'b00000100: off_y = -2;
            8'b00001000: off_y = -1;
            8'b00010000: off_y = 1;
            8'b00100000: off_y = 2;
            8'b01000000: off_y = 2;
            8'b10000000: off_y = 1;
            default: off_y = 0;
        endcase
    endfunction

endmodule
