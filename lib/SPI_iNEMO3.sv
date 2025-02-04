module SPI_iNEMO3(SS_n,SCLK,MISO,MOSI,INT);
  /////////////////////////////////////////////////////////
  // Model of a ST iNEMO 6-axis inertial device         //
  // Inertial data comes from readmemh of inertial.txt //
  //////////////////////////////////////////////////////

  input SS_n;				// active low serf select
  input SCLK;				// Serial clock
  input MOSI;				// serial data in from monarch
  output MISO;				// serial data out to monarch
  output reg INT;			// interrupt output
  
  /// Define states of SPI serf SM ///
  typedef enum reg[1:0] {IDLE,ADDR,DATA} state_t;
  ///////////////////////////////////////////////
  // Registers needed in design declared next //
  /////////////////////////////////////////////
  state_t state,nstate;
  reg [15:0] shft_reg_tx;	// SPI shift register for transmitted data (falling edge)
  reg [15:0] shft_reg_rx;	// SPI shift register for received data (rising edge)
  reg [3:0] bit_cnt;		// Needed to know when to interpret R/Wn and address for tx_data
  reg write_reg;			// Used as sentinel to mark that command is write, so write is 
                            // completed at end of transaction
  reg POR_n;				// Power On Reset active low
  
  /////////////////////////////////////////////
  // Array memory for storing inertial data //
  ///////////////////////////////////////////
  // 95:80 = AX (acceleration X)
  // 79:64 = AY (acceleration Y)
  // 63:48 = AZ (acceleration Z)
  // 47:32 = pitch rate
  // 31:16 = roll rate
  // 15:0 = yaw rate
  //////////////////////////////////////////
  reg [95:0]inert_data[0:255];	// 256 entries of inertial data
  reg [7:0] inert_ptr;			// indx into inert_data

  //////// Need array to hold all possible registers of iNEMO ////////
  reg [7:0]registers[0:127];
  reg internal_clk;				// 12.5MHz
  reg [11:0]update_period;		// around 3kHz
  reg clr_INT;
  
  /////////////////////////////////////////////
  // SM outputs declared as type logic next //
  ///////////////////////////////////////////
  logic ld_tx_reg, shft_tx, init;
  logic set_write,clr_write;
  logic [7:0] tx_data;
  
  wire NEMO_setup;		// once INT register setup it will start the measurement cycle of inertial sensor									// triggers when all ESC's have had neg edge
  
  //// Infer main SPI shift register ////
  always_ff @(negedge SCLK, negedge POR_n)
    if (!POR_n)
	  shft_reg_tx <= 16'h0000;
	else if (init)
	  shft_reg_tx <= 16'h0000;
	else if (ld_tx_reg)						// occurs at beginning and middle of 16-bit transaction
	  shft_reg_tx <= {tx_data,8'h00};
	else if (shft_tx)
	  shft_reg_tx <= {shft_reg_tx[14:0],1'b0};

  //// Infer main SPI shift register ////
  always_ff @(posedge SCLK, negedge POR_n)
    if (!POR_n)
	  shft_reg_rx <= 16'h0000;
	else if (!SS_n)
	  shft_reg_rx <= {shft_reg_rx[14:0],MOSI};
	  
  always_ff @(posedge SCLK)
    if (init)
	  bit_cnt <= 4'b0000;
	else
	  bit_cnt <= bit_cnt + 1;
	  
  always_ff @(negedge SCLK, negedge POR_n)
    if (!POR_n)
	  write_reg <= 1'b0;
	else if (set_write)
	  write_reg <= 1'b1;
	else if (write_reg)		// can only be high for one SCLK period
	  write_reg <= 1'b0;
	 
  ///////////////////////////////////////////////////
  // At end of SPI transaction, if it was a write //
  // the register being written is updated       //
  ////////////////////////////////////////////////
  always_ff @(posedge SS_n)
    if (write_reg)
      registers[shft_reg_rx[14:8]] <= shft_reg_rx[7:0];
	
  //////////////////////////////////////////////////
  // model update_period for ODR of inert sensor //
  ////////////////////////////////////////////////
  always_ff @(posedge internal_clk, negedge POR_n)
    if (!POR_n)
	  update_period <= 13'h0000;
	else if (NEMO_setup)
	  update_period <= update_period + 1;
	
  ///////////////////////////
  // Interrupt flag logic //
  /////////////////////////  
  always_ff @(posedge internal_clk, negedge POR_n)
    if (!POR_n)
	  INT <= 1'b0;
	else if (clr_INT)
	  INT <= 1'b0;
	else if (&update_period)
	  INT <= 1'b1;
	  
  ////////////////////////////////////////////////////
  // inert_ptr (index into which inert_data entry) //
  //////////////////////////////////////////////////
  always_ff @(posedge internal_clk, negedge POR_n)
    if (!POR_n)
	  ////////////////////////////////////////////////
	  // start it at 0xFF so it rolls over on      //
	  // first INT and gives data from location 0 //
	  /////////////////////////////////////////////
	  inert_ptr <= 8'hFF;
	else if (&update_period)
	  inert_ptr <= inert_ptr+1;	  
	
  //// Infer state register next ////
  always @(posedge SCLK, negedge POR_n)
    if (!POR_n)
	  state <= IDLE;
	else
	  state <= nstate;

  ///////////////////////////////////////
  // Implement state transition logic //
  /////////////////////////////////////
  always_comb
    begin
      //////////////////////
      // Default outputs //
      ////////////////////
	  ld_tx_reg = 0;
      shft_tx = 0;
      init = 0;
	  tx_data = 16'h0000;
	  set_write = 0;
      nstate = IDLE;	  

      case (state)
        IDLE : begin
          if (!SS_n) begin
		    init = 1;
            nstate = ADDR;
          end
        end
		ADDR : begin
		  shft_tx = 1;
		  if (bit_cnt==4'b0111) begin
		    ld_tx_reg = 1;
			tx_data = response(shft_reg_rx[7:0]);		// response if function of first 8-bits received
		    nstate = DATA;
	      end else
		    nstate = ADDR;
		end
		DATA : begin
		  shft_tx = 1;
          clr_INT = 0;		  
		  if (bit_cnt==4'b1110) begin
		    set_write = ~shft_reg_rx[14];				// if it is a write set the write sentinel
		    nstate = IDLE;
		  end else
		    nstate = DATA;
		end
      endcase
    end
	

  ///// MISO is shift_reg[15] with a tri-state ///////////
  assign MISO = (SS_n) ? 1'bz : shft_reg_tx[15];

  initial begin
    POR_n = 0;
	internal_clk = 0;
	$readmemh("inert_data3.hex",inert_data);
	/// This version of SPI_iNEMO takes a while before it is ready ///
	repeat(4096) @(negedge internal_clk);
	POR_n = 1;
  end
  
  always
    #40 internal_clk = ~internal_clk;	// generate 12.5MHz internal clock
  
  function [7:0] response (input [7:0] in_byte);
    if (in_byte[7])	begin		// if it is a read respond with requested register
	  case (in_byte[6:0])
	    7'h22 : begin response = inert_data[inert_ptr][39:32]; clr_INT=1; end
		7'h23 : begin response = inert_data[inert_ptr][47:40]; clr_INT=0; end
	    7'h24 : begin response = inert_data[inert_ptr][23:16]; clr_INT=0; end
		7'h25 : begin response = inert_data[inert_ptr][31:24]; clr_INT=0; end
	    7'h26 : begin response = inert_data[inert_ptr][7:0]; clr_INT=0; end
		7'h27 : begin response = inert_data[inert_ptr][15:8]; clr_INT=0; end
	    7'h28 : begin response = inert_data[inert_ptr][87:80]; clr_INT=0; end
		7'h29 : begin response = inert_data[inert_ptr][95:88]; clr_INT=0; end
	    7'h2A : begin response = inert_data[inert_ptr][71:64]; clr_INT=0; end
		7'h2B : begin response = inert_data[inert_ptr][79:72]; clr_INT=0; end
	    7'h2C : begin response = inert_data[inert_ptr][55:48]; clr_INT=0; end
		7'h2D : begin response = inert_data[inert_ptr][63:56]; clr_INT=0; end
		7'h0F : begin response = 8'h6A; clr_INT=0; end
	    default : begin response = registers[in_byte[6:0]]; clr_INT=0; end	// case it is just a generic register
	  endcase
	end else					// it is a write
	  response = 8'hA5;			// respond with 0xA5
  endfunction
  
  /// This version of SPI_iNEMO is more picky about what registers need to be setup before asserteing NEMO_setup ///
  assign NEMO_setup = ((registers[7'h0d]==8'h02) && (registers[7'h11]==8'h60))? 1'b1 : 1'b0;
  
endmodule  
  