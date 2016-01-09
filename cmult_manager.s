//=======================================================================
// Top module for cmult tester via UART interface
//=======================================================================

`include "../vc/vc-PulseGen.v"

//`include "./harness-ReqMsg.v"
//`include "./harness-RespMsg.v"
`include "../uart/UART-Manager.v"

//`include "../mtl/mtl-TestSource.v"
//`include "../mtl/mtl-TestSink.v"
//`include "../imuldiv/imuldiv-IntMulDivIterative.v"
`include "../cmult/cmult-ComplexMultiplier.v"
//`include "../cmult/cmult-PipelinedComplexMultiplier-ManQueue.v"
`include "../vc/vc-Queues.v"
`include "../vc/vc-StateElements.v"

module cmult_manager
#(
//parameter CLKFREQ = 66000000 // on-board 66 MHz
parameter CLKFREQ = 200000000 // on-board 200 MHz
)
(
// System
`ifndef SYNTHESIS
input  clk,
`else
input  clkP,
input  clkN,
`endif
input  reset,
input  clk_rst,

// UART
input  USB_1_RTS,
output USB_1_CTS,

input  USB_1_TX,
output USB_1_RX,

// Debug
/*output USER_SMA_GPIO_N,
 output USER_SMA_GPIO_P,
 output FMC_LPC_LA09_N,
 output FMC_LPC_LA09_P,
 output FMC_LPC_LA04_N,
 output FMC_LPC_LA04_P,
 output FMC_LPC_LA03_N,
 output FMC_LPC_LA03_P,
 output FMC_LPC_LA02_N,
 output FMC_LPC_LA02_P,
 output FMC_LPC_LA10_N,
 output FMC_LPC_LA10_P*/

output [7:0] LEDs
);

// Stable high-speed clock generation
`ifdef SYNTHESIS
wire    clk;    // buffered up
wire    clk_se; // single-edge
IBUFGDS clkbufds ( .I  (clkP), .IB (clkN), .O  (clk_se) );
BUFG    clkbuf   ( .I(clk_se), .O(clk) );
//BUFG    clkbuf   ( .I(clkP), .O(clk) );
`endif

// HW/SW controlled (push-button/command)
wire    rst_trig, rst;
wire    clk_rst_trig, clk_reset;

// Four times longer than the slowest clock
localparam rst_cnt = (CLKFREQ / 781250) * 4;
vc_PulseGenMult #( .COUNT(rst_cnt) ) rst_pulse
(
.clk   ( clk      ),
.trig  ( rst_trig ),
.pulse ( rst    )
);

localparam clk_rst_cnt = 4;
vc_PulseGenMult #( .COUNT(clk_rst_cnt) ) clk_rst_pulse
(
.clk   ( clk          ),
.trig  ( clk_rst_trig ),
.pulse ( clk_reset    )
);

//==================================================
// UART Settings
//==================================================

localparam PEVEN = 2'b10;
localparam PODD  = 2'b01;
localparam PNONE = 2'b00;
localparam TNDBITS = 8;
localparam TPARITY = PODD;
localparam TNSBITS = 2;
`ifndef SYNTHESIS
localparam TBDRATE = 250000;
`else
localparam TBDRATE = 781250;
`endif
localparam TMSGLEN = (RESP_MSG_SZ);

// Receiver
localparam RNDBITS = 8;
localparam RPARITY = PODD;
localparam RNSBITS = 2;
`ifndef SYNTHESIS
localparam RBDRATE = 250000;
`else
localparam RBDRATE = 781250;
`endif
localparam RMSGLEN = (REQ_MSG_SZ);

localparam REQ_MSG_SZ = 128; //Created this to replace `HARNESS_REQ_MSG_SZ
localparam RESP_MSG_SZ = 64; //Created this to replace `HARNESS_RESP_MSG_SZ

//==================================================
// UART signals
//==================================================

wire [RESP_MSG_SZ - 1:0] uart_tmsg;
wire 			     uart_in_val;
wire 			     uart_in_rdy;

wire [REQ_MSG_SZ - 1:0]  uart_rmsg;
wire 			     uart_out_val;
wire 			     uart_out_rdy;

//==================================================
// cmult signals
//==================================================

wire [31:0] 	       cmult_op_a;
wire [31:0] 	       cmult_op_b;
wire [31:0] 	       cmult_op_c;
wire [31:0] 	       cmult_op_d;
//   wire 	       cmult_in_val;
//   wire 	       cmult_in_rdy;

wire [31:0] 	       cmult_result_real;
wire [31:0] 	       cmult_result_imag;
//   wire 	       cmult_out_val;
//   wire 	       cmult_out_rdy;

reg [31:0] 	       result_real;
reg [31:0] 	       result_imag;

wire [63:0] 	       cmult_result; // concatenated

//----------------------------------------------------------------------
// Module Connections
//----------------------------------------------------------------------

// Host interface

UART_Manager
#(
.CLKFREQ ( CLKFREQ ),

.TNDBITS ( TNDBITS ),
.TPARITY ( TPARITY ),
.TNSBITS ( TNSBITS ),
.TBDRATE ( TBDRATE ),
.TMSGLEN ( TMSGLEN ),

.RNDBITS ( RNDBITS ),
.RPARITY ( RPARITY ),
.RNSBITS ( RNSBITS ),
.RBDRATE ( RBDRATE ),
.RMSGLEN ( RMSGLEN )
)
uartMgr
(
.clk       ( clk          ),
.reset     ( reset        ),
.clk_reset ( clk_reset    ),

.tdata     ( uart_tmsg    ),
.rdata     ( uart_rmsg    ),

.in_val    ( uart_in_val  ),
.in_rdy    ( uart_in_rdy  ),

.out_val   ( uart_out_val ),
.out_rdy   ( uart_out_rdy ),

.uart_rts  ( USB_1_RTS    ),
.uart_cts  ( USB_1_CTS    ),
.uart_tx   ( USB_1_TX     ),
.uart_rx   ( USB_1_RX     )/*,
                            
                            .d4(FMC_LPC_LA09_N),
                            .d3(FMC_LPC_LA09_P),
                            .d2(FMC_LPC_LA04_N),
                            .d1(FMC_LPC_LA04_P),
                            .d0(FMC_LPC_LA03_N)*/
);
/* Get rid of request harness
 harness_ReqMsgFromBits UartReq
 (
 .bits  ( uart_req_msg   ),
 
 .func  ( uart_req_func  ),
 .addr  ( uart_req_addr  ),
 .value ( uart_req_value )
 );
 */
/* Get rid of response harness
 harness_RespMsgToBits UartResp
 (
 .stat ( uart_resp_stat ),
 .addr ( uart_resp_addr ),
 .calc ( uart_resp_calc ),
 .sink ( uart_resp_sink ),
 
 .bits ( uart_resp_msg  )
 );
 */
// Internal modules

/*
 mtl_TestSource
 #(
 //       .p_msg_sz  ( `IMULDIV_MULDIVREQ_MSG_SZ ),
 .p_msg_sz  ( 128 ),
 .p_mem_sz  ( 256                       ),
 .p_addr_sz ( 8                         ) // sclog2(256)
 )
 TestSource
 (
 .clk     ( clk            ),
 .reset   ( reset          ),
 
 //      .val     ( muldivreq_val  ),
 //      .rdy     ( muldivreq_rdy  ),
 .val     ( cmult_in_val  ),
 .rdy     ( cmult_in_rdy  ),
 .msg     ( source_out_msg ),
 
 .done    ( source_done    ),
 
 .in_wen  ( source_in_wen  ),
 .in_msg  ( source_in_msg  ),
 .in_addr ( source_in_addr ),
 
 .start   ( source_start   )
 );
 
 */


assign cmult_op_a = uart_rmsg[127:96];
assign cmult_op_b = uart_rmsg[95:64];
assign cmult_op_c = uart_rmsg[63:32];
assign cmult_op_d = uart_rmsg[31:0];

/*
 imuldiv_MulDivReqMsgFromBits MulDivReq
 (
 .bits ( source_out_msg   ),
 
 .func ( muldivreq_msg_fn ),
 .a    ( muldivreq_msg_a  ),
 .b    ( muldivreq_msg_b  )
 );
 */

//Unpipelined complex multiplier
cmult_ComplexMultiplier#(32, 4'b0001) cmult
(
.clk(clk),
.reset(reset),

.in0_real(cmult_op_a),
.in0_imag(cmult_op_b),
.in1_real(cmult_op_c),
.in1_imag(cmult_op_d),
.cmultreq_val(uart_out_val),//cmult_in_val
.cmultreq_rdy(uart_out_rdy),//cmult_in_rdy

.out_real(cmult_result_real),
.out_imag(cmult_result_imag),
.cmultresp_val(uart_in_val),//cmult_out_val
.cmultresp_rdy(uart_in_rdy)//cmult_out_rdy
);

/*
 //Pipelined complex multiplier
 
 cmult_PipelinedComplexMultiplier_ManQueue#(32) pipecmult
 (
 .clk(clk),
 .reset(reset),
 
 .in0_real(cmult_op_a),
 .in0_imag(cmult_op_b),
 .in1_real(cmult_op_c),
 .in1_imag(cmult_op_d),
 .cmultreq_val(uart_out_val),//cmult_in_val
 .cmultreq_rdy(uart_out_rdy),//cmult_in_rdy
 
 .out_real(cmult_result_real),
 .out_imag(cmult_result_imag),
 .cmultresp_val(uart_in_val),//cmult_out_val
 .cmultresp_rdy(uart_in_rdy)//cmult_out_rdy
 );
 */

assign uart_tmsg [63:32] = cmult_result_real;
assign uart_tmsg [31:0]  = cmult_result_imag;


/*
 mtl_TestSink
 #(
 .p_msg_sz ( 64  ),
 .p_mem_sz ( 256 ),
 .p_addr_sz( 8   ) // sclog2(256)
 )
 TestSink
 (
 .clk          ( clk  		    ),
 .reset        ( reset		    ),
 
 //      .in_val       ( muldivresp_val        ),
 //      .in_rdy       ( muldivresp_rdy        ),
 //      .msg          ( muldivresp_msg_result ),
 
 .in_val       ( cmult_out_val        ),
 .in_rdy       ( cmult_out_rdy        ),
 .msg          ( cmult_result 	   ),
 
 .out_val      ( uart_in_val           ),
 .out_rdy      ( uart_in_rdy           ),
 .err          ( sink_err              ),
 .err_addr     ( sink_err_addr         ),
 .err_received ( sink_err_received     ),
 .err_expected ( sink_err_expected     ),
 
 .done         ( sink_done  	    ),
 
 .in_wen       ( sink_in_wen	    ),
 .in_msg       ( sink_in_msg	    ),
 .in_addr      ( sink_in_addr	    ),
 
 .start        ( sink_start            )
 );
 */

// ----------------------------------------
// Run demo
// ----------------------------------------

assign LEDs = 8'hFF;

// Synthesizable clog2
function integer sclog2;
input [31:0] value;
begin
value = value - 1;
for (sclog2 = 0; value > 0; sclog2 = sclog2 + 1)
value = value >> 1;
end
endfunction

endmodule