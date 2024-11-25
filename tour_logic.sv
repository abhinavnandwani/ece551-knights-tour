module TourLogic(
  input logic clk, rst_n, go,               // Clock, reset, and start signal inputs
  input logic [2:0] x_start, y_start,      // Starting x and y coordinates
  input logic [4:0] indx,                  // Index to track the moves
  output logic done,                       // Signal indicating the knight's tour is complete
  output logic [7:0] move                  // Output representing the current move in a one-hot vector
);

  // Internal logic declarations
  logic [7:0] state, next_state;                  // Current and next states for the state machine
  logic [4:0] board [4:0][4:0];                   // 5x5 board to track visited positions
  logic signed [7:0] chosen_moves [23:0];         // Array to store the chosen moves in a one-hot encoding
  logic [5:0] x_y_order [23:0];                   // Array to track the order of x, y positions visited

  logic [7:0] curr_move;                          // Current move index
  logic signed [3:0] x_pos, y_pos;                // Current x and y positions
  logic signed [3:0] x_new, y_new;                // Updated x and y positions after a move
  logic [1:0] curr_move_move;                     // Control signal to advance or backtrack moves

  logic update_position;                          // Signal to indicate position update

  // Function to check if a move is valid
  function is_valid_move;
    input signed [3:0] x;                         // Current x-coordinate
    input signed [3:0] y;                         // Current y-coordinate
    input signed [3:0] new_x;                     // New x-coordinate after the move
    input signed [3:0] new_y;                     // New y-coordinate after the move

    // Logic to validate the move
    begin
      if (new_x >= 4'd0 && new_x < 4'd5 &&        // Check if new_x is within board bounds
          new_y >= 4'd0 && new_y < 4'd5 &&        // Check if new_y is within board bounds
          board[new_x][new_y] == 0) begin         // Ensure the position is not already visited
        is_valid_move = 1'b1;                     // Valid move
      end else begin
        is_valid_move = 1'b0;                     // Invalid move
      end
    end
  endfunction

  // Sequential block for updating stateful variables
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all variables
      x_pos <= x_start;                           // Set starting x position
      y_pos <= y_start;                           // Set starting y position
      curr_move <= 5'h01;                         // Initialize move index
      for (int i = 0; i < 5; i++) begin
        for (int j = 0; j < 5; j++) begin
          board[i][j] <= 5'b0;
        end
      end
      for (int i = 0; i < 24; i++) begin
        chosen_moves[i] <= 8'sd0; // Use '8'sd0' for signed values
      end
      board[x_start][y_start] <= 5'b1;            // Mark the starting position as visited
      x_y_order[0] <= {x_start, y_start};         // Store the starting position
      chosen_moves[curr_move] <= move;
    end else begin
      // Update current position and order arrays
      x_pos <= x_new;                             // Update x position
      y_pos <= y_new;                             // Update y position
      x_y_order[curr_move] <= {x_new[2:0], y_new[2:0]}; // Store the updated position
      chosen_moves[curr_move] <= move;
      if (curr_move_move[0]) begin               // On successful move
        board[x_new][y_new] <= curr_move;         // Mark the new position as visited
        curr_move <= curr_move + 1;               // Increment the move index
      end else if (curr_move_move[1]) begin       // On backtracking
        curr_move <= curr_move - 1;               // Decrement the move index
        board[x_new][y_new] <= '0;                // Clear the board position
      end
    end
  end

  // Sequential block for state machine logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      state <= 8'b00000001;                       // Reset to the initial state
    else 
      state <= next_state;                        // Move to the next state
  end

  // Combinational block for state transitions
  always_comb begin
    curr_move_move = 2'h0;                        // Default no move
    next_state = state;                           // Default to current state
    x_new = x_pos;                                // Default new position
    y_new = y_pos;
    done = 1'b0;                                  // Default tour not done
    update_position = 1'b0;                       // Default no position update
    move = state;

    casex (state)
      8'bxxxxxxx1: begin                 // (2,1)
        if (is_valid_move(x_pos, y_pos, x_pos + 2, y_pos + 1)) begin
          // Logic for handling the move (2, 1)
          x_new = x_pos + 2;
          y_new = y_pos + 1;
          curr_move_move = 2'b01;
          next_state = 8'b00000001;  // Shift the state to the next move
          update_position = 1'b1;
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
          update_position = 1'b1;
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
          update_position = 1'b1;
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
          update_position = 1'b1;
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
          update_position = 1'b1;
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
          update_position = 1'b1;
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
          update_position = 1'b1;
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
          update_position = 1'b1;
        end else begin
          // No valid move, backtrack (shift state left)
          next_state = state << 1;
        end
      end
      default: begin
        // Default case for backtracking if no valid move was found
        // Reset the state and try the previous move
        if (curr_move == 8'd24) begin
          done = 1'b1;
        end else begin
          next_state = chosen_moves[curr_move-1] << 1;
          x_new = {1'b0, x_y_order[curr_move-1][5:3]};
          y_new = {1'b0, x_y_order[curr_move-1][2:0]};
          curr_move_move = 2'b10;
        end
      end
    endcase
  end
endmodule
