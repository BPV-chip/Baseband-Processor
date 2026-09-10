`timescale 1ns / 1ps

// You MUST NOT change the module name or the ports declarations

module Viterbi(
    input clk,
    input rst,
    input fifo_data_out,
    input fifo_empty,
    input start,

    output reg start_nxt,
    output reg fifo_rd_en,
    output reg [3:0] out_symbol,
    output reg done_flag,
    output wire data_valid
 
  
);
    // These declarations are provided as hints for a possible implementation.
    // You are free to modify, add, or remove them as long as the module's
    // external behavior is correct
    wire encode_in;
    reg [1:0] encode_reg;
    reg [1:0] encode_out;

    assign encode_in = (fifo_empty == 1'b0) ? fifo_data_out : 1'b0;
    
    // ----------- Insert your codes below --------------//
  
    localparam  IDLE = 0,
                READ = 1,
                ENCODE = 2,
  				ODD=3,
                DONE = 4;
  
  reg [2:0] state;
  reg [2:0] next_state;
  reg m1,m2;
  reg [1:0] crumb; 
  reg [3:0] store;
  reg buffer_state;
  reg [2:0] zero_pad; 
  reg fifo_bit;
  

  reg symbol_valid;
  assign data_valid = symbol_valid ;

  
  always @(*) begin
    if (!rst)
      next_state = IDLE;
    
    else begin
            case (state)
              IDLE : next_state = start ? READ : IDLE;
              READ : next_state =  ENCODE;
              ENCODE : next_state = (fifo_empty) ? ODD:READ;
              ODD:next_state = (zero_pad==3'd2)? DONE:ODD ;
              DONE : next_state =  IDLE;
             default: next_state = IDLE;
            endcase
    end
  end
  
   always @(posedge clk or negedge rst) begin
     if (!rst)
      state <= IDLE;
    else begin
            state <= next_state;
    end
   end
  
  always @(*)begin
    	case(state)
          
          	IDLE: begin
          		m1 = 0;
          		m2 = 0;
          		buffer_state = 0;
          		zero_pad = 3'd0;
          		symbol_valid = 0;
          		store = 4'd0;
              	fifo_bit = 0;
            end
          	READ:begin
              	
              		if (!fifo_empty)begin
            			fifo_rd_en = 1;
          	  		end
              		else begin
                		fifo_rd_en = 0;
              		end
          	end
          
          	ENCODE:begin
          			crumb[0] = fifo_data_out ^ m1 ^ m2;
          			crumb[1] = fifo_data_out  ^ m2;
          			//symbol_valid <= 0;
            			if (!buffer_state) begin
            				store[1:0] = crumb;
            				symbol_valid = 0;
          				end
          				else begin
            				store[3:2] = crumb;
            				out_symbol = store;
          					symbol_valid = 1;
          				end
          	end
         
            ODD: begin
              	crumb[0] = m1 ^ m2;
           		crumb[1] = m2;
              if(buffer_state&& zero_pad==3'd0)begin
                      store[3:2] = crumb;
                      out_symbol = store;
          			symbol_valid = 1;
              end
          		
              if(buffer_state&& zero_pad==3'd1)begin
                      store[3:2] = crumb;
                      out_symbol = store;
          				symbol_valid = 1;
                    end
              else if(!buffer_state&& zero_pad==3'd1)begin
                		out_symbol = {2'b00,crumb};
                        symbol_valid = 1;
              		end
              else if(!buffer_state && zero_pad==3'd0)begin
                       store[1:0] = crumb;
          				symbol_valid = 0;
                    end
             end
		endcase
  end 
     
  always @(posedge clk or negedge rst) begin
        if (!rst) begin
          
          start_nxt <= 0;
          fifo_rd_en <= 0;
          out_symbol <= 0;
          done_flag <= 0;
          buffer_state <= 0;
          m1 <= 0;
          m2 <= 0;
          store<=4'd0;
          zero_pad <=0;
          symbol_valid <= 0;
        end
    else begin
      start_nxt  <= 0;
      fifo_rd_en <= 0;
      done_flag  <= 0;
      symbol_valid <= 0;
      
      case(state)
        IDLE: begin
          start_nxt <=start;
        end
        
        ENCODE: begin
                    fifo_bit<=fifo_data_out;
                  	m2 <= m1;
          			m1 <= fifo_data_out ;
          				if (!buffer_state) begin
            				buffer_state  <= 1;
          				end
          				else begin
            				buffer_state  <= 0;
          				end
          		 
        end
         
        ODD:begin
          fifo_bit<=0;
          m2 <= m1;
          m1 <= 0;
          if(buffer_state)begin
            buffer_state  <= 0;
            zero_pad <= zero_pad + 3'd1;
          end
            
          else if(!buffer_state)begin
           buffer_state  <= 1;
           zero_pad <= zero_pad + 3'd1;
          end
        end
         
         
        DONE: begin
          symbol_valid <= 0;
           done_flag <= 1;
        end
      endcase
    end
  end
     endmodule