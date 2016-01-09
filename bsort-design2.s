//=========================================================================
// bsort Design 2
//=========================================================================

`ifndef BSORT_DESIGN2_V
`define BSORT_DESIGN2_V

`include "../vc/vc-StateElements.v"

module bsort_design2
#(
parameter ADDR_WIDTH = 16, // byte address to index into all BRAM lines (size of startAddr)
parameter COL_WIDTH = 32 // word wide data (size of numElem and data)
)
(
input                   clk,
input                   reset,

input [ADDR_WIDTH-1:0]  startAddr,
input [COL_WIDTH-1:0]   numElem,
input                   go,
input                   bsortreq_val,
output                  bsortreq_rdy,

output [REQ_MSG_SZ-1:0] memReadRequest,
output                  bsortresp_val,
input                   bsortresp_rdy
);

localparam LEN_WIDTH = 2; // clog2(COL_WIDTH/8)
localparam TYPE_WIDTH = 1;
localparam REQ_MSG_SZ  = TYPE_WIDTH + ADDR_WIDTH + LEN_WIDTH + COL_WIDTH;

wire in_en;
wire msgsSent;

bsort_design2Ctrl ctrl
(
.clk         (clk),
.reset       (reset),
.in_en         (in_en),
.msgsSent      (msgsSent),
.bsortreq_val  (bsortreq_val),
.bsortreq_rdy  (bsortreq_rdy),
.bsortresp_val (bsortresp_val),
.bsortresp_rdy (bsortresp_rdy)
);

bsort_design2Dpath#(ADDR_WIDTH, COL_WIDTH, REQ_MSG_SZ) dpath
(
.clk                (clk),
.go			(go),
.msgsSent           (msgsSent),
.in_en              (in_en),
.startAddr          (startAddr),
.numElem            (numElem),
.memReadRequest	(memReadRequest)
);

//----------------------------------------------------------------------
// Line Trace
//----------------------------------------------------------------------

reg [15:0] num_cycles = 0;
always @( posedge clk ) begin
$write( num_cycles );

// Display input request

if ( ctrl.bsortreq_go ) begin
$write( "go = ", go, " startAddr = ", startAddr, " numElem = ", numElem );
end
else begin
$write( "    ", ".", "             ", "        .", "           ", "       ." );
end

// Display state

case ( ctrl.state_reg )
2'd0    : begin
$write( " (WAIT) " );
end
2'd1    : begin
$write( " (CALC) " );
$write( "go_reg =",dpath.go_reg, " ",
"startAddr_reg =",dpath.startAddr_reg, " ",
"numElem_reg =",dpath.numElem_reg, " ",
"currAddr =",dpath.currAddr, " ",
"count =",dpath.count
);
$write( "\n" );
end
2'd2    : begin
$write( " (DONE) " );
end
default : $write( " (   ?) " );
endcase

// Display output request

if ( ctrl.bsortresp_go ) begin
$write( "memReadRequest =", memReadRequest);
end
else begin
$write( "                ", "           #");
end


$write( "\n" );
num_cycles <= num_cycles + 1;
end


endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module bsort_design2Dpath
#(
parameter ADDR_WIDTH = 16, // byte address to index into all BRAM lines - size of startAddr
parameter COL_WIDTH = 32, // word wide data - size of numElem and data
parameter REQ_MSG_SZ = 41 //1 + ADDR_WIDTH + 2 + COL_WIDTH
)
(
input              clk,
input              go,
input              in_en,

input [ADDR_WIDTH-1:0]  startAddr,
input [COL_WIDTH-1:0]   numElem,

output reg [REQ_MSG_SZ-1:0] memReadRequest,
output reg		      msgsSent
);
reg [ADDR_WIDTH-1:0] currAddr = 16'b0;
reg [COL_WIDTH-1:0] count = 32'b0;

//Store inputs in registers
reg go_reg;
reg [ADDR_WIDTH-1:0] startAddr_reg;
reg [COL_WIDTH-1:0] numElem_reg;

always @ ( posedge clk ) begin
if (in_en) begin
go_reg <= go;
startAddr_reg <= startAddr;
numElem_reg <= numElem;
end
end

always @(posedge clk) begin
if (go_reg && (count == 0)) begin
currAddr <= startAddr_reg;
count <= count + 1'b1;
memReadRequest <= {1'b0, currAddr, 2'b00, 32'hxxxxxxxx};
end
else if (go_reg && (count != numElem_reg)) begin
currAddr <= currAddr + 16'd4;
count <= count + 1'b1;
memReadRequest <= {1'b0, currAddr, 2'b00, 32'hxxxxxxxx};
end
else if (count == numElem_reg) begin
currAddr <= currAddr;
count <= 32'hxxxxxxx;
memReadRequest <= {1'b0, currAddr, 2'b00, 32'hxxxxxxxx};
msgsSent <= 1'b1;
end
end


endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module bsort_design2Ctrl
(
input            clk,
input            reset,

input 	   msgsSent,
output           in_en,
input            bsortreq_val,
output           bsortreq_rdy,
output           bsortresp_val,
input            bsortresp_rdy
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
if ( bsortreq_go ) begin
state_next = STATE_CALC;
end

STATE_CALC:
if ( msgsSent ) begin
state_next = STATE_DONE;
end

STATE_DONE:
if ( bsortresp_go ) begin
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
STATE_CALC: cs = { n,  y,   n };
STATE_DONE: cs = { n,  y,   n };

endcase

end

// Signal Parsing

assign bsortreq_rdy  = cs[2];
assign bsortresp_val = cs[1];
assign in_en         = cs[0];

// Transition Triggers

wire bsortreq_go    = bsortreq_val && bsortreq_rdy;
wire bsortresp_go   = bsortresp_val && bsortresp_rdy;

endmodule

`endif