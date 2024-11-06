

module SPI_mnrch(
  input clk,
  input rst_n,
  input snd, 
  input [15:0] cmd,
  output logic done, 
  output [15:0] resp,
  output logic SS_n,
  output SCLK,
  output MOSI,
  input MISO  
);

  typedef enum { IDLE, TRANSMIT } state_t;
  state_t next_state, state;

  logic [15:0] shft_reg;
  logic [4:0] bit_cnt;
  logic [4:0] SCLK_div;
  logic full;
  logic shft;
  logic set_done;
  logic done16;
  logic init;
  logic ld_SCLK;
  
  // COUNTER
  assign done16 = bit_cnt == 5'b10000;
  always_ff @(posedge clk)
    bit_cnt <= init ? '0 : shft ? bit_cnt+1 : bit_cnt;

  // SHIFT FLAG
  assign SCLK = SCLK_div[4];
  assign full = 5'b11111 === SCLK_div;
  assign shft = 5'b10001 === SCLK_div;

  always_ff @(posedge clk)
    if (ld_SCLK)  
      SCLK_div <= 5'b10111;
    else
      SCLK_div <= SCLK_div + 1;

  // SHIFT REGISTER
  assign MOSI = shft_reg[15];
  always_ff @(posedge clk)
    if (init)
      shft_reg <= cmd;
    else if (shft)
      shft_reg <= { shft_reg[14:0] , MISO };
    
  // DONE OUTPUT
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      done <= 0;
    else if (init)
      done <= 0;
    else if (set_done)
      done <= 1;

  // SS_n OUTPUT
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      SS_n <= 1;
    else if (set_done)
      SS_n <= 1;
    else if (init) 
      SS_n <= 0;

  // STATE MACHINE
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;

  // COMB
  always_comb begin
    // DEFAULT OUTPUTS
    ld_SCLK = 1;
    init = 0;
    set_done = 0;
    next_state = state;
    case (state)
      IDLE: if (snd) begin
        init = 1;
        next_state = TRANSMIT;
      end
      TRANSMIT: begin
        ld_SCLK = 0;
        if (done16) begin
          set_done = 1;
          next_state = IDLE;
        end
      end
    endcase
  end
  
  assign resp = shft_reg;

endmodule