//=========================================================================
// GCD Unit
//=========================================================================

`ifndef GCD_GCD_UNIT_V
`define GCD_GCD_UNIT_V

`include "gcd-GcdUnitCtrl.v"
`include "gcd-GcdUnitDpath.v"

module gcd_GcdUnit#( parameter W = 16 )
(
input          clk,
input          reset,

input  [W-1:0] operands_bits_A,
input  [W-1:0] operands_bits_B,
input          operands_val,
output         operands_rdy,

output [W-1:0] result_bits_data,
output         result_val,
input          result_rdy
);

// Control signals

wire       B_zero;
wire       A_lt_B;
wire       A_en;
wire       B_en;
wire [1:0] A_mux_sel;
wire       B_mux_sel;

// Instantiate control unit

gcd_GcdUnitCtrl ctrl
(
.clk               (clk),
.reset             (reset),

.operands_val      (operands_val),
.operands_rdy      (operands_rdy),
.result_val        (result_val),
.result_rdy        (result_rdy),

.A_en              (A_en),
.B_en              (B_en),
.A_mux_sel         (A_mux_sel),
.B_mux_sel         (B_mux_sel),
.B_zero            (B_zero),
.A_lt_B            (A_lt_B)
);

// Instantiate datapath

gcd_GcdUnitDpath#(W) dpath
(
.clk               (clk),

.operands_bits_A   (operands_bits_A),
.operands_bits_B   (operands_bits_B),
.result_bits_data  (result_bits_data),

.A_en              (A_en),
.B_en              (B_en),
.A_mux_sel         (A_mux_sel),
.B_mux_sel         (B_mux_sel),
.B_zero            (B_zero),
.A_lt_B            (A_lt_B)
);

endmodule

`endif
