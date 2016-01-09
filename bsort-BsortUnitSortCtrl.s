//=========================================================================
// bsort Sorter Engine Control
//=========================================================================

`ifndef BSORT_BSORT_UNIT_SORT_CTRL_V
`define BSORT_BSORT_UNIT_SORT_CTRL_V

`include "../vc/vc-StateElements.v"

module bsort_BsortUnitSortCtrl
(
input            clk,
input            reset,

// Dataflow signals
input            bsortreq_val,
output reg       bsortreq_rdy,
output reg       bsortresp_val,
input            bsortresp_rdy,

input            startAddr,
input            numElem,
input            go,

input            writeDone, //DO THIS

// Control signals (ctrl->dpath)
output reg       a_sel,       //Select bit for A mux
output reg       a_en,        // Enable for A register
output reg       b_en,        // Enable for B register
output reg       max_sel,
output reg       min_sel,
output reg       max_en,
output reg       min_en,
output reg       str_sel,
output reg       addr_read_en,
output reg       addr_write_en,

// Control signals (dpath->ctrl)
input            a_gt_b       // Output of greater-than comparator
);

//----------------------------------------------------------------------
// States
//----------------------------------------------------------------------

localparam IDLE       = 4'd0;
localparam INITIAL    = 4'd1;
localparam SET        = 4'd2;
localparam LOADFIRSTA = 4'd3;
localparam LOADB      = 4'd4;
localparam WRITE      = 4'd5;
localparam STOREMIN   = 4'd6;
localparam SETSORTED  = 4'd7;
localparam INCREMENT  = 4'd8;
localparam LOADNEWA   = 4'd9;
localparam STOREMAX   = 4'd10;

reg  [3:0] state_next;
wire [3:0] state;

// State update
vc_RDFF_pf#(4,0) state_pf
(
.clk     (clk),
.reset_p (reset),
.d_p     (state_next),
.q_np    (state)
);

//----------------------------------------------------------------------
// State outputs
//----------------------------------------------------------------------

localparam A_MUX_SEL_X      = 1'dx;
localparam A_MUX_SEL_IN     = 1'd0;
localparam A_MUX_SEL_MAXREG = 1'd1;

localparam MAX_MUX_SEL_X   = 1'dx;
localparam MAX_MUX_SEL_A   = 1'd0;
localparam MAX_MUX_SEL_B   = 1'd1;

localparam MIN_MUX_SEL_X   = 1'dx;
localparam MIN_MUX_SEL_A   = 1'd0;
localparam MIN_MUX_SEL_B   = 1'd1;

localparam STR_MUX_SEL_X   = 1'dx;
localparam STR_MUX_SEL_MAX = 1'd0;
localparam STR_MUX_SEL_MIN = 1'd1;

reg [32:0] max;
reg sorted;
reg [32:0] i;
reg [32:0] count;


always @(*)
begin

// Default control signals
a_sel         = A_MUX_SEL_X;
a_en          = 1'b0;
b_en          = 1'b0;
max_sel       = MAX_MUX_SEL_X; //Take these out?
min_sel       = MIN_MUX_SEL_X;
max_en        = 1'b0;
min_en        = 1'b0;
str_sel       = STR_MUX_SEL_X;
addr_read_en  = 1'b0;
addr_write_en = 1'b0;
bsortreq_rdy  = 1'b0;
bsortresp_val = 1'b0;

case ( state )

IDLE : //technically can be empty
begin
a_sel         = A_MUX_SEL_X;
a_en          = 1'b0;
b_en          = 1'b0;
max_en        = 1'b0;
min_en        = 1'b0;
str_sel       = STR_MUX_SEL_X;
addr_read_en  = 1'b0;
addr_write_en = 1'b0;
end

INITIAL :
begin
max           = (startAddr + numElem) - 1;
sorted        = 1'b0;
end

SET :
begin
sorted        = 1'b1;
i             = startAddr;
count 	      = numElem;
end

LOADFIRSTA :
begin
// Popped off queue here to do memread
a_sel         = A_MUX_SEL_IN;
a_en          = 1'b1;
end

LOADB :
begin
// Popped off queue here to do memread
b_en          = 1'b1;
end

WRITE :
begin
max_en        = 1'b1;
min_en        = 1'b1;
end

STOREMIN :
begin
addr_read_en  = 1'b1;
addr_write_en = 1'b1;
str_sel       = STR_MUX_SEL_MIN;
// Pushed on to queue here to do memwrite
if (writeDone) begin
count = count - 1;
end
end

SETSORTED :
begin
sorted = 1'b0;
end

INCREMENT :
begin
i             = i + 1;
end

LOADNEWA :
begin
a_sel         = A_MUX_SEL_MAXREG;
a_en          = 1'b1;
end

STOREMAX :
begin
addr_read_en  = 1'b1;
addr_write_en = 1'b1;
str_sel       = STR_MUX_SEL_MAX;
// Pushed on to queue here to do memwrite
if (writeDone) begin
count = count - 1;
end
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

IDLE :
begin
if ( go )
state_next = INITIAL;
else
state_next = IDLE;
end

INITIAL :
begin
if ( !sorted )
state_next = SET;
else
state_next = IDLE;
end

SET :
begin
state_next = LOADFIRSTA;
end

LOADFIRSTA :
begin
if ( i <= max )
state_next = LOADB;
else
state_next = SET;
end

LOADB :
begin
state_next = WRITE;
end

WRITE :
begin
state_next = STOREMIN;
end

STOREMIN :
begin
if (a_gt_b)
state_next = SETSORTED;
else
state_next = INCREMENT;
end

SETSORTED:
begin
state_next = INCREMENT;
end

INCREMENT :
begin
if (i < max)
state_next = LOADNEWA;
else
state_next = STOREMAX;
end

LOADNEWA :
begin
state_next = LOADB;
end

STOREMAX:
begin
if (!sorted && count == 0)
state_next = SET;
else
state_next = IDLE;
end

endcase
end

endmodule

`endif
