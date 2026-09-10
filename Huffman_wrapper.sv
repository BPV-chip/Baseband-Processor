
// You MUST NOT change the CONTENT of this file

module Huffman_wrapper #(
    parameter NUM_DATA = 15,
    parameter CHAR_LEN = 3,
    parameter CHAR_SPACE = 5,
    parameter CODE_LEN = 4,
    parameter FREQ_LEN = 4,
    parameter CODE_LEN_LEN = 3
)(
    input clk,
    input rst_n,
    input [CHAR_LEN-1: 0] text_msg_in,
    input start,
    input valid,
    input done,

    output wire out_bit,
    output wire wr_en,
    output wire finish_huffman_o
);

    reg [2:0] state;
    localparam  INIT        = 0,
                READ_IN     = 1,
                WAIT_TREE   = 2,
                ENC         = 3;

    wire start_huff;            // start the tree builder
    wire start_nxt_tree2enc;    // tree is built
    
    reg start_encode;           // start encode a saved symbol
    wire encode_idle;           // a symbol encoding is done
    reg finish_last_encode;     // all symbols are done

    // save symbols in an array
    reg [CHAR_LEN-1: 0] saved_msg [NUM_DATA-1:0];
    
    // counter for saving symbols and sending symbols to the
    // encoder
    reg [FREQ_LEN:0] msg_save_counter;
    reg [FREQ_LEN:0] msg_enc_counter;

    reg [CHAR_SPACE-1:0][FREQ_LEN-1:0] character_freq_unsort;
    wire [CHAR_SPACE-1:0][CODE_LEN-1:0] huffman_lib;
    wire [CHAR_SPACE-1:0][CODE_LEN_LEN-1:0] huffman_len;
    
    // saved huffman tree info
    reg [CHAR_SPACE-1:0][CODE_LEN-1:0] saved_huffman_lib;
    reg [CHAR_SPACE-1:0][CODE_LEN_LEN-1:0] saved_huffman_len;
    reg [CHAR_LEN-1: 0] enc_text_msg;
    
    assign start_huff = (state == READ_IN) && done;
    assign finish_huffman_o = (state == ENC) && finish_last_encode;

    always @(posedge clk, negedge rst_n)
    begin
        if(!rst_n) begin
            state <= INIT;
        end
        else begin
            case(state)
                INIT: begin
                    if(start == 1'b1)
                        state <= READ_IN;
                end
                READ_IN: begin
                    if(done == 1'b1)
                        state <= WAIT_TREE;
                end
                WAIT_TREE: begin
                    if(start_nxt_tree2enc)
                        state <= ENC;
                end
                ENC:
                    if(finish_last_encode)
                        state <= INIT;
            endcase
        end
    end

    integer i;
    always @(posedge clk) begin
        case(state)
            INIT: begin
                for(i=0; i<=CHAR_SPACE-1; i=i+1)
                    character_freq_unsort[i] <= 0;
            end
            READ_IN: begin
                if(valid == 1'b1)
                    character_freq_unsort[text_msg_in] = character_freq_unsort[text_msg_in] + 1'b1;
            end
            WAIT_TREE: begin
                if(start_nxt_tree2enc) begin
                    saved_huffman_lib <= huffman_lib;
                    saved_huffman_len <= huffman_len;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        case(state)
            INIT: begin
                msg_save_counter <= 0;
                start_encode <= 0;
                finish_last_encode <= 0;
            end
            READ_IN: begin
                if(valid == 1'b1) begin
                    saved_msg[msg_save_counter] <= text_msg_in;
                    msg_save_counter <= msg_save_counter + 1'b1;
                end
            end
            WAIT_TREE: begin
                if(start_nxt_tree2enc)
                    msg_enc_counter <= 0;
            end
            ENC: begin
                if(start_encode)
                    start_encode <= 1'b0;
                else if(encode_idle) begin
                    if (msg_enc_counter != msg_save_counter) begin
                        enc_text_msg <= saved_msg[msg_enc_counter];
                        msg_enc_counter <= msg_enc_counter + 1'b1;
                        start_encode <= 1'b1;
                    end else begin
                        finish_last_encode <= 1'b1;
                    end
                end
            end
        endcase
    end

    Huffman_Tree_constr #(
        .CHAR_SPACE(CHAR_SPACE),
        .CHAR_LEN(CHAR_LEN),
        .CODE_LEN(CODE_LEN),
        .FREQ_LEN(FREQ_LEN),
        .CODE_LEN_LEN(CODE_LEN_LEN)
    ) Huffman_Tree_constr_inst(
        .clk(clk),
        .rst_n(rst_n),
        .character_freq_unsort(character_freq_unsort),
        .start(start_huff),

        .start_nxt(start_nxt_tree2enc),
        .huffman_lib_out(huffman_lib),
        .huffman_len_out(huffman_len)
    );

    Huffman_Enc #(
        .CHAR_SPACE(CHAR_SPACE),
        .CODE_LEN(CODE_LEN),
        .CHAR_LEN(CHAR_LEN),
        .CODE_LEN_LEN(CODE_LEN_LEN)
    ) Huffman_Enc_inst(
        .clk(clk),
        .rst_n(rst_n),
        .start(start_encode),
        .text_msg(enc_text_msg),
        .huffman_lib(saved_huffman_lib),
        .huffman_len(saved_huffman_len),

        .wr_en(wr_en),
        .out_bit(out_bit),
        .idle(encode_idle)
    );
endmodule 