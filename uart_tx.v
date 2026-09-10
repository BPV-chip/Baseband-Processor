`timescale 1ns / 1ps

// You MUST NOT change the module name or the ports declarations

module uart_tx (
        input clk,  //100MHz
        input rst_n, //when 0 idle state
        input [7:0] data_byte_in,
        input send_now,//Ready signal

        output reg finish_tx, //assigned 1 after one full tx
        output reg uart_tx_o  //Serial output
    );

    // FSM states parameters
    localparam INIT = 0, //Idle state
               SEND = 1, //Transmission process
               DONE = 2; //Wait time and assertion that transmission is done

    reg [1:0] state;

    reg [13:0] baud_time_counter; // counts clock ticks to measure the duration of one bit period
  
    reg [3:0] bit_counter; // 10 bits for transfering a whole byte

  reg [14:0] wait_between_byte; // counts clock ticks for the wait duration (20000 cycles) 15 bit is enough for 20k cycles
  
  reg [7:0] data_reg;//Data register
  
  //Parallel to serial
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin  //for asynchronous reset
      state<=INIT;
      uart_tx_o <=1'b1;
      finish_tx <= 1'b0;
      baud_time_counter <= 14'd0;
      bit_counter <= 4'd0;
      wait_between_byte <= 15'd0;
      data_reg <= 8'h00;
      end
    else begin
            finish_tx <= 1'b0;   // default low as it can be high only after on full tx for one clock cycle
      
      //FSM execution
      case (state)
        
        
        //Idle state
        
        INIT: begin
          		uart_tx_o <= 1'b1;
          		baud_time_counter <= 14'd0;
          		bit_counter <= 4'd0;
          		wait_between_byte <= 15'd0;
          	if (send_now) begin
            	data_reg <= data_byte_in; //Parallel data storage
            	state <= SEND; //Send part of tx FSM 
            end
           end
        
        
        //Transmission state
        
        SEND: begin
           if (baud_time_counter < 10417)
             baud_time_counter <= baud_time_counter + 1;
           else begin
             baud_time_counter <= 0;
             bit_counter <= bit_counter + 1;
             end
           
           if (bit_counter == 4'd0) begin //start bit
             uart_tx_o <= 1'b0;
             end
           else if (bit_counter >= 4'd1 && bit_counter <= 4'd8) begin //input parallel data into register
             uart_tx_o <= data_reg[bit_counter - 4'd1];
             end
           else if (bit_counter == 4'd9) begin //end bit
             uart_tx_o <= 1'b1; 
             end 
           else begin //for all other cases as we have taken a 4 bit register for bit counter
             uart_tx_o <= 1'b1;
             end
           
          if (bit_counter == 4'd9 && baud_time_counter == 10417)begin //after startbit+ 8 data bits+ stop bit are transmitted
             state <= DONE;
          end
           end
        
        //DONE state
        
        DONE: begin
          uart_tx_o <= 1'b1; // Idles high
          if (wait_between_byte < 15'd20000)
            wait_between_byte <= wait_between_byte + 1;
          else begin
            finish_tx <= 1'b1; //To notify on transmission is successfully done
            state <= INIT;
            end
                end

            endcase
    	end
    end  

endmodule