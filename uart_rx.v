`timescale 1ns / 1ps

// You MUST NOT change the module name or the ports declarations
module uart_rx(
    input clk,
    input rst_n,
    input uart_rx_i,

    output reg rec_full_byte,  // A full byte has been received (1-cycle pulse)
    output reg [7:0] text_msg_chara
);
   

  reg [13:0] baud_time_counter; // counts clock ticks to measure the duration of one bit period
    reg [3:0] bit_counter; // 10 bits for transferring a whole byte
    reg en_baud_counter; // enables counting when a UART frame is being received
    //wire neg_uart_rx; // single-cycle pulse that detects the falling edge of the start bit
  
  reg stop_bit_check; //Introducing this to detect the stop bit

   localparam integer BAUD_CYCLES = 10417;
  localparam integer MID_CYCLE_SAMPLE = 5208; // For accurate data
  
  
  //Serial to parallel
  
  
  reg uart_rx_i_reg;// One-clock delayed sample of the input used to check edge detection for the start bit 
  
  always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            uart_rx_i_reg <= 1'b1; // uart line is high at idle condition 
        else
            uart_rx_i_reg <= uart_rx_i;
    end

  wire neg_uart_rx = (uart_rx_i_reg & ~uart_rx_i);//and operation to detect falling edge start bit
  
  always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          baud_time_counter <= 14'd0;
          bit_counter <= 4'd0;
          en_baud_counter <= 1'b0;
          rec_full_byte <= 1'b0;
          text_msg_chara <= 8'd0;
          end
    else begin
      rec_full_byte <= 1'b0;  // default each cycle

      if (neg_uart_rx && !en_baud_counter) begin //Serial input has started
                en_baud_counter <= 1'b1; //Start counting
                baud_time_counter <= 14'd0;
                bit_counter <= 4'd0;
      end

            
      if (en_baud_counter) begin //When counting starts
        if (baud_time_counter < BAUD_CYCLES)begin //Middle of a bit cycle
            baud_time_counter <= baud_time_counter + 1'b1;
        end
        else begin
            baud_time_counter <= 14'd0;
            bit_counter <= bit_counter + 1'b1;
         end
      end
              
                
        if (baud_time_counter == MID_CYCLE_SAMPLE) begin // Mid bit sampling for accuracy

                   if (bit_counter == 4'd0) begin
                       if (uart_rx_i == 1'b1) begin //False start check
                        	en_baud_counter <= 1'b0; //Assign all the counters 0 again
                        	baud_time_counter <= 14'd0;
                        	bit_counter <= 4'd0;
                        end
                   end
          
                	else if (bit_counter >= 4'd1 && bit_counter <= 4'd8) begin //The data bits starting from when bit counter is 1, avoiding start bit
                        text_msg_chara[bit_counter - 1] <= uart_rx_i;
                    end
             
          			else if (bit_counter == 4'd9) begin//All data done
                      	if (uart_rx_i == 1'b1)begin
                          stop_bit_check<= 1'b1;// A full byte has been received (1-cycle)
                      	end
						else 
						   stop_bit_check <= 1'b0;// The data will not be processed if the stop bit is not high
					 	end
            end
       
            if( stop_bit_check==1 && baud_time_counter==BAUD_CYCLES)begin //Check for bit 9 full cycle completion
					rec_full_byte<=1;
					stop_bit_check<= 1'b0;
					en_baud_counter <= 1'b0;// assigning 0 as the cycle ended
					bit_counter <= 4'd0;
					baud_time_counter <= 14'd0;
              end
               
            end
        end
    

endmodule
