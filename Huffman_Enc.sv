// You MUST NOT change the module name or the ports declarations
`timescale 1ns / 1ps
module Huffman_Enc #(
    parameter CHAR_SPACE = 5,
    parameter CODE_LEN = 4,
    parameter CHAR_LEN = 3,
    parameter CODE_LEN_LEN = 3
)(
    input clk,
    input rst_n,
    input start,
    input [CHAR_LEN-1:0] text_msg,
    input [CHAR_SPACE-1:0][CODE_LEN-1:0] huffman_lib,
    input [CHAR_SPACE-1:0][CODE_LEN_LEN-1:0] huffman_len,

    output reg wr_en,
    output reg out_bit,
    output reg idle
);
    // These declarations are provided as hints for a possible implementation.
    // You are free to modify, add, or remove them as long as the module's
    // external behavior is correct

    reg[CODE_LEN_LEN-1:0] read_pointer;
    reg[CODE_LEN-1:0] load;

    
    localparam  INIT = 0,
                SEND = 1;

    // ----------- Insert your codes below --------------//
  
  
integer i;
reg state,next_state;

  
  always @(*) begin
    if (!rst_n)
      next_state = INIT;
    
    else begin
            case (state)
              INIT: next_state = start ? SEND : INIT;    
              SEND: next_state = (idle==1) ? INIT : SEND;
                default: next_state = INIT;
            endcase
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= INIT;
    
    else begin
      state <= next_state;
    end
  end
  
      
      always @(*) begin
        case(state) 
            INIT: begin//Initializations
                wr_en = 0;
                idle = 1;
                out_bit = 0;
                i = 0;
            end            
            SEND: begin//Code output wrt character
                out_bit = huffman_lib[text_msg][i]; 
                idle = 1'b0;
              		if (i == huffman_len[text_msg]) begin
                    	wr_en = 1'b0;
                    	idle = 1'b1;
                  		out_bit = 0;
                	end  
                	else begin
                    	wr_en = 1'b1;
                	end      
            end
        endcase
      end
  
  always @(posedge clk)begin
    	case(state)
            INIT: begin
            	i<=0;
            end
			SEND: begin
                i<=i+1;
            end
 		endcase
  end 
endmodule