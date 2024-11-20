module TourCmd(clk,rst_n,start_tour,move,mv_indx,
               cmd_UART,cmd,cmd_rdy_UART,cmd_rdy,
			   clr_cmd_rdy,send_resp,resp);

   input clk,rst_n;			// 50MHz clock and asynch active low reset
   input start_tour;			// from done signal from TourLogic
   input [7:0] move;			// encoded 1-hot move to perform
   output reg [4:0] mv_indx;	// "address" to access next move
   input [15:0] cmd_UART;	// cmd from UART_wrapper
   input cmd_rdy_UART;		// cmd_rdy from UART_wrapper
   output [15:0] cmd;		// multiplexed cmd to cmd_proc
   output cmd_rdy;			// cmd_rdy signal to cmd_proc
   input clr_cmd_rdy;		// from cmd_proc (goes to UART_wrapper too)
   input send_resp;			// lets us know cmd_proc is done with the move command
   output [7:0] resp;		// either 0xA5 (done) or 0x5A (in progress)


   // case for all possible X and Y //
   logic [31:0] encoded_cmd;
   always_comb begin
      encoded_cmd = 0;

      // 00 - north 
      // 7f - south 
      // bf - east 
      // 3f - west
      case(move)
      8'b0000_0001 : encoded_cmd = {16'h4002,16'h5bf1}; //0
      8'h0000_0010 : encoded_cmd = {16'h4002,16'h53f1}; //1
      8'h0000_0100 : encoded_cmd = {16'h4001,16'h53f2}; //2
      8'h0000_1000 : encoded_cmd = {16'h47f1,16'h53f2}; //3
      8'h0001_0000 : encoded_cmd = {16'h47f2,16'h53f1}; //4
      8'h0010_0000 : encoded_cmd = {16'h47f2,16'h5bf1}; //5
      8'h0100_0000 : encoded_cmd = {16'h47f2,16'h5bf2}; //6
      8'h1000_0000 : encoded_cmd = {16'h4001,16'h5bf2}; //7
      endcase
   end

   //// FSM for TourCmd ////
   typedef enum reg [2:0] {IDLE, } state_t;
   state_t state, nxt_state;

   // state flop //
   always_ff@(posedge clk, negedge rst_n)

      


  
endmodule