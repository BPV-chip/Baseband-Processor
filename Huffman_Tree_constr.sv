// You MUST NOT change the module name or the ports declarations
`timescale 1ns / 1ps
module Huffman_Tree_constr #(
    parameter CHAR_SPACE = 5,
    parameter CHAR_LEN = 3,
    parameter CODE_LEN = 4,
    parameter FREQ_LEN = 4,
    parameter CODE_LEN_LEN = 3
)(
    input clk,
    input rst_n,
    input [CHAR_SPACE-1: 0][FREQ_LEN-1: 0] character_freq_unsort,
    input start,

    output reg start_nxt,
    output reg [CHAR_SPACE-1: 0][CODE_LEN-1: 0] huffman_lib_out, 
    output reg [CHAR_SPACE-1: 0][CODE_LEN_LEN-1: 0] huffman_len_out  
);
    // These declarations are provided as hints for a possible implementation.
    // You are free to modify, add, or remove them as long as the module's
    // external behavior is correct

    reg [CHAR_SPACE-1:0][CODE_LEN-1:0] char_code;
    reg [CHAR_SPACE-1:0][CODE_LEN_LEN-1:0] char_len;
    reg [CHAR_SPACE-1:0][CHAR_LEN-1:0] char_pool_id;
    
    localparam  INIT        = 0, 
                LOAD        = 1,
                SORT        = 2,
                WAIT_SORT   = 3,
                SUM         = 4,
                POOL_UPDATE = 5,
                CODE_UPDATE = 6,
                DONE        = 7;

    localparam MAX_NUM = 2 ** FREQ_LEN;

    reg[2:0] state;
    reg [FREQ_LEN:0] sum_min_nxtmin;
    reg [CHAR_LEN-1:0] loop_counter;


    // DO NOT change the module instantiation

    reg start_sort;
    wire done_sort;

    reg [CHAR_SPACE-1:0][FREQ_LEN:0] arr_pool_freq;
    wire [CHAR_LEN-1:0] min_pool_id;
    wire [CHAR_LEN-1:0] nxtmin_pool_id;

    Huffman_Sort #(
        .CHAR_SPACE(CHAR_SPACE),
        .FREQ_LEN(FREQ_LEN),
        .CHAR_LEN(CHAR_LEN)
    ) Huffman_Sort_inst(
        .start(start_sort),
        .clk(clk),
        .rst_n(rst_n),
      .character_pool(arr_pool_freq), 

        .start_nxt(done_sort),
        .min_pool_id(min_pool_id),
        .nxtmin_pool_id(nxtmin_pool_id)
    );
    
    // ----------- Insert your codes below --------------//
  
  integer i;
  reg [CHAR_SPACE-1:0][FREQ_LEN:0] char_pool_id_old; //Stores the pool id before id updation
  
  
  //State Transitions//
  
    always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    state <= INIT;
  else begin
    case (state)
      INIT:       state <= start ? LOAD : INIT;
      LOAD:       state	<= SORT;
      SORT: 	  state <= WAIT_SORT;
      WAIT_SORT:  state <= done_sort ? SUM:WAIT_SORT;
      SUM:        state	<=POOL_UPDATE;
      POOL_UPDATE:state	<= CODE_UPDATE;
      CODE_UPDATE:state	<=(loop_counter== CHAR_SPACE-1) ? DONE:SORT;
      DONE:       state <= INIT;
      default:    state <= INIT;
    endcase
  end
end
  
  //Initializations// 
  
  always @(posedge clk or negedge rst_n) begin
    	if (!rst_n) begin
      		loop_counter <= 0;
      		sum_min_nxtmin <= 0;
      		start_sort <= 0;
      		start_nxt <= 0;
      			for (i=0; i<CHAR_SPACE; i=i+1) begin
       				 char_code[i]<= 0;
        			 char_len[i]<= 0;
       				 char_pool_id[i]<= i;
       				 arr_pool_freq[i]<= 0;
       		    end
      	end
    	else begin
     		 start_nxt<= 0;
      		 start_sort<= 0;
      
     		 case (state)
        		INIT:begin //Variables initialization for new cycle
         	 		loop_counter<=0;
         	 		sum_min_nxtmin<=0;
                  for (i=0; i<CHAR_SPACE; i=i+1) begin 
        					char_code[i]<= 0;
        					char_len[i]<= 0;
        					char_pool_id[i]<= i;
            			end
          		end
        
      		  	LOAD:begin // Input frequency loading  
         			 for (i=0; i<CHAR_SPACE; i=i+1)begin
           				 arr_pool_freq[i]<=character_freq_unsort[i];
          			 end
        		end
        
       		 	SORT:begin
          			start_sort <= 1'b1;
         				 if (done_sort)begin
            				start_sort <= 1'b0;
          				 end
        		end
        
        		WAIT_SORT:begin// Buffer state for sorting to be done
        		end
        
        		SUM:begin //Pool frequency updation for merged node
          sum_min_nxtmin<= arr_pool_freq[min_pool_id]+arr_pool_freq[nxtmin_pool_id];
         		end
        
        		POOL_UPDATE:begin
          arr_pool_freq[nxtmin_pool_id] <=sum_min_nxtmin;//Sum of the merged node frequencies updation to the number with higher frequency or lower value 
          arr_pool_freq[min_pool_id] <=MAX_NUM;// Storage of a frequency greater that the sum of all the exsisting frequencies to the number with lower frequency or higher value 
          loop_counter <= loop_counter + 1;//Counter increment everytime one sorting cycle is done. 
          			for (i = 0; i < CHAR_SPACE; i = i + 1) begin
             			char_pool_id_old[i] <= char_pool_id[i];
            		end
          
           			for (i = 0; i < CHAR_SPACE; i = i + 1) begin
             			if (char_pool_id[i] == min_pool_id) begin
              				 char_pool_id[i] <= nxtmin_pool_id;
             			end
          			end
         		end
        
        		CODE_UPDATE:begin
          			for (i=0; i<CHAR_SPACE; i=i+1) begin
            			if (char_pool_id_old[i] == min_pool_id) begin
                          char_code[i]<=(char_code[i] << 1);
              			  char_len[i]<=char_len[i] + 1;
             			end
            			else if (char_pool_id_old[i] == nxtmin_pool_id) begin
              				char_code[i]<= (char_code[i] << 1) | 1'b1;
              				char_len[i]<= char_len[i] + 1;
             			end
            		end
          		end
    		endcase 
    	end
    end
 
  always @(*) begin//Combinational logic
	case(state) 
        DONE: begin
          for (i=0; i<CHAR_SPACE; i=i+1) begin
            huffman_lib_out[i] = char_code[i];//Character codes
            huffman_len_out[i] = char_len[i];// character code lengths
          end
          start_nxt = 1'b1;
        end
        default: begin
          	start_nxt = 1'b0;
        end
    endcase
end
endmodule