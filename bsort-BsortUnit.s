//=========================================================================
// bsort Unit
//=========================================================================

`ifndef BSORT_BSORT_UNIT_V
`define BSORT_BSORT_UNIT_V

`include "bsort-BsortUnitSort.v"
`include "bsort-BsortUnitFetch.v"

module bsort_BsortUnit#( parameter W = 32 )
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

output         memReadReqOut,
input          memReadRespIn,

output         memWriteReqOut,
input          memWriteResp

);

// Signals for sorter unit
wire       addrOut; //input - address
wire       memReadRespOut;  //input - data to be sorted
wire       memWriteReqIn;  //output - sorted data to be stored

//Signals for fetch engine
wire	   memReadReqIn; //output of fetch engine - address
wire       addrIn;
;

// Instantiate sorter engine

bsort_BsortUnitSort sorterEngine
(
.clk               (clk),
.reset             (reset),

.bsortreq_val      (bsortreq_val),
.bsortreq_rdy      (bsortreq_rdy),
.bsortresp_val     (bsortresp_val),
.bsortresp_rdy     (bsortresp_rdy),

.startAddr	   (startAddr),
.numElements       (numElem),
.go  	           (go),

.addr              (addrOut),
.numIn             (memReadRespOut),
.memWriteReq       (memWriteReqIn),
.writeDone         (memWriteResp)
);

// Instantiate fetch engine

bsort_BsortUnitFetch fetchEngine
(
.clk               (clk),
.reset             (reset),

.bsortreq_val      (bsortreq_val),
.bsortreq_rdy      (bsortreq_rdy),
.bsortresp_val     (bsortresp_val),
.bsortresp_rdy     (bsortresp_rdy),

.startAddr	   (startAddr),
.numElements       (numElem),
.go  	           (go),

.addrIn	           (addrIn),
.memReadReqIn	   (memReadReqIn)
);

endmodule

`endif
