`timescale 1ns / 1ps

// You MUST NOT change the module name or the ports declarations

module QAM(
    input wire clk,
    input wire rst,
    input wire [3:0] symbol,
    input wire data_valid_i,
    input wire start,
    input wire done_flag_i,

    output reg [7:0] I_data,
    output reg [7:0] Q_data,
    output reg data_valid_o,
    output reg done_flag_o
);
    // ----------- Insert your codes below --------------//
  
   localparam  INIT= 0,
               CALC = 1,
               DONE = 2;
  
  reg[2:0] state;
  reg[2:0] next_state;
  //reg m1,m2;
  
  
  always @(*) begin
    if (!rst)
      next_state = INIT;
    
    else begin
            case (state)
              INIT : next_state = (data_valid_i) ? CALC : (done_flag_i) ?DONE:INIT;
              CALC : next_state =  (done_flag_i) ? DONE:INIT;
              DONE : next_state = INIT;
              
             default: next_state = INIT;
            endcase
    end
  end
  
   always @(posedge clk or negedge rst) begin
     if (!rst)
      state <= INIT;
    else begin
            state <= next_state;
    end
   end
  
  always @(posedge clk or negedge rst) begin
        if (!rst) begin
          
         
        end
    else begin
      data_valid_o<=0;
      done_flag_o<=0;
      
      case(state)
        INIT: begin
          I_data<=0;
          Q_data<=0;
          data_valid_o<=0;
          done_flag_o<=0;
          if(done_flag_i)begin
            next_state = DONE;
          end
        end
        
        CALC:begin
          case(symbol[1:0])
             2'b00: Q_data<=8'b11000011;
       		 2'b01: Q_data<=8'b00111101;
       		 2'b11: Q_data<=8'b00010100;
       		 2'b10: Q_data<=8'b11101100;
        default: Q_data<=8'b11000011;
          endcase
            case(symbol[3:2])
             2'b00: I_data<=8'b11000011;
       		 2'b01: I_data<=8'b00111101;
       		 2'b11: I_data<=8'b00010100;
       		 2'b10: I_data<=8'b11101100;
        default: I_data<=8'b11000011;
            endcase 
              data_valid_o<=1;
              end
              
         DONE:begin
           done_flag_o<=1;
         end
      endcase
    end
  end
  

endmodule