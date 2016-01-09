//=========================================================================
// bsort Fetch Engine
//=========================================================================

`ifndef GCD_GCD_UNIT_CTRL_V
`define GCD_GCD_UNIT_CTRL_V

`include "../vc/vc-StateElements.v"

module gcd_GcdUnitCtrl
(
input            clk,
input            reset,

// Dataflow signals
input            operands_val,
output reg       operands_rdy,
output reg       result_val,
input            result_rdy,

// Control signals (ctrl->dpath)
output reg       A_en,        // Enable for A register
output reg       B_en,        // Enable for B register
output reg [1:0] A_mux_sel,   // Select for mux in front of A register
output reg       B_mux_sel,   // Select for mux in front of B register

// Control signals (dpath->ctrl)
input            B_zero,      // Output of zero comparator
input            A_lt_B       // Output of less-than comparator
);

//----------------------------------------------------------------------
// States
//----------------------------------------------------------------------

localparam WAIT = 2'd0;
localparam CALC = 2'd1;
localparam DONE = 2'd2;

reg  [1:0] state_next;
wire [1:0] state;

vc_RDFF_pf#(2,WAIT) state_pf
(
.clk     (clk),
.reset_p (reset),
.d_p     (state_next),
.q_np    (state)
);

//----------------------------------------------------------------------
// State outputs
//----------------------------------------------------------------------

localparam A_MUX_SEL_X   = 2'dx;
localparam A_MUX_SEL_IN  = 2'd0;
localparam A_MUX_SEL_B   = 2'd1;
localparam A_MUX_SEL_SUB = 2'd2;

localparam B_MUX_SEL_X   = 1'dx;
localparam B_MUX_SEL_IN  = 1'd0;
localparam B_MUX_SEL_A   = 1'd1;

always @(*)
begin

// Default control signals
A_mux_sel    = A_MUX_SEL_X;
A_en         = 1'b0;
B_mux_sel    = B_MUX_SEL_X;
B_en         = 1'b0;
operands_rdy = 1'b0;
result_val   = 1'b0;

case ( state )

WAIT :
begin
A_mux_sel    = A_MUX_SEL_IN;
A_en         = 1'b1;
B_mux_sel    = B_MUX_SEL_IN;
B_en         = 1'b1;
operands_rdy = 1'b1;
end

CALC :
begin
if ( A_lt_B )
begin
A_mux_sel = A_MUX_SEL_B;
A_en      = 1'b1;
B_mux_sel = B_MUX_SEL_A;
B_en      = 1'b1;
end
else if ( !B_zero )
begin
A_mux_sel = A_MUX_SEL_SUB;
A_en      = 1'b1;
end
end

DONE :
begin
result_val = 1'b1;
end

endcase
end

//----------------------------------------------------------------------
// State transitions
//----------------------------------------------------------------------

always @(*)
begin

// Default is to stay in the same state
state_next = state;

case ( state )

WAIT :
if ( operands_val )
state_next = CALC;

CALC :
if ( !A_lt_B && B_zero )
state_next = DONE;

DONE :
if ( result_rdy )
state_next = WAIT;

endcase
end

endmodule

`endif
