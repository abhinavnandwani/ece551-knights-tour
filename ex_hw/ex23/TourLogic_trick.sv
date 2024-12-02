module TourLogic(
    input logic clk, rst_n,               // 50MHz clock and async active low reset
    input logic [2:0] x_start, y_start,   // Starting position of the knight
    input logic go,                       // Start signal to begin the knight's tour
    input logic [4:0] indx,               // Move index to retrieve specific move
    output logic done,                    // Pulses high when the tour is complete
    output logic [7:0] move               // The current move in one-hot encoding
);

    // Internal signals and registers
    logic [4:0] board[0:4][0:4];          // 5x5 board tracking visited positions
    logic [7:0] last_move[0:23];          // Array storing the last move taken at each step
    logic [7:0] poss_moves[0:23];         // Array storing possible moves at each step
    logic [4:0] move_num;                 // Current move number (1 to 24)
    logic [2:0] xx, yy;                   // Current knight position
    logic [2:0] nxt_xx, nxt_yy;           // Next knight position
    logic update_position,init;

    // Knight's possible moves (delta values)
    logic signed [2:0] dx[0:7], dy[0:7];

    assign dx = {1,-1,-2,-2,-1,1,2,2};
    assign dy = {2,2,1,-1,-2,-2,-1,1};

    // FSM states
    typedef enum logic [2:0] {
        IDLE, INIT, CALC_MOVES, SELECT_MOVE, UPDATE_POS, COMPLETE
    } state_t;
    state_t state, next_state;

    // State flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Function to calculate onward degree of a position
    function automatic logic [3:0] calculate_degree(input logic [2:0] tmp_x, tmp_y);
        logic [3:0] degree;
        logic [2:0] new_x;
        logic [2:0] new_y;
        degree = 0;
        for (int j = 0; j < 8; j++) begin
             new_x = tmp_x + dx[j];
             new_y = tmp_y + dy[j];
            if (new_x >= 0 && new_x < 5 && new_y >= 0 && new_y < 5 && board[new_x][new_y] == 0)
                degree++;
        end
        return degree;
    endfunction

    // move register 
    always_ff@(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            xx <= 0;
            yy <= 0;
        end else if (init) begin
            xx <= x_start;
            yy <= y_start;
        end else if (update_position) begin
            xx <= nxt_xx;
            yy <= nxt_yy;
        end
    end

    // board register 
    always_ff@(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 5; i++)
                for (int j = 0; j < 5; j++)
                    board[i][j] <= 0;
        end else if (init) begin
            board[x_start][y_start] <= 5'h1;
        end else if (update_position) begin
            board[nxt_xx][nxt_yy] <= move_num + 1;
        end
    end
    

        

    // FSM next state and output logic
    always_comb begin
        // Default values
        next_state = state;
        done = 0;
        update_position = 0;
        init = 0;

        case (state)
            IDLE: begin
                if (go) begin
                    next_state = INIT;
                end
            end

            INIT: begin
                // Initialize board and position
                init = 1'b1;
                move_num = 1;
                next_state = CALC_MOVES;
            end

            CALC_MOVES: begin
                // Calculate all possible moves from the current position
                poss_moves[move_num] = 0;
                for (int i = 0; i < 8; i++) begin
                    nxt_xx = xx + dx[i];
                    nxt_yy = yy + dy[i];
                    if (nxt_xx >= 0 && nxt_xx < 5 && nxt_yy >= 0 && nxt_yy < 5 && board[nxt_xx][nxt_yy] == 0) begin
                        poss_moves[move_num][i] = 1;
                    end
                end
                next_state = SELECT_MOVE;
            end

            SELECT_MOVE: begin
                // Select the move with the lowest onward degree
                logic [3:0] min_degree;
                min_degree = 8;
                for (int i = 0; i < 8; i++) begin
                    if (poss_moves[move_num][i]) begin
                        logic [3:0] degree;
                        degree = calculate_degree(xx + dx[i], yy + dy[i]);
                        if (degree <= min_degree) begin
                            min_degree = degree;
                            nxt_xx = xx + dx[i];
                            nxt_yy = yy + dy[i];
                        end
                    end
                end
                next_state = UPDATE_POS;
            end

            UPDATE_POS: begin
                // Update the board and position
                last_move[move_num] = (1 << (nxt_xx * 5 + nxt_yy));
                update_position = 1'b1;
                move_num = move_num + 1;
                if (move_num == 24) begin
                    next_state = COMPLETE;
                end else begin
                    next_state = CALC_MOVES;
                end
            end

            COMPLETE: begin
                done = 1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output the move for the given index
    assign move = last_move[indx];

endmodule