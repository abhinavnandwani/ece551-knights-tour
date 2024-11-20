module tour_logic(clk, rst_n, x_start, y_start, go, done, indx, move);
  // Declare input and output signals
  input logic clk, rst_n, go;
  input logic [2:0] x_start, y_start;
  input logic [4:0] indx;
  output logic done;
  output logic [7:0] move;
  
  // Declare internal logic 
  typedef enum {CALCULATE} state_t;
  state_t state, nxt_state;
  logic [4:0] where_been [2:0][2:0]; // Array of positions the knight has been to
  logic [7:0] chosen_moves [4:0]; // 24 wide array of the chosen moves in a one-hot 8-bit vector
  logic [7:0] practical_moves [4:0]; // Moves that are both possible and actually may work
  logic [7:0] possible_moves [4:0]; // 24 wide array of all possible moves stored in 8-bit vector
  logic [4:0] curr_move;
  logic [2:0] x_pos, y_pos;
  logic curr_move_inc;
  
  assign where_been[x_start][y_start] = 5'h00;
  assign move = chosen_moves[indx];
  
  // Increment curr_move sometimes
  always_ff@(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
	  curr_move <= 5'h00;
	else if (curr_move_inc)
	  curr_move <= curr_move + 1;
  end
  
  // Create state_machine simple math
  always_ff(@posedge clk, negedge rst_n) begin
    if (!rst_n) 
	  state <= ZERO;
	else 
	  state <= nxt_state;
  end
  
  always_comb begin
	x_pos = 3'd0;
	y_pos = 3'd0;
	curr_move_inc = 0;
	case (possible_moves[currmove]) inside
	  8'bxxxxxxx1:
	  8'bxxxxxx10:
	  8'bxxxxx100:
	  8'bxxxx1000:
	  8'bxxx10000:
	  8'bxx100000:
	  8'bx1000000:
	  8'b10000000:
	  default:
	endcase
  end
  
  // Assign the correct possible moves value (this does not take into account past moves for determining legal moves
  always_comb begin
    if (x_pos > 3'd2) begin
      possible_moves[curr_move][0] = 0;
      possible_moves[curr_move][1] = 0;
	  possible_moves[curr_move][4] = 1;
      possible_moves[curr_move][5] = 1;
    end 
    else if (x_pos < 3'd2) begin 
      possible_moves[curr_move][0] = 1;
      possible_moves[curr_move][1] = 1;
	  possible_moves[curr_move][4] = 0;
      possible_moves[curr_move][5] = 0;
    end
    else begin
      possible_moves[curr_move][0] = 1;
      possible_moves[curr_move][1] = 1;
	  possible_moves[curr_move][4] = 1;
      possible_moves[curr_move][5] = 1;
    end
  
    if (y_pos > 3'd2) begin
      possible_moves[curr_move][6] = 0;
      possible_moves[curr_move][7] = 0;
	  possible_moves[curr_move][2] = 1;
      possible_moves[curr_move][3] = 1;
    end 
    else if (y_pos < 3'd2) begin 
      possible_moves[curr_move][6] = 1;
      possible_moves[curr_move][7] = 1;
	  possible_moves[curr_move][2] = 0;
      possible_moves[curr_move][3] = 0;
    end
    else begin
      possible_moves[curr_move][6] = 1;
      possible_moves[curr_move][7] = 1;
	  possible_moves[curr_move][2] = 1;
      possible_moves[curr_move][3] = 1;
    end
  end
  
endmodule