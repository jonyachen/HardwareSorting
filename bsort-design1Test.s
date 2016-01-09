//=========================================================================
// Test for bsort-design1.v
//=========================================================================

`include "bsort-design1.v"
`include "vc-TestSource.v"
`include "vc-TestSink.v"
`include "vc-Test.v"

//------------------------------------------------------------------------
// Helper Module
//------------------------------------------------------------------------

module bsort_design1_helper
(
input  clk,
input  reset,
output done
);

wire [40:0] src_msg;
wire go               = src_msg[40];
wire [7:0] startAddr = src_msg[39:32];
wire [31:0] numElem   = src_msg[31:0];

wire        src_val;
wire        src_rdy;
wire        src_done;

wire [42:0] sink_msg;
wire [42:0] memReadRequest;
wire        sink_val;
wire        sink_rdy;
wire        sink_done;

assign sink_msg = memReadRequest;

assign done = src_done && sink_done;

assign go = 1'b1;

vc_TestSource#(41) src
(
.clk   (clk),
.reset (reset),
.msg   (src_msg),
.val   (src_val),
.rdy   (src_rdy),
.done  (src_done)
);

bsort_design1 sortdesign1
(
.clk                (clk),
.reset              (reset),

.startAddr            (startAddr),
.numElem              (numElem),
.go                   (go),
.bsortreq_val         (src_val),
.bsortreq_rdy         (src_rdy),

.memReadRequest    (memReadRequest),
.bsortresp_val        (sink_val),
.bsortresp_rdy        (sink_rdy)
);

vc_TestSink#(43) sink
(
.clk   (clk),
.reset (reset),
.msg   (sink_msg),
.val   (sink_val),
.rdy   (sink_rdy),
.done  (sink_done)
);

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module tester;

// VCD Dump
//initial begin
//  $dumpfile("dump.vcd");
//  $dumpvars;
//end

`VC_TEST_SUITE_BEGIN( "bsort-design1" )

reg  t0_reset = 1'b1;
wire t0_done;

bsort_design1_helper t0
(
.clk   (clk),
.reset (t0_reset),
.done  (t0_done)
);

`VC_TEST_CASE_BEGIN( 1, "bsort" )
begin

t0.src.m[0] = { 1'b1,    8'd3,   32'd4  }; t0.sink.m[0] = { 1'b0,   8'd3,   2'd0,   32'd0  };
t0.sink.m[1] = { 1'b0,   8'd7,   2'd0,   32'd0  };
t0.sink.m[2] = { 1'b0,   8'd11,  2'd0,   32'd0  };
t0.sink.m[3] = { 1'b0,   8'd15,  2'd0,   32'd0  };
//     t0.sink.m[4] = { 1'b0,   8'd19,  2'd0,   32'd0  };
//     t0.sink.m[5] = { 1'b0,   8'd23,  2'd0,   32'd0  };
/*
 t0.src.m[1] = { 1'b1,    8'd5,   32'd3  }; t0.sink.m[4] = { 1'b0,   8'd5,   2'd0,   32'd0  };
 t0.sink.m[5] = { 1'b0,   8'd9,   2'd0,   32'd0  };
 t0.sink.m[6] = { 1'b0,   8'd13,  2'd0,   32'd0  };
 */

#5;   t0_reset = 1'b1;
#20;  t0_reset = 1'b0;
#1500; `VC_TEST_CHECK( "Is sink finished?", t0_done )

end
`VC_TEST_CASE_END

`VC_TEST_SUITE_END( 1 )

endmodule