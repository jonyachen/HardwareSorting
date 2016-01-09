//=========================================================================
// Simple-Sort Unit Combinational
//=========================================================================

`ifndef SSORT_SSORT_UNIT_COMB_V
`define SSORT_SSORT_UNIT_COMB_V

`include "../ssort/ssort-MaxMinUnit.v"

module ssort_SsortUnitComb
#(
parameter WIDTH = 32
)
(
input              clk,
input              reset,

input  [WIDTH-1:0] ssortreq_msg_a,
input  [WIDTH-1:0] ssortreq_msg_b,
input  [WIDTH-1:0] ssortreq_msg_c,
input  [WIDTH-1:0] ssortreq_msg_d,
input              ssortreq_val,
output             ssortreq_rdy,

output [WIDTH-1:0] ssortresp_result_a,
output [WIDTH-1:0] ssortresp_result_b,
output [WIDTH-1:0] ssortresp_result_c,
output [WIDTH-1:0] ssortresp_result_d,
output             ssortresp_val,
input              ssortresp_rdy
);

wire in_en;

ssort_SsortUnitCtrl ctrl
(
.clk         (clk),
.reset       (reset),
.in_en       (in_en),
.ssortreq_val  (ssortreq_val),
.ssortreq_rdy  (ssortreq_rdy),
.ssortresp_val (ssortresp_val),
.ssortresp_rdy (ssortresp_rdy)
);

ssort_SsortUnitDpath#(WIDTH) dpath
(
.clk                (clk),
.in_en              (in_en),
.ssortreq_msg_a     (ssortreq_msg_a),
.ssortreq_msg_b     (ssortreq_msg_b),
.ssortreq_msg_c     (ssortreq_msg_c),
.ssortreq_msg_d     (ssortreq_msg_d),
.ssortresp_result_a (ssortresp_result_a),
.ssortresp_result_b (ssortresp_result_b),
.ssortresp_result_c (ssortresp_result_c),
.ssortresp_result_d (ssortresp_result_d)
);

//----------------------------------------------------------------------
// Line Trace
//----------------------------------------------------------------------

//reg [15:0] num_cycles = 0;
//always @( posedge clk ) begin
//  $write( num_cycles );

//  // Display input request

//  if ( ctrl.ssortreq_go ) begin
//    $write( ssortreq_msg_a, "-", ssortreq_msg_b, "-", ssortreq_msg_c, "-", ssortreq_msg_d );
//  end
//  else begin
//    $write( "          ", "-", "          " , "-", "          ", "-", "          " );
//  end

//  // Display state

//  case ( ctrl.state_reg )
//    2'd0    : $write( " (WAIT) " );
//    2'd1    : begin
//      $write( " (CALC) " );
//      $write( "\n" );
//      $write( "          ", " ", "          " , " ", "          ", " ", "          ", "        " );
//      $write( "in ",
//              dpath.maxmin_1a.ssortreq_msg_a, "-",
//              dpath.maxmin_1a.ssortreq_msg_b,
//              " out ",
//              dpath.maxmin_1a.ssortresp_msg_max, "-",
//              dpath.maxmin_1a.ssortresp_msg_min
//            );
//      $write( "\n" );
//      $write( "          ", " ", "          " , " ", "          ", " ", "          ", "        " );
//      $write( "in ",
//              dpath.maxmin_1b.ssortreq_msg_a, "-",
//              dpath.maxmin_1b.ssortreq_msg_b,
//              " out ",
//              dpath.maxmin_1b.ssortresp_msg_max, "-",
//              dpath.maxmin_1b.ssortresp_msg_min
//            );
//      $write( "\n" );
//      $write( "          ", " ", "          " , " ", "          ", " ", "          ", "        " );
//      $write( "in ",
//              dpath.maxmin_2a.ssortreq_msg_a, "-",
//              dpath.maxmin_2a.ssortreq_msg_b,
//              " out ",
//              dpath.maxmin_2a.ssortresp_msg_max, "-",
//              dpath.maxmin_2a.ssortresp_msg_min
//            );
//      $write( "\n" );
//      $write( "          ", " ", "          " , " ", "          ", " ", "          ", "        " );
//      $write( "in ",
//              dpath.maxmin_2b.ssortreq_msg_a, "-",
//              dpath.maxmin_2b.ssortreq_msg_b,
//              " out ",
//              dpath.maxmin_2b.ssortresp_msg_max, "-",
//              dpath.maxmin_2b.ssortresp_msg_min
//            );
//      $write( "\n" );
//      $write( "          ", " ", "          " , " ", "          ", " ", "          ", "        " );
//      $write( "in ",
//              dpath.maxmin_3a.ssortreq_msg_a, "-",
//              dpath.maxmin_3a.ssortreq_msg_b,
//              " out ",
//              dpath.maxmin_3a.ssortresp_msg_max, "-",
//              dpath.maxmin_3a.ssortresp_msg_min
//            );
//
//    end
//    2'd2    : $write( " (DONE) " );
//    default : $write( " (   ?) " );
//  endcase

//  // Display output request

//  if ( ctrl.ssortresp_go ) begin
//    $write( ssortresp_result_a, " ", ssortresp_result_b, " ", ssortresp_result_c, " ", ssortresp_result_d );
//  end

//  $write( "\n" );
//  num_cycles <= num_cycles + 1;
//end

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module ssort_SsortUnitDpath
#(
parameter WIDTH = 32
)
(
input              clk,
input              in_en,

// Data signals

input  [WIDTH-1:0] ssortreq_msg_a,         // Initial operand A
input  [WIDTH-1:0] ssortreq_msg_b,         // Initial operand B
input  [WIDTH-1:0] ssortreq_msg_c,         // Initial operand C
input  [WIDTH-1:0] ssortreq_msg_d,         // Initial operand D

output [WIDTH-1:0] ssortresp_result_a,   // Final output A
output [WIDTH-1:0] ssortresp_result_b,   // Final output B
output [WIDTH-1:0] ssortresp_result_c,   // Final output C
output [WIDTH-1:0] ssortresp_result_d    // Final output D
);

//----------------------------------------------------------------------
// Sequential Logic
//----------------------------------------------------------------------

reg [WIDTH-1:0] a_reg;
reg [WIDTH-1:0] b_reg;
reg [WIDTH-1:0] c_reg;
reg [WIDTH-1:0] d_reg;

always @ ( posedge clk ) begin
if (in_en) begin
a_reg <= ssortreq_msg_a;
b_reg <= ssortreq_msg_b;
c_reg <= ssortreq_msg_c;
d_reg <= ssortreq_msg_d;
end
end

//----------------------------------------------------------------------
// Combinational Logic
//----------------------------------------------------------------------

// 1st stage
wire [WIDTH-1:0] maxmin_1a_max;
wire [WIDTH-1:0] maxmin_1a_min;
wire [WIDTH-1:0] maxmin_1b_max;
wire [WIDTH-1:0] maxmin_1b_min;

ssort_MaxMinUnit#(WIDTH) maxmin_1a
(
.ssortreq_msg_a    (a_reg),
.ssortreq_msg_b    (b_reg),
.ssortresp_msg_max (maxmin_1a_max),
.ssortresp_msg_min (maxmin_1a_min)
);

ssort_MaxMinUnit#(WIDTH) maxmin_1b
(
.ssortreq_msg_a    (c_reg),
.ssortreq_msg_b    (d_reg),
.ssortresp_msg_max (maxmin_1b_max),
.ssortresp_msg_min (maxmin_1b_min)
);

// 2nd stage
wire [WIDTH-1:0] maxmin_2a_max;
wire [WIDTH-1:0] maxmin_2a_min;
wire [WIDTH-1:0] maxmin_2b_max;
wire [WIDTH-1:0] maxmin_2b_min;

ssort_MaxMinUnit#(WIDTH) maxmin_2a
(
.ssortreq_msg_a    (maxmin_1a_max),
.ssortreq_msg_b    (maxmin_1b_max),
.ssortresp_msg_max (maxmin_2a_max),
.ssortresp_msg_min (maxmin_2a_min)
);

ssort_MaxMinUnit#(WIDTH) maxmin_2b
(
.ssortreq_msg_a    (maxmin_1a_min),
.ssortreq_msg_b    (maxmin_1b_min),
.ssortresp_msg_max (maxmin_2b_max),
.ssortresp_msg_min (maxmin_2b_min)
);

// 3rd stage
wire [WIDTH-1:0] maxmin_3a_max;
wire [WIDTH-1:0] maxmin_3a_min;

ssort_MaxMinUnit#(WIDTH) maxmin_3a
(
.ssortreq_msg_a    (maxmin_2a_min),
.ssortreq_msg_b    (maxmin_2b_max),
.ssortresp_msg_max (maxmin_3a_max),
.ssortresp_msg_min (maxmin_3a_min)
);

// Result
assign ssortresp_result_a = maxmin_2a_max;
assign ssortresp_result_b = maxmin_3a_max;
assign ssortresp_result_c = maxmin_3a_min;
assign ssortresp_result_d = maxmin_2b_min;

endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module ssort_SsortUnitCtrl
(
input            clk,
input            reset,

// Dataflow signals
output           in_en,
input            ssortreq_val,
output           ssortreq_rdy,
output           ssortresp_val,
input            ssortresp_rdy
);

//----------------------------------------------------------------------
// State Definitions
//----------------------------------------------------------------------

localparam STATE_WAIT = 2'd0;
localparam STATE_CALC = 2'd1;
localparam STATE_DONE = 2'd2;

//----------------------------------------------------------------------
// State Update
//----------------------------------------------------------------------

always @ ( posedge clk ) begin
if ( reset ) begin
state_reg <= STATE_WAIT;
end
else begin
state_reg <= state_next;
end
end

//----------------------------------------------------------------------
// State Transitions
//----------------------------------------------------------------------

reg  [1:0] state_reg;
reg  [1:0] state_next;

always @ ( * ) begin

state_next = state_reg;

case ( state_reg )

STATE_WAIT:
if ( ssortreq_go ) begin
state_next = STATE_CALC;
end

STATE_CALC:
if ( is_calc_done ) begin
state_next = STATE_DONE;
end

STATE_DONE:
if ( ssortresp_go ) begin
state_next = STATE_WAIT;
end

endcase

end

//----------------------------------------------------------------------
// Control Definitions
//----------------------------------------------------------------------

localparam n      = 1'd0;
localparam y      = 1'd1;

//----------------------------------------------------------------------
// Output Control Signals
//----------------------------------------------------------------------

localparam cs_size = 3;
reg [cs_size-1:0] cs;

always @ ( * ) begin

case ( state_reg )

//                 req resp in
//                 rdy val  en
STATE_WAIT: cs = { y,  n,   y };
STATE_CALC: cs = { n,  n,   n };
STATE_DONE: cs = { n,  y,   n };

endcase

end

// Signal Parsing

assign ssortreq_rdy  = cs[2];
assign ssortresp_val = cs[1];
assign in_en         = cs[0];

// Transition Triggers

wire ssortreq_go    = ssortreq_val && ssortreq_rdy;
wire ssortresp_go   = ssortresp_val && ssortresp_rdy;
wire is_calc_done = 1'b1;

endmodule

`endif