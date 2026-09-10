`timescale 1ns / 1ps

// You MUST NOT change the CONTENT of this file

module top #(
    parameter NUM_DATA = 15,
    parameter CHAR_SPACE = 5
)(
    input clk,
    input rst, // use posedge rst for button
    input uart_rx_i,
    output uart_tx_o
);
    localparam CODE_LEN = CHAR_SPACE - 1;
    localparam CHAR_LEN = $clog2(CHAR_SPACE);
    localparam FREQ_LEN = $clog2(NUM_DATA + 1);
    localparam CODE_LEN_LEN = $clog2(CODE_LEN + 1);
    
    wire rst_n;
    assign rst_n = ~rst;

    initial begin
        if (CHAR_LEN > 8) begin
            $warning("[%m] WARNING: CHAR_LEN (%0d) is larger than 8. The UART interface only provides 8 bits, so the upper bits of your characters will always be zero.", CHAR_LEN);
        end
    end

    localparam TX_BUF_SIZE = (NUM_DATA * CODE_LEN) + 4;
    localparam CNT_WIDTH = $clog2(TX_BUF_SIZE + 1);
    localparam MSG_CNT_WIDTH = $clog2(NUM_DATA + 1);

    // Local storage to replay the original message during TX phase
    reg [NUM_DATA-1:0][CHAR_LEN-1:0] saved_text_msg; 
    
    // Huffman wrapper control signals
    reg huff_start;
    reg huff_done;
    wire huff_valid;
    wire [CHAR_LEN-1:0] huff_msg_in;

    // Huffman encoding output signals:
    wire finish_huffman;

    // UART RX signals
    wire rec_full_byte;
    wire [7:0] text_msg_chara;

    // FIFO signals:
    wire fifo_in_bit;
    wire fifo_out_bit;
    wire wr_en;
    wire rd_en;
    wire full;
    wire empty;

    // Viterbi signals:
    wire start_QAM;
    wire done_flag_viterbi;
    wire data_valid_viterbi;
    wire [3:0] out_symbol;

    // QAM signals:
    wire [7:0] I_data_QAM;
    wire [7:0] Q_data_QAM;
    wire done_QAM;
    wire data_valid_QAM;

    // To Tx signals:
    reg [TX_BUF_SIZE-1:0][7:0] store_QAM_results;
    reg [CNT_WIDTH-1:0] store_QAM_counter;
    reg [CNT_WIDTH-1:0] store_QAM_counter_tx;
    reg [MSG_CNT_WIDTH-1:0] send_data_counter_text;
    reg [CNT_WIDTH-1:0] send_data_counter_result;

    reg send_now_tx;
    reg finish_tx;
    reg [7:0] data_byte_in;

    // signals for rx control:
    reg [MSG_CNT_WIDTH-1:0] rx_chara_counter;

    typedef enum logic[2:0] { 
        INIT,
        REC,
        WAIT_p,
        TRAN_1,
        TRAN_2
    } state_t;

    state_t state;

    reg [1:0] uart_rx_i_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            uart_rx_i_sync <= 2'b11;
        else 
            uart_rx_i_sync <= {uart_rx_i_sync[0], uart_rx_i};
    end
    // -----------------------------------------------------------
    // Instantiate Modules
    // -----------------------------------------------------------
    uart_rx uart_rx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx_i_sync[1]),

        .rec_full_byte(rec_full_byte),
        .text_msg_chara(text_msg_chara)
    );

    // Direct mapping: Valid pulse from UART drives Valid pulse to Huffman
    assign huff_valid = rec_full_byte;
    assign huff_msg_in = text_msg_chara[CHAR_LEN-1:0];

    Huffman_wrapper #(
        .NUM_DATA(NUM_DATA),
        .CHAR_SPACE(CHAR_SPACE),
        .CHAR_LEN(CHAR_LEN),
        .CODE_LEN(CODE_LEN),
        .FREQ_LEN(FREQ_LEN),
        .CODE_LEN_LEN(CODE_LEN_LEN)
    ) Huffman_wrapper_inst (
        .clk(clk),
        .rst_n(rst_n),      // Assuming rst is Active Low
        .text_msg_in(huff_msg_in),
        .start(huff_start), // Pulses once in INIT
        .valid(huff_valid), // Pulses every time UART gets a byte
        .done(huff_done),   // Pulses after last byte

        .out_bit(fifo_in_bit),
        .wr_en(wr_en),
        .finish_huffman_o(finish_huffman)
    );

    fifo_wrapper fifo_inst (
        .clk(clk),  
        .rst(rst_n),         // FIFO often expects Active High reset
        .fifo_in_bit(fifo_in_bit),   
        .wr_en(wr_en),    
        .rd_en(rd_en),    
        .fifo_out_bit(fifo_out_bit), 
        .full(full),      
        .empty(empty)    
    );

    Viterbi Viterbi_inst(
        .clk(clk),
        .rst(rst_n),
        .fifo_data_out(fifo_out_bit),
        .fifo_empty(empty),
        .start(finish_huffman), // Triggers when Huffman is totally done

        .done_flag(done_flag_viterbi),
        .start_nxt(start_QAM),
        .fifo_rd_en(rd_en),
        .data_valid(data_valid_viterbi),
        .out_symbol(out_symbol)
    );

    QAM QAM_inst(
        .clk(clk),
        .rst(rst_n),
        .symbol(out_symbol),
        .data_valid_i(data_valid_viterbi),
        .start(start_QAM),
        .done_flag_i(done_flag_viterbi),

        .I_data(I_data_QAM),
        .Q_data(Q_data_QAM),
        .data_valid_o(data_valid_QAM),
        .done_flag_o(done_QAM)
    );

    uart_tx uart_tx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_byte_in(data_byte_in),
        .send_now(send_now_tx),

        .finish_tx(finish_tx),
        .uart_tx_o(uart_tx_o)
    );

    // -----------------------------------------------------------
    // Main Control Logic
    // -----------------------------------------------------------
    integer i;
    always @(posedge clk, negedge rst_n)
    begin
        if(!rst_n) begin
            state <= INIT;
            rx_chara_counter <= 0;
            store_QAM_counter <= 0;
            send_now_tx <= 1'b0;
            send_data_counter_result <= 0;
            send_data_counter_text <= 0;
            huff_start <= 1'b0;
            huff_done <= 1'b0;
            
            for(i=0; i<NUM_DATA; i=i+1) 
                saved_text_msg[i] <= 0;
            for(i=0; i<TX_BUF_SIZE; i=i+1)
                store_QAM_results[i] <= 0;
        end
        else begin
            case(state)
                INIT: begin
                    send_data_counter_text <= 0;
                    send_data_counter_result <= 0;
                    send_now_tx <= 1'b0;
                    store_QAM_counter <= 0;
                    rx_chara_counter <= 0;
                    huff_done <= 1'b0;

                    // 1. Initialize Huffman Wrapper
                    huff_start <= 1'b1; 
                    state <= REC;
                end

                REC: begin
                    huff_start <= 1'b0; // Clear start pulse

                    if(rec_full_byte == 1'b1) begin
                        // 2. Store locally for later replay (TRAN_1)
                        saved_text_msg[rx_chara_counter] <= text_msg_chara[CHAR_LEN-1:0];

                        // 3. Serial Feeding Logic
                        // Note: The huff_valid signal is wired directly to rec_full_byte
                        // so the data goes into the wrapper this cycle.

                        if(rx_chara_counter == NUM_DATA-1) begin
                            state <= WAIT_p;
                            huff_done <= 1'b1; // Signal Huffman that input stream ended
                        end
                        else begin
                            rx_chara_counter <= rx_chara_counter + 1;
                        end
                    end
                end

                WAIT_p: begin
                    huff_done <= 1'b0;
                    
                    if(done_QAM == 1'b1) begin
                        state <= TRAN_1;
                        store_QAM_counter_tx <= store_QAM_counter;
                    end
                    else if(data_valid_QAM == 1'b1) begin
                        store_QAM_results[store_QAM_counter] <= I_data_QAM;
                        store_QAM_results[store_QAM_counter + 1] <= Q_data_QAM;
                        store_QAM_counter <= store_QAM_counter + 2;
                    end
                end

                TRAN_1: begin
                    if(send_data_counter_result >= store_QAM_counter_tx) begin // All finished
                        if(send_data_counter_result == store_QAM_counter_tx) begin
                            state <= TRAN_2;
                            send_now_tx <= 1'b1;
                            data_byte_in <= 8'h55; // End Marker
                            send_data_counter_result <= send_data_counter_result + 1;
                        end
                        else begin
                            state <= INIT;
                        end
                    end
                    else if(send_data_counter_text < NUM_DATA) begin // Use NUM_DATA param
                        state <= TRAN_2;
                        send_now_tx <= 1'b1;
                        // Read from the local copy
                        data_byte_in <= saved_text_msg[send_data_counter_text]; 
                        send_data_counter_text <= send_data_counter_text + 1;
                    end
                    else if(send_data_counter_text == NUM_DATA) begin
                        state <= TRAN_2;
                        send_now_tx <= 1'b1;
                        data_byte_in <= store_QAM_results[send_data_counter_result];
                        send_data_counter_result <= send_data_counter_result + 1;
                    end
                end

                TRAN_2: begin
                    send_now_tx <= 1'b0;
                    if(finish_tx)
                        state <= TRAN_1;
                end
            endcase
        end
    end

endmodule