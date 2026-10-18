`timescale 1ns / 1ps
`default_nettype none

// ============================================================================
// Module: pe_mac
// Description: Parameterized Processing Element (PE) with Multiply-Accumulate
//              and Selectable MAC Implementation (DSP / LUT / SHARED).
//
// Power Optimizations (v2 – PYNQ-Z2 low-power):
//   - FREE_RUN_FORWARD disabled by default: forwarding FFs only toggle on 'en'
//     to cut dynamic switching power on inactive rows/columns.
//   - TRACK_OVERFLOW gated at compile time so inactive PEs carry no logic.
//   - use_dsp="no" on all LUT paths prevents spurious DSP inference for the
//     accumulator add, which Vivado may otherwise pick up.
//   - DSP48E1 OPMODE/ALUMODE attributes are not forced here; Vivado maps the
//     plain multiply-accumulate into a single DSP48E1 MACC primitive.
// ============================================================================

module pe_mac #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 20,     // INT20 fits K<=16 × INT8×INT8 without overflow
    parameter     MAC_IMPL   = "DSP",  // "DSP", "LUT", "SHARED"
    parameter bit FREE_RUN_FORWARD = 1'b0,
    parameter bit TRACK_OVERFLOW = 1'b0  // Disabled by default to save LUTs
)(
    input  wire                          clk,
    input  wire                          rst_n,      // Synchronous active-low reset
    input  wire                          clr_acc,    // Clear accumulator for new K-pass
    input  wire                          en,         // Active region enable

    // Systolic stream inputs
    input  wire signed [DATA_WIDTH-1:0]  a_i,        // Activation input from West
    input  wire signed [DATA_WIDTH-1:0]  b_i,        // Weight/feature input from North

    // Systolic forwarding outputs (1-cycle register delay)
    output logic signed [DATA_WIDTH-1:0] a_o,        // Forward to East
    output logic signed [DATA_WIDTH-1:0] b_o,        // Forward to South

    // Accumulated output and status
    output logic signed [ACC_WIDTH-1:0]  acc_o,      // Signed accumulator (INT20)
    output logic                         overflow_o  // Sticky overflow indicator
);

    // Internal pipeline registers
    logic signed [DATA_WIDTH-1:0] a_q;
    logic signed [DATA_WIDTH-1:0] b_q;
    logic signed [ACC_WIDTH-1:0]  acc_q;
    logic                         overflow_q;

    // Multiplier product (16-bit for INT8 × INT8)
    localparam int PROD_WIDTH = 2 * DATA_WIDTH;
    wire signed [PROD_WIDTH-1:0] mult_product;

    // -------------------------------------------------------------------------
    // Synthesize MAC according to MAC_IMPL parameter
    // -------------------------------------------------------------------------
    generate
        if (MAC_IMPL == "LUT") begin : gen_lut_mac
            (* use_dsp = "no" *) wire signed [PROD_WIDTH-1:0] product_lut;
            assign product_lut = a_i * b_i;
            assign mult_product = product_lut;
        end else if (MAC_IMPL == "SHARED") begin : gen_shared_mac
            (* use_dsp = "no" *) wire signed [PROD_WIDTH-1:0] product_shared;
            assign product_shared = a_i * b_i;
            assign mult_product = product_shared;
        end else begin : gen_dsp_mac // Default: "DSP"
            (* use_dsp = "yes" *) wire signed [PROD_WIDTH-1:0] product_dsp;
            assign product_dsp = a_i * b_i;
            assign mult_product = product_dsp;
        end
    endgenerate

    // Sign-extend product to accumulator width (INT20)
    wire signed [ACC_WIDTH-1:0] prod_ext = {{(ACC_WIDTH - PROD_WIDTH){mult_product[PROD_WIDTH-1]}}, mult_product};

    // -------------------------------------------------------------------------
    // Accumulator (LUT or DSP path)
    // -------------------------------------------------------------------------
    wire signed [ACC_WIDTH-1:0] next_acc;
    generate
        if (MAC_IMPL == "LUT" || MAC_IMPL == "SHARED") begin : gen_lut_accum
            (* use_dsp = "no" *) wire signed [ACC_WIDTH-1:0] next_acc_lut;
            assign next_acc_lut = acc_q + prod_ext;
            assign next_acc = next_acc_lut;
        end else begin : gen_dsp_accum
            (* use_dsp = "yes" *) wire signed [ACC_WIDTH-1:0] next_acc_dsp;
            assign next_acc_dsp = acc_q + prod_ext;
            assign next_acc = next_acc_dsp;
        end
    endgenerate

    // Overflow detection (combinational, guarded by TRACK_OVERFLOW)
    wire signed_overflow = TRACK_OVERFLOW ?
        ((acc_q[ACC_WIDTH-1] == prod_ext[ACC_WIDTH-1]) &&
         (next_acc[ACC_WIDTH-1] != acc_q[ACC_WIDTH-1])) : 1'b0;

    // -------------------------------------------------------------------------
    // Sequential update — power-optimized:
    //   * Forwarding FFs only toggle when 'en' is asserted (or FREE_RUN_FORWARD)
    //   * Accumulator FFs only toggle when 'en' && !clr_acc
    //   * Clock enable prevents unnecessary switching on idle PEs
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            a_q        <= '0;
            b_q        <= '0;
            acc_q      <= '0;
            overflow_q <= 1'b0;
        end else begin
            // Clear accumulator takes priority over accumulate
            if (clr_acc) begin
                acc_q      <= '0;
                overflow_q <= 1'b0;
            end

            // Forwarding: conditionally enabled to cut switching power
            if (FREE_RUN_FORWARD) begin
                a_q <= a_i;
                b_q <= b_i;
            end else if (en) begin
                a_q <= a_i;
                b_q <= b_i;
            end else begin
                a_q <= '0;
                b_q <= '0;
            end

            // Accumulate only in active region, not during clear
            if (en && !clr_acc) begin
                acc_q <= next_acc;
                if (TRACK_OVERFLOW && signed_overflow)
                    overflow_q <= 1'b1; // Sticky flag
            end
        end
    end

    assign a_o        = a_q;
    assign b_o        = b_q;
    assign acc_o      = acc_q;
    assign overflow_o = TRACK_OVERFLOW ? overflow_q : 1'b0;

endmodule

`default_nettype wire
