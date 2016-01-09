//=========================================================================
// bsort Sorter Engine Unit
//=========================================================================

`ifndef BSORT_BSORT_UNIT_SORT_V
`define BSORT_BSORT_UNIT_SORT_V

`include "bsort-BsortUnitSortCtrl.v"
`include "bsort-BsortUnitSortDpath.v"

module bsort_BsortUnitSort#( parameter W = 32 )
(
input          clk,
input          reset,

input	       startAddr,
input	       numElem,
input 	       go,

input          bsortreq_val,
output         bsortreq_rdy,
output         bsortresp_val,
input          bsortresp_rdy,

input          addr,
input          numIn,
output         memWriteReq,
input          writeDone
);

// Control signals for sorter unit

wire       a_sel;
wire       a_en;
wire       b_en;
wire       max_sel;
wire	   min_sel;
wire       max_en;
wire       min_en;
wire	   str_sel;
wire       addr_read_en;
wire       addr_write_en;
wire       a_gt_b;

// Instantiate sorter engine control unit

bsort_BsortUnitSortCtrl sortCtrl
(
.clk               (clk),
.reset             (reset),

.bsortreq_val      (bsortreq_val),
.bsortreq_rdy      (bsortreq_rdy),
.bsortresp_val     (bsortresp_val),
.bsortresp_rdy     (bsortresp_rdy),

.startAddr         (startAddr),
.numElem           (numElem),
.go                (go),

.writeDone         (writeDone),

.A_sel             (a_sel),
.A_en              (a_en),
.B_en              (b_en),
.max_sel           (max_sel),
.min_sel           (min_sel),
.max_en            (max_en),
.min_en            (min_en),
.str_sel           (str_sel),
.addr_read_en      (addr_read_en),
.addr_write_en     (addr_write_en),
.a_gt_b            (a_gt_b)
);

// Instantiate sorter engine datapath

bsort_BsortUnitSortDpath#(W) sortDpath
(
.clk               (clk),

.numIn             (numIn),
.addr              (addr),
.memWriteReq       (memWriteReq),

.A_sel             (a_sel),
.A_en              (a_en),
.B_en              (b_en),
.max_sel           (max_sel),
.min_sel           (min_sel),
.max_en            (max_en),
.min_en            (min_en),
.str_sel           (str_sel),
.addr_read_en      (addr_read_en),
.addr_write_en     (addr_write_en),
.a_gt_b            (a_gt_b)
);

endmodule

`endif
