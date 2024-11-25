module TourLogic(
  input logic clk, rst_n, go,
  input logic [2:0] x_start, y_start,
  input logic [4:0] indx,
  output logic done,
  output logic [7:0] move
);

  // Declare internal logic
  logic [7:0] state, next_state;
  logic [4:0] visited [4:0][4:0]; // Array of positions the knight has been to (5x5 board)
  logic signed [7:0] chosen_moves [24:0]; // Array of chosen moves in a one-hot 8-bit vector
  logic [5:0] x_y_order [24:0];

  logic [7:0] curr_move;
  logic signed [3:0] x_pos, y_pos;
  logic signed [3:0] x_new, y_new;
  logic [1:0] curr_move_move;

  // Function to check if a move is valid
  function is_valid_move;
    input signed [3:0] x;         // Current x-coordinate
    input signed [3:0] y;         // Current y-coordinate
    input signed [3:0] new_x;     // New x-coordinate after the move
    input signed [3:0] new_y;     // New y-coordinate after the move

    // Check if the new position is within bounds of the board
    begin
      if (new_x >= 4'd0 && new_x < 4'd5 && new_y >= 4'd0 && new_y < 4'd5 && visited[new_x][new_y] == 0) begin
        is_valid_move = 1'b1;       // Valid move
      end else begin
        is_valid_move = 1'b0;       // Invalid move
      end
    end
  endfunction

  // Move all updates to stateful variables into a sequential block
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x_pos <= x_start;
      y_pos <= y_start;
      curr_move <= 5'h01;
      visited <= '{default: '{default: 5'b0}}; // Clear visited array
      visited[x_start][y_start] <= 5'b1;
      x_y_order[0] <= {x_start, y_start};
    end else begin
      if (curr_move_move[0]) begin
        curr_move <= curr_move + 1;
        x_pos <= x_new;
        y_pos <= y_new;
        visited[x_new][y_new] <= curr_move;
        x_y_order[curr_move] <= {x_new[2:0], y_new[2:0]};
      end else if (curr_move_move[1]) begin
        curr_move <= curr_move - 1;
      end
    end
  end

  // Create state machine logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      state <= 8'b00000001;
    else 
      state <= next_state;
  end

  always_comb begin
    curr_move_move = 2'h0;
    next_state = state;
    x_new = x_pos;
    y_new = y_pos;

    casex (state)
      8'bxxxxxxx1: begin                 // (2,1)
        if (is_valid_move(x_pos, y_pos, x_pos + 2, y_pos + 1)) begin
          // Logic for handling the move (2, 1)
          x_new = x_pos + 2;
          y_new = y_pos + 1;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b00000001;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'bxxxxxx10: begin                 // (1,2)
        if (is_valid_move(x_pos, y_pos, x_pos + 1, y_pos + 2)) begin
          // Logic for handling the move (1, 2)
          x_new = x_pos + 1;
          y_new = y_pos + 2;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b00000010;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'bxxxxx100: begin                 // (-1,2)
        if (is_valid_move(x_pos, y_pos, x_pos - 1, y_pos + 2)) begin
          // Logic for handling the move (-1, 2)
          x_new = x_pos - 1;
          y_new = y_pos + 2;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b00000100;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'bxxxx1000: begin                 // (-2,1)
        if (is_valid_move(x_pos, y_pos, x_pos - 2, y_pos + 1)) begin
          // Logic for handling the move (-2, 1)
          x_new = x_pos - 2;
          y_new = y_pos + 1;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b00001000;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'bxxx10000: begin                 // (-2,-1)
        if (is_valid_move(x_pos, y_pos, x_pos - 2, y_pos - 1)) begin
          // Logic for handling the move (-2, -1)
          x_new = x_pos - 2;
          y_new = y_pos - 1;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b00010000;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'bxx100000: begin                 // (-1,-2)
        if (is_valid_move(x_pos, y_pos, x_pos - 1, y_pos - 2)) begin
          // Logic for handling the move (-1, -2)
          x_new = x_pos - 1;
          y_new = y_pos - 2;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b00100000;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'bx1000000: begin                 // (1,-2)
        if (is_valid_move(x_pos, y_pos, x_pos + 1, y_pos - 2)) begin
          // Logic for handling the move (1, -2)
          x_new = x_pos + 1;
          y_new = y_pos - 2;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b01000000;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      8'b10000000: begin                 // (2,-1)
        if (is_valid_move(x_pos, y_pos, x_pos + 2, y_pos - 1)) begin
          // Logic for handling the move (2, -1)
          x_new = x_pos + 2;
          y_new = y_pos - 1;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          chosen_moves[curr_move] = 8'b10000000;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      default: begin
        // Default case for backtracking if no valid move was found
        // Reset the state and try the previous move
        next_state = chosen_moves[curr_move-1];
        x_new = {1'b0, x_y_order[curr_move-1][5:3]};
        y_new = {1'b0, x_y_order[curr_move-1][2:0]};
        curr_move_move = 2'b10;
      end
    endcase
  end
endmodule
