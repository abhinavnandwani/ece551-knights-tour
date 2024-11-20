module tour_logic(clk, rst_n, x_start, y_start, go, done, indx, move);
  // Declare input and output signals
  input logic clk, rst_n, go;
  input logic [2:0] x_start, y_start;
  input logic [4:0] indx;
  output logic done;
  output logic [7:0] move;
  
  // Declare internal logic 
  typedef enum {} state_t;
  state_t state, nxt_state;
  logic [4:0] where_been [2:0][2:0]; // Array of positions the knight has been to
  logic [7:0] id_array [4:0]; // 24 wide array of the chosen moves in a one-hot 8-bit vector
  logic [7:0] possible_moves [4:0]; // 24 wide array of all possible moves stored in 8-bit vector
  
endmodule