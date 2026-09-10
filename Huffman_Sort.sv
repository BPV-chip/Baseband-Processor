// You MUST NOT change the module name or the ports declarations
`timescale 1ns / 1ps
module Huffman_Sort #(
    parameter CHAR_SPACE = 5, 
    parameter FREQ_LEN = 4, 
    parameter CHAR_LEN = 3 
)(
    input start,
    input clk,
    input rst_n,
    input [CHAR_SPACE-1:0][FREQ_LEN:0] character_pool,

    output reg start_nxt,
    output reg [CHAR_LEN-1:0] min_pool_id,
    output reg [CHAR_LEN-1:0] nxtmin_pool_id
);
    // These declarations are provided as hints for a possible implementation.
    // You are free to modify, add, or remove them as long as the module's
    // external behavior is correct

    reg [CHAR_SPACE-1:0][CHAR_SPACE-1:0] compare_reg;
    reg [CHAR_SPACE-1:0][CHAR_LEN-1:0] position;
    reg [CHAR_SPACE-1:0][CHAR_LEN-1:0] sorted_map;

    localparam  INIT    = 0,
                CMP     = 1,
                SORT    = 2,
                GET_MIN = 3,
                DONE    = 4;

  reg[2:0] state;

    // ----------- Insert your codes below --------------//

  integer i, j;
  reg [CHAR_LEN-1:0] rank;//intermediate used to store position value
  
  
  always @(posedge clk or negedge rst_n) begin            
        if (!rst_n)
            state <= INIT;
        else begin
            case (state)
                INIT:    state <= start ? CMP : INIT;
                CMP:     state <= SORT;
                SORT:    state <= GET_MIN;
                GET_MIN: state <= DONE;
                DONE:    state <= INIT;
                default: state <= INIT;
            endcase
        end
    end
  
 always @(posedge clk or negedge rst_n) begin
  	if (!rst_n) begin
    	start_nxt <= 0;
    	position <= '0;
  	end
   	else
       start_nxt <= (state == DONE);
    end
 
 always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            compare_reg <= '0; 
            position <= '0;
      		min_pool_id  <= '0;
            nxtmin_pool_id <= '0;
        end

        else begin
            case(state)
              INIT: begin// Initialisations
                    compare_reg <= '0;
                    position <= '0;
              end
             
              CMP: begin//Compare reg matrix formation
  				for (i = 0; i < CHAR_SPACE; i = i + 1) begin
    				compare_reg[i][i] <= 0;

    				for (j = i + 1; j < CHAR_SPACE; j = j + 1) begin
     	 				if (character_pool[i] > character_pool[j]) begin
        					compare_reg[i][j] <= 1;
        					compare_reg[j][i] <= 0;
      					end
      					else if (character_pool[i] < character_pool[j]) begin
        					compare_reg[i][j] <= 0;
        					compare_reg[j][i] <= 1;
      					end
      					else begin
        					compare_reg[i][j] <= (i < j);
        					compare_reg[j][i] <= (j < i);
      					end
    				 end
 				 end
			  end 
              
              SORT: begin
/*Chars ranked wrt to frequency and size using compare_reg */                		 					 for (i = 0; i < CHAR_SPACE; i = i + 1) begin 
    					rank = '0;
							for (j = 0; j < CHAR_SPACE; j = j + 1) begin
      						rank = rank + compare_reg[i][j]; 
    						end

                      position[i] <= rank;
  					end
			  end

              GET_MIN: begin//loading of min_pool, next_min_pool
               	for(i=0;i<CHAR_SPACE;i=i+1) begin
                  if(position[i] == 0)
                    min_pool_id <= i[CHAR_LEN-1:0];
                  if(position[i] == 1)
                    nxtmin_pool_id <= i[CHAR_LEN-1:0];
                 end
              end
              
              DONE: begin
                start_nxt <= 1;
              end
            endcase
         end
      end
endmodule