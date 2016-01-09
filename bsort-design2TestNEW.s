//=========================================================================
// Test for bsort-design2.v
//=========================================================================

`include "bsort-design2.v"
`include "vc-TestSource.v"
`include "vc-TestSink.v"
`include "vc-Test.v"
`include "vc-TestSinglePortMem.v"

`include "vc-TestRandDelaySource.v"
`include "vc-TestRandDelaySink.v"

//------------------------------------------------------------------------
// Test Harness - t0 (For writing data to memory)
//------------------------------------------------------------------------

module TestHarness
#(
parameter p_mem_sz  = 1024,    // size of physical memory in bytes
parameter p_addr_sz = 16,       // size of mem message address in bits
parameter p_data_sz = 32,      // size of mem message data in bits
parameter p_src_max_delay = 0, // max random delay for source
parameter p_sink_max_delay = 0 // max random delay for sink
)(
input  clk,
input  reset,
output done0
);

// Local parameters

localparam c_req_msg_sz  = `VC_MEM_REQ_MSG_SZ(p_addr_sz,p_data_sz);
localparam c_resp_msg_sz = `VC_MEM_RESP_MSG_SZ(p_data_sz);

// Test source

wire                    memreq_val;
wire                    memreq_rdy;
wire [c_req_msg_sz-1:0] memreq_msg;

wire                    src_done;

vc_TestRandDelaySource#(c_req_msg_sz,1024,p_src_max_delay) src0
(
.clk         (clk),
.reset       (reset),

.val         (memreq_val),
.rdy         (memreq_rdy),
.msg         (memreq_msg),

.done        (src_done)
);

// Test memory

wire                     memresp_val;
wire                     memresp_rdy;
wire [c_resp_msg_sz-1:0] memresp_msg;

vc_TestSinglePortMem#(p_mem_sz,p_addr_sz,p_data_sz) mem
(
.clk         (clk),
.reset       (reset),

.memreq_val  (memreq_val),
.memreq_rdy  (memreq_rdy),
.memreq_msg  (memreq_msg),

.memresp_val (memresp_val),
.memresp_rdy (memresp_rdy),
.memresp_msg (memresp_msg)
);

// Test sink

wire sink_done;

vc_TestRandDelaySink#(c_resp_msg_sz,1024,p_sink_max_delay) sink0
(
.clk   (clk),
.reset (reset),

.val   (memresp_val),
.rdy   (memresp_rdy),
.msg   (memresp_msg),

.done  (sink_done)
);


// Done when both source and sink are done

assign done0 = src_done & sink_done;

endmodule

//------------------------------------------------------------------------
// Test harness - t1 (for doing actual Fetch Engine stuff)
//------------------------------------------------------------------------
module bsort_design2_helper
(
input  clk,
input  reset,
output done1
);

wire [48:0] src_msg;
wire go              = src_msg[48];
wire [15:0] startAddr = src_msg[47:32];
wire [31:0] numElem  = src_msg[31:0];

wire        src_val;
wire        src_rdy;
wire        src_done;

wire [34:0] sink_msg;
wire [50:0] memReadRequest;
wire        sink_val;
wire        sink_rdy;
wire        sink_done;

wire [34:0]memReadResponse;

vc_TestSource#(49) src1
(
.clk   (clk),
.reset (reset),
.msg   (src_msg),
.val   (src_val),
.rdy   (src_rdy),
.done  (src_done)
);

wire bsortresp_val_wire;
wire bsortresp_rdy_wire;



bsort_design2#(16, 32) sortdesign2
(
.clk                (clk),
.reset              (reset),

.startAddr            (startAddr),
.numElem              (numElem),
.go                   (go),
.bsortreq_val         (src_val),
.bsortreq_rdy         (src_rdy),

.memReadRequest       (memReadRequest),
.bsortresp_val        (bsortresp_val_wire),
.bsortresp_rdy        (bsortresp_rdy_wire)
);



vc_TestSinglePortMem #(1024, 16, 32) mem
(
.clk                  (clk),
.reset                (reset),

//Memory request interface
.memreq_val           (bsortresp_val_wire),
.memreq_rdy           (bsortresp_rdy_wire),
.memreq_msg           (memReadRequest),

//Memory response interface
.memresp_val          (sink_val),
.memresp_rdy          (sink_rdy),
.memresp_msg          (memReadResponse)
);

assign sink_msg = memReadResponse;

//Make sure to check/change bits below
vc_TestSink#(35) sink1
(
.clk   (clk),
.reset (reset),
.msg   (sink_msg),
.val   (sink_val),
.rdy   (sink_rdy),
.done  (sink_done)
);

assign done1 = src_done && sink_done;

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

`VC_TEST_SUITE_BEGIN( "bsort-design2" )



//----------------------------------------------------------------------
// localparams
//----------------------------------------------------------------------

localparam c_req_rd  = `VC_MEM_REQ_MSG_TYPE_READ;
localparam c_req_wr  = `VC_MEM_REQ_MSG_TYPE_WRITE;

localparam c_resp_rd = `VC_MEM_RESP_MSG_TYPE_READ;
localparam c_resp_wr = `VC_MEM_RESP_MSG_TYPE_WRITE;

//----------------------------------------------------------------------
// TestDesign2 - writing to mem
//----------------------------------------------------------------------

wire t0_done;
reg  t0_reset = 1;


TestHarness
#(
.p_mem_sz         (1024),
.p_addr_sz        (16),
.p_data_sz        (32),
.p_src_max_delay  (0),
.p_sink_max_delay (0)
) t0
(
.clk   (clk),
.reset (t0_reset),
.done0  (t0_done)
);

// Helper tasks

reg [`VC_MEM_REQ_MSG_SZ(16,32)-1:0] t0_req;
reg [`VC_MEM_RESP_MSG_SZ(32)-1:0]   t0_resp;

task t0_mk_req_resp
(
input [1023:0] index,

input [`VC_MEM_REQ_MSG_TYPE_SZ(16,32)-1:0] req_type,
input [`VC_MEM_REQ_MSG_ADDR_SZ(16,32)-1:0] req_addr,
input [`VC_MEM_REQ_MSG_LEN_SZ(16,32)-1:0]  req_len,
input [`VC_MEM_REQ_MSG_DATA_SZ(16,32)-1:0] req_data,

input [`VC_MEM_RESP_MSG_TYPE_SZ(32)-1:0]   resp_type,
input [`VC_MEM_RESP_MSG_LEN_SZ(32)-1:0]    resp_len,
input [`VC_MEM_RESP_MSG_DATA_SZ(32)-1:0]   resp_data
);
begin
t0_req[`VC_MEM_REQ_MSG_TYPE_FIELD(16,32)] = req_type;
t0_req[`VC_MEM_REQ_MSG_ADDR_FIELD(16,32)] = req_addr;
t0_req[`VC_MEM_REQ_MSG_LEN_FIELD(16,32)]  = req_len;
t0_req[`VC_MEM_REQ_MSG_DATA_FIELD(16,32)] = req_data;

t0_resp[`VC_MEM_RESP_MSG_TYPE_FIELD(32)]  = resp_type;
t0_resp[`VC_MEM_RESP_MSG_LEN_FIELD(32)]   = resp_len;
t0_resp[`VC_MEM_RESP_MSG_DATA_FIELD(32)]  = resp_data;


t0.src0.src.m[index]   = t0_req;
t0.sink0.sink.m[index] = t0_resp;
end
endtask


// Actual test case

//initial begin
//$dumpfile("dump.vcd");
//$dumpvars;
//end


`VC_TEST_CASE_BEGIN( 1, "TestDesign2 - writing to mem" )
begin

//                  ----------- memory request -----------  ------ memory response ------
//              idx type      addr      len   data          type       len   data

//t0.mem.m[0] = {1'b1, 16'h0003, 2'd0, 32'h00000005};
//t0.mem.m[8'd0][ (2'b11*8) + (32'h00000000)*8]  = 32'h00000005[ (32'h00000000*8) ];
t0.mem.m[8'd0] = 32'h05234235; // write word x0003
t0.mem.m[8'd1] = 32'h02000002; // write word x0007
t0.mem.m[8'd2] = 32'h01000001; // write word x000B
t0.mem.m[8'd3] = 32'h04000004; // write word x000F
//m[physical_block_addr_M][ (block_offset_M*8) + (wr_i*8) +: 8 ] <= memreq_msg_data_M[ (wr_i*8) +: 8 ];

#100;

//t0_mk_req_resp( 0,  c_req_wr, 16'h0003, 2'd0, 32'h00000005, c_resp_wr, 2'd0, 32'h???????? ); // write word  0x0003
//t0_mk_req_resp( 1,  c_req_wr, 16'h0007, 2'd0, 32'h00000002, c_resp_wr, 2'd0, 32'h???????? ); // write word  0x0007
//t0_mk_req_resp( 2,  c_req_wr, 16'h000B, 2'd0, 32'h00000001, c_resp_wr, 2'd0, 32'h???????? ); // write word  0x000B (11)
//t0_mk_req_resp( 3,  c_req_wr, 16'h000F, 2'd0, 32'h00000004, c_resp_wr, 2'd0, 32'h???????? ); // write word  0x000F (15)

t0_mk_req_resp( 0,  c_req_rd, 16'h0003, 2'd0, 32'hxxxxxxxx, c_resp_rd, 2'd0, 32'h00000005 ); // read  word  0x0003
t0_mk_req_resp( 1,  c_req_rd, 16'h0007, 2'd0, 32'hxxxxxxxx, c_resp_rd, 2'd0, 32'h00000002 ); // read  word  0x0007
t0_mk_req_resp( 2,  c_req_rd, 16'h000B, 2'd0, 32'hxxxxxxxx, c_resp_rd, 2'd0, 32'h00000001 ); // read  word  0x000B
t0_mk_req_resp( 3,  c_req_rd, 16'h000F, 2'd0, 32'hxxxxxxxx, c_resp_rd, 2'd0, 32'h00000004 ); // read  word  0x000F

#1;   t0_reset = 1'b1;
#20;  t0_reset = 1'b0;
#500; `VC_TEST_CHECK( "Is sink finished?", t0_done )

end
`VC_TEST_CASE_END



//----------------------------------------------------------------------
// TestDesign2 - Fetch Engine
//----------------------------------------------------------------------


reg  t1_reset = 1'b1;
wire t1_done;

bsort_design2_helper t1
(
.clk   (clk),
.reset (t1_reset),
.done1  (t1_done)
);

`VC_TEST_CASE_BEGIN( 2, "TestDesign2 - Fetch Engine" )
begin

//t1.src1.m[0] = { 1'b1,    16'd3,   32'd4  }; t1.sink1.m[0] = { 1'b0,   16'd3,   2'd0,   32'd0  };
//t1.sink1.m[1] = { 1'b0,   16'd7,   2'd0,   32'd0  };
//t1.sink1.m[2] = { 1'b0,   16'd11,  2'd0,   32'd0  };
//t1.sink1.m[3] = { 1'b0,   16'd15,  2'd0,   32'd0  };

t1.src1.m[0] =  { 1'b1,    16'd3,   32'd4  }; t1.sink1.m[0] = { 1'b0,   2'd0,   32'd5  };
t1.sink1.m[1] = { 1'b0,   2'd0,   32'd2  };
t1.sink1.m[2] = { 1'b0,   2'd0,   32'd1  };
t1.sink1.m[3] = { 1'b0,   2'd0,   32'd4  };

//     t1.sink.m[4] = { 1'b0,   8'd19,  2'd0,   32'd0  };
//     t1.sink.m[5] = { 1'b0,   8'd23,  2'd0,   32'd0  };

// t1.src.m[1] = { 1'b1,    8'd5,   32'd3  }; t1.sink.m[4] = { 1'b0,   8'd5,   2'd0,   32'd0  };
// t1.sink.m[5] = { 1'b0,   8'd9,   2'd0,   32'd0  };
// t1.sink.m[6] = { 1'b0,   8'd13,  2'd0,   32'd0  };


#5;   t1_reset = 1'b1;
#20;  t1_reset = 1'b0;
#1500; `VC_TEST_CHECK( "Is sink finished?", t1_done )

end
`VC_TEST_CASE_END


//`VC_TEST_SUITE_END( 1 )

`VC_TEST_SUITE_END( 2 )

endmodule