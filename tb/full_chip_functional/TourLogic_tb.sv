`timescale 1ns/1ps
module TourLogic_tb();

  // Testbench Signals
  reg clk, rst_n, go;
  wire done;

  // Parameters for Board Dimensions (for adaptability)
  localparam BOARD_WIDTH = 5;
  localparam BOARD_HEIGHT = 5;
  // Start Coordinates
  reg [2:0] x_start, y_start;

  ////////////////////////
  // Instantiate DUT    //
  ////////////////////////
  TourLogic iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .x_start(x_start),
    .y_start(y_start),
    .go(go),
    .done(done),
    .indx(5'h00),
    .move()
  );

  // Clock Generation
  always #5 clk = ~clk;



  // Define Black Square Coordinates (Vector of Pairs)
  localparam int NUM_BLACK_SQUARES = 13; // Adjust based on the board size
  reg [2:0] black_squares[0:NUM_BLACK_SQUARES-1][1:0];

  assign black_squares = '{
    '{0, 0}, '{0, 2}, '{0, 4}, '{1, 1}, '{1, 3}, 
    '{2, 0}, '{2, 2}, '{2, 4}, '{3, 1}, '{3, 3}, 
    '{4, 0}, '{4, 2}, '{4,4}
  };

  integer i; // Loop variable

  initial begin
    // Initialization
    clk = 0;
    rst_n = 0;
    go = 0;

    // Reset Sequence
    @(negedge clk);


    // Iterate through all black squares
    for (i = 0; i < NUM_BLACK_SQUARES; i = i + 1) begin
	  @(negedge clk)
	  	rst_n = 1'b1;
      x_start = black_squares[i][0];
      y_start = black_squares[i][1];

      // Start Test for Black Square
      @(negedge clk);
      go = 1;
      @(negedge clk);
      go = 0;

      // Wait for completion or timeout
      fork
        begin: timeout
          repeat(80000000) @(negedge clk);
          $display("ERROR: Simulation timed out at x=%d, y=%d.", x_start, y_start);
          display_board();
          $stop();
        end
        begin
          @(posedge done);
          disable timeout;
        end
      join

      // Display Completion Message
      $display("SUCCESS: Solution found starting at x=%d, y=%d.", x_start, y_start);
	  rst_n = 1'b0;
      display_board();
    end

    $display("INFO: Testbench completed for all black squares.");
    $stop();
  end

  // Task to Display Board State
  task display_board;
    integer x, y;
    begin
      for (y = BOARD_HEIGHT - 1; y >= 0; y = y - 1) begin
        for (x = 0; x < BOARD_WIDTH; x = x + 1) begin
          $write("%2d  ", iDUT.board[x][y]);
        end
        $write("\n");
      end
      $display("--------------------\n");
    end
  endtask

  // //Debug Board State at Every Update
  // always @(posedge iDUT.update_position) begin
  //   $display("DEBUG: Board state updated");
  //   display_board();
  // end

endmodule