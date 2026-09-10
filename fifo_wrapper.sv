`timescale 1ns / 1ps
// ============================================================================
//  FIFO Wrapper Template
//  This module wraps around the Xilinx fifo_generator_0 IP,
//  preserving exactly the same I/O interface for student use.
// ============================================================================

// You MUST NOT change the CONTENT of this file

module fifo_wrapper (
    input  wire clk,            // Clock
    input  wire rst,            // Active-low reset (wrapper inverts for srst)

    input  wire fifo_in_bit,    // Data input  (1 bit)
    input  wire wr_en,          // Write enable
    input  wire rd_en,          // Read enable

    output wire fifo_out_bit,   // Data output (1 bit)
    output wire full,           // FIFO full flag
    output wire empty           // FIFO empty flag
);

    // --------------------------------------------------------------------
    // Instance of Xilinx FIFO Generator IP
    // --------------------------------------------------------------------
    fifo_generator_0 fifo_generator_0_inst (
        .clk   (clk),          // input wire clk
        .srst  (~rst),         // FIFO expects active-high reset → use ~rst

        .din   (fifo_in_bit),  // input wire [0:0]
        .wr_en (wr_en),        // write enable
        .rd_en (rd_en),        // read enable

        .dout  (fifo_out_bit), // output wire [0:0]
        .full  (full),         // full flag
        .empty (empty)         // empty flag
    );

endmodule
