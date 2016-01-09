//=========================================================================
// Test for BsortUnitSort
//=========================================================================

`include "bsort-BsortUnitSort.v"
`include "vc-TestSource.v"
`include "vc-TestSink.v"
`include "vc-Test.v"

//------------------------------------------------------------------------
// Helper Module
//------------------------------------------------------------------------

module bsort_BsortUnitSort_helper
(
input  clk,
input  reset,
output done
);

wire [127:0] src_msg;
wire [31:0] src_msg_a = src_msg[127:96];
wire [31:0] src_msg_b = src_msg[95:64];
wire [31:0] src_msg_c = src_msg[63:32];
wire [31:0] src_msg_d = src_msg[31:0];


wire startAddr;
wire numElements;

integer list[10:0];
assign list[0]=0;
assign list[1]=0;
assign list[2]=0;
assign list[3]=0;
assign list[4]=5;
assign list[5]=2;
assign list[6]=6;
assign list[7]=1;
assign list[8]=3;
assign list[9]=2;
assign list[10]=6;

sum=0;
end

wire        src_val;
wire        src_rdy;
wire        src_done;

wire [42:0] sink_msg;
wire [42:0] memWriteReq;
wire        sink_val;
wire        sink_rdy;
wire        sink_done;

module bsort_BsortUnitSort#( parameter W = 32 )
(

input	       startAddr,
input	       numElements,
input 	       go,


input          addr,
input          numIn,

input          writeDone
);


assign sink_msg = { sink_result_a, sink_result_b, sink_result_c, sink_result_d };

assign done = src_done && sink_done;

vc_TestSource#(128) src
(
.clk   (clk),
.reset (reset),
.msg  (src_msg),
.val   (src_val),
.rdy   (src_rdy),
.done  (src_done)
);

ssort_SsortUnitComb#(32) ssort
(
.clk                (clk),
.reset              (reset),

.ssortreq_msg_a       (src_msg_a),
.ssortreq_msg_b       (src_msg_b),
.ssortreq_msg_c       (src_msg_c),
.ssortreq_msg_d       (src_msg_d),
.ssortreq_val         (src_val),
.ssortreq_rdy         (src_rdy),

.ssortresp_result_a   (sink_result_a),
.ssortresp_result_b   (sink_result_b),
.ssortresp_result_c   (sink_result_c),
.ssortresp_result_d   (sink_result_d),

.ssortresp_val        (sink_val),
.ssortresp_rdy        (sink_rdy)
);

vc_TestSink#(128) sink
(
.clk   (clk),
.reset (reset),
.msg  (sink_msg),
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

`VC_TEST_SUITE_BEGIN( "ssort-SsortUnitComb" )

reg  t0_reset = 1'b1;
wire t0_done;

ssort_SsortUnitComb_helper t0
(
.clk   (clk),
.reset (t0_reset),
.done  (t0_done)
);

`VC_TEST_CASE_BEGIN( 1, "ssort" )
begin

// Test All Equal
t0.src.m[0] = { 32'd0,   32'd0,   32'd0,   32'd0  }; t0.sink.m[0] = { 32'd0,   32'd0,   32'd0,   32'd0  };
t0.src.m[1] = { 32'd7,   32'd7,   32'd7,   32'd7  }; t0.sink.m[1] = { 32'd7,   32'd7,   32'd7,   32'd7  };

// Test 3 Equal
t0.src.m[2] = { 32'd0,   32'd7,   32'd7,   32'd7  }; t0.sink.m[2] = { 32'd7,   32'd7,   32'd7,   32'd0  };
t0.src.m[3] = { 32'd7,   32'd7,   32'd0,   32'd7  }; t0.sink.m[3] = { 32'd7,   32'd7,   32'd7,   32'd0  };

// Test 2 Equal
t0.src.m[4] = { 32'd7,   32'd0,   32'd7,   32'd0  }; t0.sink.m[4] = { 32'd7,   32'd7,   32'd0,   32'd0  };
t0.src.m[5] = { 32'd0,   32'd0,   32'd7,   32'd7  }; t0.sink.m[5] = { 32'd7,   32'd7,   32'd0,   32'd0  };
t0.src.m[6] = { 32'd0,   32'd7,   32'd7,   32'd0  }; t0.sink.m[6] = { 32'd7,   32'd7,   32'd0,   32'd0  };
t0.src.m[7] = { 32'd7,   32'd7,   32'd0,   32'd0  }; t0.sink.m[7] = { 32'd7,   32'd7,   32'd0,   32'd0  };

// Test Comparisons
t0.src.m[8] = { 32'd27,  32'd15,  32'd10,  32'd17 }; t0.sink.m[8] = { 32'd27,  32'd17,  32'd15,  32'd10 };
t0.src.m[9] = { 32'd21,  32'd49,  32'd25,  32'd30 }; t0.sink.m[9] = { 32'd49,  32'd30,  32'd25,  32'd21 };
t0.src.m[10] = { 32'd19,  32'd27,  32'd40,  32'd0  }; t0.sink.m[10] = { 32'd40,  32'd27,  32'd19,  32'd0  };
t0.src.m[11] = { 32'd250, 32'd190, 32'd5,   32'd1  }; t0.sink.m[11] = { 32'd250, 32'd190, 32'd5,   32'd1  };
t0.src.m[12] = { 32'hffffffff, 32'd0, 32'd9, 32'd3 }; t0.sink.m[12] = { 32'hffffffff, 32'd9, 32'd3, 32'd0 };
t0.src.m[13] = { 32'd0, 32'd9, 32'd3, 32'hffffffff }; t0.sink.m[13] = { 32'hffffffff, 32'd9, 32'd3, 32'd0 };

#5;   t0_reset = 1'b1;
#20;  t0_reset = 1'b0;
#1500; `VC_TEST_CHECK( "Is sink finished?", t0_done )

end
`VC_TEST_CASE_END

`VC_TEST_SUITE_END( 1 )

endmodule