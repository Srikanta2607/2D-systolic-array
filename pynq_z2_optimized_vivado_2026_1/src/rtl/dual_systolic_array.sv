`timescale 1ns / 1ps
`default_nettype none

// Two independent meshes with symmetrical DSP partitioning (Plan B – low-power).
// Power optimization: DSP_PE_LIMIT reduced from 110 to 64 per engine.
// Engine 0: 64 DSP48E1 MAC PEs + 192 LUT MAC PEs = 256 PEs total
// Engine 1: 64 DSP48E1 MAC PEs + 192 LUT MAC PEs = 256 PEs total
// Total DSPs: 128 / 220 (~58% of XC7Z020), down from 100% usage.
// This reduces dynamic power ~0.4-0.6 W vs. the 220-DSP baseline.
module dual_systolic_array #(
    parameter int ARRAY_ROWS     = 16,
    parameter int ARRAY_COLS     = 16,
    parameter int DATA_WIDTH     = 8,
    parameter int ACC_WIDTH      = 20,  // INT20 sufficient for K<=16 INT8 tiles
    parameter int DSP_PE_LIMIT   = 64,  // REDUCED: 64 DSPs per engine (was 110)
    parameter int DSP_PE_LIMIT_0 = DSP_PE_LIMIT,
    parameter int DSP_PE_LIMIT_1 = DSP_PE_LIMIT,
    parameter bit MASK_AT_INGRESS = 1'b0,
    parameter bit TRACK_OVERFLOW = 1'b0  // Disabled to save LUTs
)(
    input  wire                                  clk,
    input  wire                                  rst_n,

    input  wire                                  clr_acc_0,
    input  wire                                  array_en_0,
    input  wire                                  active_mask_0 [0:ARRAY_ROWS-1][0:ARRAY_COLS-1],
    input  wire signed [DATA_WIDTH-1:0]          a_in_0 [0:ARRAY_ROWS-1],
    input  wire signed [DATA_WIDTH-1:0]          b_in_0 [0:ARRAY_COLS-1],
    output wire signed [ACC_WIDTH-1:0]           c_out_0 [0:ARRAY_ROWS-1][0:ARRAY_COLS-1],
    output wire                                  overflow_0,

    input  wire                                  clr_acc_1,
    input  wire                                  array_en_1,
    input  wire                                  active_mask_1 [0:ARRAY_ROWS-1][0:ARRAY_COLS-1],
    input  wire signed [DATA_WIDTH-1:0]          a_in_1 [0:ARRAY_ROWS-1],
    input  wire signed [DATA_WIDTH-1:0]          b_in_1 [0:ARRAY_COLS-1],
    output wire signed [ACC_WIDTH-1:0]           c_out_1 [0:ARRAY_ROWS-1][0:ARRAY_COLS-1],
    output wire                                  overflow_1
);

    localparam int EFF_DSP_LIMIT_0 = DSP_PE_LIMIT_0;
    localparam int EFF_DSP_LIMIT_1 = DSP_PE_LIMIT_1;

    systolic_array #(
        .ARRAY_ROWS  (ARRAY_ROWS),
        .ARRAY_COLS  (ARRAY_COLS),
        .DATA_WIDTH  (DATA_WIDTH),
        .ACC_WIDTH   (ACC_WIDTH),
        .MAC_IMPL    ("HYBRID"),
        .DSP_PE_LIMIT(EFF_DSP_LIMIT_0),
        .MASK_AT_INGRESS(MASK_AT_INGRESS),
        .TRACK_OVERFLOW(TRACK_OVERFLOW)
    ) u_engine_0 (
        .clk        (clk),
        .rst_n      (rst_n),
        .clr_acc    (clr_acc_0),
        .array_en   (array_en_0),
        .active_mask(active_mask_0),
        .a_in       (a_in_0),
        .b_in       (b_in_0),
        .c_out      (c_out_0),
        .overflow   (overflow_0)
    );

    systolic_array #(
        .ARRAY_ROWS  (ARRAY_ROWS),
        .ARRAY_COLS  (ARRAY_COLS),
        .DATA_WIDTH  (DATA_WIDTH),
        .ACC_WIDTH   (ACC_WIDTH),
        .MAC_IMPL    ("HYBRID"),
        .DSP_PE_LIMIT(EFF_DSP_LIMIT_1),
        .MASK_AT_INGRESS(MASK_AT_INGRESS),
        .TRACK_OVERFLOW(TRACK_OVERFLOW)
    ) u_engine_1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .clr_acc    (clr_acc_1),
        .array_en   (array_en_1),
        .active_mask(active_mask_1),
        .a_in       (a_in_1),
        .b_in       (b_in_1),
        .c_out      (c_out_1),
        .overflow   (overflow_1)
    );

endmodule

`default_nettype wire
