//=========================================================================
// GCD Unit Datpath
//=========================================================================

`ifndef GCD_GCD_UNIT_DPATH_V
`define GCD_GCD_UNIT_DPATH_V

`include "../vc/vc-StateElements.v"
`include "../vc/vc-Muxes.v"

module gcd_GcdUnitDpath#( parameter W = 16 )
(
input          clk,

// Data signals
input  [W-1:0] operands_bits_A,   // Initial operand A
input  [W-1:0] operands_bits_B,   // Initial operand B
output [W-1:0] result_bits_data,  // Final output

// Control signals (ctrl->dpath)
input          A_en,              // Enable for A register
input          B_en,              // Enable for B register
input    [1:0] A_mux_sel,         // Select for mux in front of A reg
input          B_mux_sel,         // Select for mux in front of B reg

// Control signals (dpath->ctrl)
output         B_zero,            // Output of zero comparator
output         A_lt_B             // Output of less-than comparator
);

// A mux

wire [W-1:0] B;
wire [W-1:0] sub_out;
wire [W-1:0] A_mux_out;

vc_Mux3#(W) A_mux
(
.in0 (operands_bits_A),
.in1 (B),
.in2 (sub_out),
.sel (A_mux_sel),
.out (A_mux_out)
);

// A register

wire [W-1:0] A;

vc_EDFF_pf#(W) A_pf
(
.clk  (clk),
.en_p (A_en),
.d_p  (A_mux_out),
.q_np (A)
);

// B mux

wire [W-1:0] B_mux_out;

vc_Mux2#(W) B_mux
(
.in0 (operands_bits_B),
.in1 (A),
.sel (B_mux_sel),
.out (B_mux_out)
);

// B register

vc_EDFF_pf#(W) B_pf
(
.clk  (clk),
.en_p (B_en),
.d_p  (B_mux_out),
.q_np (B)
);

// Arithmetic logic

assign B_zero  = ( B == 0 );
assign A_lt_B  = ( A < B );
assign sub_out = A - B;

// Result is output from A register

assign result_bits_data = A;

endmodule

`endif
