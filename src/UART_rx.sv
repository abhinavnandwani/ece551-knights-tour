/* 
    Author          : Abhinav Nandwani
    Filename        : UART_rx.sv
    Description     : 
*/

`default_nettype none
module UART_rx(clk,rst_n,RX,rx_data,clr_rdy,rdy);

    input logic clk, rst_n;
    input logic RX, clr_rdy;
    output logic [7:0] rx_data;
    output reg rdy;


    logic [3:0] bit_cnt;
    logic [8:0] rx_shift_reg;
    logic [11:0] baud_cnt,baud_value;
    logic receiving,start,shift,set_rdy;



  //// RX is async to clk, double flopping ////
  logic RX_ff,RX_2ff,RX_3ff;
  always_ff@(posedge clk, negedge rst_n)
    if (!rst_n)
      {RX_ff,RX_2ff,RX_3ff} <= 3'b111; //async preset 
    else
      {RX_ff,RX_2ff,RX_3ff} <= {RX,RX_ff,RX_2ff}; // chain the flops, creating 2 clk delay
  


    // BIT COUNTER
    always_ff@(posedge clk)
        if (start)
            bit_cnt <= 0;
        else if (shift)
            bit_cnt <= bit_cnt +1'b1;

    assign baud_value = start ? 1302:2604;
    assign shift = (baud_cnt == 0) ? 1'b1:1'b0;
    // BAUD COUNTER
    always_ff@(posedge clk)
        if (start | shift)
            baud_cnt <= baud_value;
        else if (receiving)
            baud_cnt <= baud_cnt - 1'b1;
    
    // SHIFTER
    always_ff@(posedge clk)
        if (shift)
            rx_shift_reg <= {RX_2ff,rx_shift_reg[8:1]};
    


    

    assign rx_data = rx_shift_reg[7:0];


    //// FSM for control unit ////
    typedef enum reg[1:0]{IDLE,RECEIVING} state_t;
    state_t state, nxt_state;

    // state flop in always_ff with non blocking //
    always_ff@(posedge clk, negedge rst_n)
      if(!rst_n)
        state <= IDLE;
      else 
        state <= nxt_state;
    
    // next state and output logic with always_comb //
    always_comb begin
      
      // default outputs //
      start = 0;
      receiving = 0;
      set_rdy = 0;

      // state transition and output logic //
      case (state) inside
        RECEIVING :  if(bit_cnt == 10) begin
                        set_rdy = 1;
                        nxt_state = IDLE;
                      end else receiving = 1;
        // default case: IDLE //
        default:      if (RX_3ff && !RX_2ff) begin
                      start = 1;
                      nxt_state = RECEIVING;
                    end 
      endcase
    end

    // SR flop for rdy //
    always_ff@(posedge clk, negedge rst_n) begin
      if(!rst_n)
        rdy <= 0;
      else if(start || clr_rdy)
        rdy <= 0;
      else if(set_rdy)
        rdy <= 1'b1;

    end

            
endmodule
`default_nettype wire
            
