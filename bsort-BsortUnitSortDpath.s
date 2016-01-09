//=========================================================================
// bsort Sorter Engine Datapath
//=========================================================================

`ifndef BSORT_BSORT_UNIT_SORT_DPATH_V
`define BSORT_BSORT_UNIT_SORT_DPATH_V

`include "../vc/vc-StateElements.v"
`include "../vc/vc-Muxes.v"

module bsort_BsortUnitSortDpath#( parameter W = 32 )
(
input          clk,

// Data signals
input  [W-1:0]     numIn,  // Incoming data
input  [8-1:0]     addr,   // Address where data should be stored
output [43-1:0] memWriteReq,  // Final output - memory write request message - {TYPE, ADDR, LEN, DATA} = bits {1, 8, 2, 32} = 43 bits total

// Control signals (ctrl->dpath)
input          a_sel,             // Select bit for A mux
input          a_en,              // Enable for A register
input          b_en,              // Enable for B register
input          max_sel,
input          min_sel,
input          max_en,
input          min_en,
input          str_sel,
input          addr_read_en,
input          addr_write_en,

// Control signals (dpath->ctrl)
output         a_gt_b             // Output of greater-than comparator
);

// Outputs of datapath (before made into mem request to store back into memory)
wire       numOut; //number to store in memory
wire       writeAddr; //where to store the number in memory

// A mux
wire [W-1:0] maxReg;
wire [W-1:0] a_mux_out;

vc_Mux2#(W) a_mux
(
.in0 (numIn),
.in1 (maxReg),
.sel (a_sel),
.out (a_mux_out)
);

// A register
wire [W-1:0] a;

vc_EDFF_pf#(W) a_reg
(
.clk  (clk),
.en_p (a_en),
.d_p  (a_mux_out),
.q_np (a)
);

// B register
vc_EDFF_pf#(W) B_reg
(
.clk  (clk),
.en_p (b_en),
.d_p  (numIn),
.q_np (b)
);

//Comparator logic
assign a_gt_b  = ( a > b );

/*
 //Comparator
 GTComparator#(W) gt_comparator
 (
 .in0  (a),
 .in1  (b),
 .out  (a_gt_b)
 )
 */

//Assigns select bits for max and min muxes
assign max_sel = !a_gt_b;
assign min_sel = a_gt_b;

// Max mux
wire [W-1:0] max_mux_out;

vc_Mux2#(W) max_mux
(
.in0 (a),
.in1 (b),
.sel (max_sel),
.out (max_mux_out)
);

// Min mux
wire [W-1:0] min_mux_out;

vc_Mux2#(W) min_mux
(
.in0 (a),
.in1 (b),
.sel (min_sel),
.out (min_mux_out)
);

// Max register
vc_EDFF_pf#(W) max_reg
(
.clk  (clk),
.en_p (max_en),
.d_p  (max_mux_out),
.q_np (maxReg)
);

// Min register
wire [W-1:0] minReg;

vc_EDFF_pf#(W) min_reg
(
.clk  (clk),
.en_p (min_en),
.d_p  (min_mux_out),
.q_np (minReg)
);

// Store select mux
vc_Mux2#(W) str_mux
(
.in0 (maxReg),
.in1 (minReg),
.sel (str_sel),
.out (numOut)
);

// Address read register
wire [8-1:0] addr_In;

vc_EDFF_pf#(W) addr_read_reg
(
.clk  (clk),
.en_p (addr_read_reg),
.d_p  (addr),
.q_np (addr_In)
);

// Address write register
vc_EDFF_pf#(W) addr_write_reg
(
.clk  (clk),
.en_p (addr_write_reg),
.d_p  (addr_In),
.q_np (writeAddr)
);

// Need to concatenate the data and address to make a memwrite request - {TYPE, ADDR, LEN, DATA} = bits {1, 8, 2, 32}
assign memWriteReq = {1'b1, writeAddr, 2'b00, numOut};

endmodule

/*
 module GTComparator #( parameter W = 32 )
 // Outputs a one if a > b
 (
 input  [W-1:0] in0,
 input  [W-1:0] in1,
 output         out
 );
 
 assign out = ( in0 > in1 );
 
 endmodule
 */

`endif
