module TourCmd(
   input clk, rst_n,            // 50MHz clock and async active low reset
   input start_tour,            // Start signal from TourLogic
   input [7:0] move,            // Encoded 1-hot move to perform
   output logic [4:0] mv_indx,    // Address for the next move
   input [15:0] cmd_UART,       // Command from UART_wrapper
   input cmd_rdy_UART,          // Ready signal from UART_wrapper
   output logic [15:0] cmd,           // Command to cmd_proc
   output logic cmd_rdy,              // Ready signal to cmd_proc
   input clr_cmd_rdy,           // Clear signal from cmd_proc
   input send_resp,             // Indicates cmd_proc has processed the move
   output logic [7:0] resp            // Response: 0xA5 (done) or 0x5A (in progress)
);

   // Signals to control mv_indx
   logic inc_mv_indx;          // Increment mv_indx when cmd_proc completes
   logic clr_mv_indx;          // Clear mv_indx when start_tour is asserted
   logic [4:0] nxt_mv_indx;

   // Update mv_indx: Clear, increment, or hold value
    //Need to add a flop because we only want it to increment once in the current clock cycle
    always_ff @(posedge clk) begin
        unique if (clr_mv_indx)
            mv_indx <= 4'b0000;
        else 
            mv_indx <= mv_indx + inc_mv_indx;
    end

   // Generate response based on mv_indx
   assign resp = ((mv_indx == 5'd23) | send_resp) ? 8'hA5 : 8'h5A; // Response logic

   // Decode move to generate encoded_cmd
   logic [31:0] encoded_cmd;
   always_comb begin
       encoded_cmd = 0;
       unique case (move)
           8'b0000_0001 : encoded_cmd = {16'h4002,16'h5BF1}; // Move 0
           8'b0000_0010 : encoded_cmd = {16'h4002,16'h53F1}; // Move 1
           8'b0000_0100 : encoded_cmd = {16'h4001,16'h53F2}; // Move 2
           8'b0000_1000 : encoded_cmd = {16'h47F1,16'h53F2}; // Move 3
           8'b0001_0000 : encoded_cmd = {16'h47F2,16'h53F1}; // Move 4
           8'b0010_0000 : encoded_cmd = {16'h47F2,16'h5BF1}; // Move 5
           8'b0100_0000 : encoded_cmd = {16'h47F2,16'h5BF2}; // Move 6
           8'b1000_0000 : encoded_cmd = {16'h4001,16'h5BF2}; // Move 7
           8'b1111_1111 : encoded_cmd = {16'hFFFF, 16'hFFFF}; //Idle
       endcase
   end

   // Mux logic for cmd and cmd_rdy
   logic en_cmd_mux;           // Control source selection for cmd and cmd_rdy
   logic cmd_rdy_SM;           // Ready signal from FSM
   logic [15:0] cmd_SM;               // Command signal from FSM

   assign cmd_rdy = en_cmd_mux ? cmd_rdy_SM : cmd_rdy_UART;
   assign cmd = en_cmd_mux ? cmd_SM : cmd_UART;

   // FSM for controlling the TourCmd process
   typedef enum reg [2:0] {IDLE, VERTICAL, WAIT_1, HORIZONTAL, WAIT_2} state_t;
   state_t state, nxt_state;

   // State transition logic
   always_ff @(posedge clk or negedge rst_n) begin
       unique if (!rst_n)
           state <= IDLE;
       else 
           state <= nxt_state;
   end

   // FSM next state and control signal generation
   always_comb begin
       nxt_state = state;
       clr_mv_indx = 0;
       en_cmd_mux = 0;
       cmd_rdy_SM = 0;
       cmd_SM = 16'h0000;
       inc_mv_indx = 0;

       case (state)
           VERTICAL: begin
               en_cmd_mux = 1'b1;
               cmd_rdy_SM = 1'b1;
               cmd_SM = encoded_cmd[31:16];
               if (clr_cmd_rdy) nxt_state = WAIT_1;
           end
           WAIT_1: begin
               en_cmd_mux = 1'b1;
               cmd_SM = encoded_cmd[31:16];
               if (send_resp) nxt_state = HORIZONTAL;
           end
           HORIZONTAL: begin
               en_cmd_mux = 1'b1;
               cmd_rdy_SM = 1'b1;
               cmd_SM = encoded_cmd[15:0];
               if (clr_cmd_rdy) nxt_state = WAIT_2;
           end
           WAIT_2: begin
               en_cmd_mux = 1'b1;
               cmd_SM = encoded_cmd[15:0];
               if (send_resp) begin
                   if (mv_indx !== 5'd23) begin
                       inc_mv_indx = 1'b1;
                       nxt_state = VERTICAL;
                   end else
                       nxt_state = IDLE;
               end
           end
           default: begin
               nxt_state = IDLE;
                clr_mv_indx = 1'b1;
               if (start_tour) begin
                   nxt_state = VERTICAL;
               end
           end
       endcase
   end

endmodule
