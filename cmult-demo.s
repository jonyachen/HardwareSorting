//=======================================================================
// Top module for GCD/peripherals demo
//=======================================================================

`include "../uart/UART-Manager.v"
`include "../vc/vc-PulseGen.v"
//`include "../gcd/gcd-GcdUnit.v"
`include "../cmult/cmult-ComplexMultiplier.v"
//`include "../cmult/cmult-PipelinedComplexMultiplier-ManQueue.v"
//`include "../cmult/cmult-PipelinedComplexMultiplier.v"
`include "../vc/vc-Queues.v"
`include "../vc/vc-StateElements.v"
`include "../lcd/LCD-Manager.v"
`include "./ByteToDec.v"

module cmult_demo
(
// System
input 	clk,
input 	reset,
input 	clk_reset,

// GCD
//   output [7:0] result_bits,
//   output 	gcd_in_rdy,
//   output 	gcd_out_val,

// CMULT
output [7:0] result_real_bits,
output [7:0] result_imag_bits,
output 	 cmult_in_rdy,
output 	 cmult_out_val,

// UART
input 	USB_1_RTS,
output 	USB_1_CTS,

input 	USB_1_TX,
output 	USB_1_RX,

// LCD
input 	redraw,

output 	lcd_rs,
output [3:0] lcd_db,
output 	lcd_rw,
output 	lcd_e,

// Debug
output 	USER_SMA_GPIO_N,
output 	USER_SMA_GPIO_P,

output [7:0] LEDs
);

// UART Settings

localparam PEVEN = 2'b10;
localparam PODD  = 2'b01;
localparam PNONE = 2'b00;

localparam NDBITS = 8;
localparam PARITY = PODD;
localparam NSBITS = 2;

localparam BDRATE = 300;
localparam NDMSGS = 2; // 8-bit input as int + '\0'
localparam MSG_SZ = NDBITS * NDMSGS;
localparam MSG_MD = (NDMSGS == 1) ? 0 : 1;

// UART signals

wire 	uart_in_val;
wire 	uart_in_rdy;
wire [MSG_SZ - 1:0] uart_tmsg;

wire 	       uart_out_val;
wire 	       uart_out_rdy;
wire [MSG_SZ - 1:0] uart_rmsg;

/*   // GCD signals
 
 reg [7:0] 	       gcd_op_a;
 reg [7:0] 	       gcd_op_b;
 wire 	       gcd_in_val;
 wire 	       gcd_in_rdy;
 
 wire [7:0]          gcd_result;
 wire 	       gcd_out_val;
 wire 	       gcd_out_rdy;
 
 reg [7:0] 	       result;
 */

// CMULT signals

reg [7:0] 	       cmult_op_a;
reg [7:0] 	       cmult_op_b;
reg [7:0] 	       cmult_op_c;
reg [7:0] 	       cmult_op_d;
wire 	       cmult_in_val;
wire 	       cmult_in_rdy;

wire [7:0] 	       cmult_result_real;
wire [7:0] 	       cmult_result_imag;
wire 	       cmult_out_val;
wire 	       cmult_out_rdy;

reg [7:0] 	       result_real;
reg [7:0] 	       result_imag;



//----------------------------------------------------------------------
// Module Connections
//----------------------------------------------------------------------

UART_Manager
#(
.NDBITS(NDBITS),
.PARITY(PARITY),
.NSBITS(NSBITS),
.BDRATE(BDRATE),

.NDMSGS(NDMSGS),
.MSG_SZ(MSG_SZ),
.MSG_MD(MSG_MD)
)
uartMgr
(
.clk(clk),
.reset(reset),
.clk_reset(clk_reset),

.tdata(uart_tmsg),
.rdata(uart_rmsg),

.in_val(uart_in_val),
.in_rdy(uart_in_rdy),

.out_val(uart_out_val),
.out_rdy(uart_out_rdy),

.uart_rts(USB_1_RTS),
.uart_cts(USB_1_CTS),
.uart_tx(USB_1_TX),
.uart_rx(USB_1_RX)
);

/*   gcd_GcdUnit
 #(
 .W(8)
 )
 gcdUnit
 (
 .clk(clk),
 .reset(reset),
 
 .operands_bits_A(gcd_op_a),
 .operands_bits_B(gcd_op_b),
 .operands_val(gcd_in_val),
 .operands_rdy(gcd_in_rdy),
 
 .result_bits_data(gcd_result),
 .result_val(gcd_out_val),
 .result_rdy(gcd_out_rdy)
 );
 */


cmult_ComplexMultiplier#(8, 4'b0001) cmult
(
.clk(clk),
.reset(reset),

.in0_real(cmult_op_a),
.in0_imag(cmult_op_b),
.in1_real(cmult_op_c),
.in1_imag(cmult_op_d),
.cmultreq_val(cmult_in_val),
.cmultreq_rdy(cmult_in_rdy),

.out_real(cmult_result_real),
.out_imag(cmult_result_imag),
.cmultresp_val(cmult_out_val),
.cmultresp_rdy(cmult_out_rdy)
);

wire 	       redraw_pulse;

vc_PulseGenSing pushbutton_redraw
(
.clk         (clk),
.trigger     (redraw),
.pulse       (redraw_pulse)
);

wire [(16 * 8) - 1:0] sbits;
wire [(3 * 8) - 1:0]  abits;
wire [(3 * 8) - 1:0]  bbits;
wire [(3 * 8) - 1:0]  cbits;

LCD_Manager lcdMgr
(
.clk       (clk),
.reset     (reset),
.clk_reset (clk_reset),
.redraw    (redraw_pulse),

.status    (sbits),
.a         (abits),
.b         (bbits),
.c         (cbits),

.lcd_rs    (lcd_rs),
.lcd_db    (lcd_db),
.lcd_rw    (lcd_rw),
.lcd_e     (lcd_e)
);


// ----------------------------------------
// Run demo
// ----------------------------------------
/*
 // State definitions
 
 localparam STATE_RECA = 0; // waiting for A
 localparam STATE_RECB = 1; // waiting for B
 localparam STATE_INIT = 2; // sending A and B
 localparam STATE_CALC = 3; // calculating C
 localparam STATE_SEND = 4; // transmitting
 localparam STATE_DONE = 5; // done
 */

// State definitions

localparam STATE_RECA = 0; // waiting for A
localparam STATE_RECB = 1; // waiting for B
localparam STATE_RECC = 2; // waiting for C
localparam STATE_RECD = 3; // waiting for D
localparam STATE_INIT = 4; // sending A, B, C, and D
localparam STATE_CALC = 5; // calculating two outputs, E and F
localparam STATE_SEND = 6; //transmitting
//   localparam STATE_SENDREAL = 6; // transmitting E (real)
//   localparam STATE_SENDIMAG = 7; // transmitting F (imag)
localparam STATE_DONE = 7; // done

// Internal state

reg [3:0] 		 state;

// Other state

// State update

always @ (posedge clk)
begin
if (reset)
begin
state <= STATE_RECA;

cmult_op_a <= 0;
cmult_op_b <= 0;
cmult_op_c <= 0;
cmult_op_d <= 0;
result_real <= 0;
result_imag <= 0;
end
else
begin
state <= state_next;

cmult_op_a <= a_next;
cmult_op_b <= b_next;
cmult_op_c <= c_next;
cmult_op_d <= d_next;
result_real <= result_real_next;
result_imag <= result_imag_next;
end
end // always @ (posedge clk)

// State transitions

reg [3:0] state_next;

reg [7:0] a_next;
reg [7:0] b_next;
reg [7:0] c_next;
reg [7:0] d_next;
reg [7:0] result_real_next;
reg [7:0] result_imag_next;

reg [7:0] LEDs_signals;
reg [MSG_SZ - 1:0] tmsg;

always @ (*)
begin
state_next = state;

a_next = cmult_op_a;
b_next = cmult_op_b;
c_next = cmult_op_c;
d_next = cmult_op_d;
result_real_next = result_real;
result_imag_next = result_imag;

case (state)
STATE_RECA:
if (recvd_a)
begin
LEDs_signals = 8'b00000001;
a_next = uart_rmsg[7:0];
state_next = STATE_RECB;
end

STATE_RECB:
if (recvd_b)
begin
LEDs_signals = 8'b00000010;
b_next = uart_rmsg[7:0];
state_next = STATE_RECC;
end

STATE_RECC:
if (recvd_c)
begin
LEDs_signals = 8'b00000100;
c_next = uart_rmsg[7:0];
state_next = STATE_RECD;
end

STATE_RECD:
if (recvd_d)
begin
LEDs_signals = 8'b00001000;
d_next = uart_rmsg[7:0];
state_next = STATE_INIT;
end

STATE_INIT:
if (calc_go)
begin
LEDs_signals = 8'b00010000;
state_next = STATE_CALC;
end

STATE_CALC:
if (calcd)
begin
LEDs_signals = 8'b00100000;
result_real_next = cmult_result_real;
result_imag_next = cmult_result_imag;
state_next = STATE_SEND;
end

STATE_SEND:
begin
LEDs_signals = 8'b01000000;
tmsg = { result_real, result_imag };
state_next = STATE_DONE;
end
/*
 STATE_SENDREAL:
 begin
 LEDs_signals = 8'b01000000;
 tmsg = { 8'h00, result_real };
 state_next = STATE_SENDIMAG;
 end
 
 STATE_SENDIMAG:
 if (sent_msg)
 begin
 LEDs_signals = 8'b10000000;
 tmsg = { 8'h00, result_imag };
 state_next = STATE_DONE;
 end
 */
STATE_DONE:
if (sent_msg)
begin
LEDs_signals = 8'b10000000;
state_next = STATE_RECA;
end

endcase // case (state)
end // always @ (*)

assign LEDs = LEDs_signals;

// State output

localparam numcs = 4;
localparam cs_cmult_out_rdy  = numcs - 1;
localparam cs_cmult_in_val   = numcs - 2;
localparam cs_uart_out_rdy = numcs - 3;
localparam cs_uart_in_val  = numcs - 4;

reg [numcs - 1:0] cs;

wire 	     recvd_a;
wire 	     recvd_b;
wire 	     recvd_c;
wire 	     recvd_d;
wire 	     calc_go;
wire 	     calcd;
wire 	     sent_msg;

always @ (*)
begin
case (state)
//                     cmult_out_rdy cmult_in_val uart_out_rdy uart_in_val
STATE_RECA:     cs = {      1'b0,      1'b0,        1'b1,       1'b0 };
STATE_RECB:     cs = {      1'b0,      1'b0,        1'b1,       1'b0 };
STATE_RECC:     cs = {      1'b0,      1'b0,        1'b1,       1'b0 };
STATE_RECD:     cs = {      1'b0,      1'b0,        1'b1,       1'b0 };
STATE_INIT:     cs = {      1'b1,      1'b1,        1'b0,       1'b0 };//might have to change this bit for pipelined to work!
STATE_CALC:     cs = {      1'b1,      1'b0,        1'b0,       1'b0 };
STATE_SEND:     cs = {      1'b0,      1'b0,        1'b0,       1'b1 };
//	STATE_SENDREAL: cs = {      1'b0,      1'b0,        1'b0,       1'b1 };
//	STATE_SENDIMAG: cs = {      1'b0,      1'b0,        1'b0,       1'b1 };
STATE_DONE:     cs = {      1'b0,      1'b0,        1'b0,       1'b0 };
endcase // case (state)
end // always @ (*)

// State transition control

assign recvd_a = (uart_out_rdy && uart_out_val)
&& (uart_rmsg[15:8] == 8'h00);
assign recvd_b = (uart_out_rdy && uart_out_val)
&& (uart_rmsg[15:8] == 8'h00);
assign recvd_c = (uart_out_rdy && uart_out_val)
&& (uart_rmsg[15:8] == 8'h00);
assign recvd_d = (uart_out_rdy && uart_out_val)
&& (uart_rmsg[15:8] == 8'h00);
assign calc_go = cmult_in_val && cmult_in_rdy;
assign calcd = cmult_out_rdy && cmult_out_val;
assign sent_msg = uart_in_rdy;

// Static assignments

assign cmult_out_rdy  = cs[cs_cmult_out_rdy];
assign cmult_in_val   = cs[cs_cmult_in_val];
assign uart_out_rdy   = cs[cs_uart_out_rdy];
assign uart_in_val    = cs[cs_uart_in_val];

assign uart_tmsg    = tmsg;

//   assign result_real_bits  = result_real;

//   assign uart_tmsg    = { 8'h00, result_imag };
//   assign result_imag_bits = result_imag;

/*
 assign uart_tmsg    = { 8'h00, result };
 assign result_bits  = result;
 */
// "Cur. status: ###"
wire [7:0] status [15:0];

assign status[0]  = 8'h43;
assign status[1]  = 8'h75;
assign status[2]  = 8'h72;
assign status[3]  = 8'h2e;
assign status[4]  = 8'h20; // might need clear (2'b01, 5'h04, 8'h00)
assign status[5]  = 8'h73;
assign status[6]  = 8'h74;
assign status[7]  = 8'h61;
assign status[8]  = 8'h74;
assign status[9]  = 8'h75;
assign status[10] = 8'h73;
assign status[11] = 8'h3a;
assign status[12] = 8'h20;
assign status[13] = {7'h18, state[2]}; // instead of (# | 0x30), concat
assign status[14] = {7'h18, state[1]}; // -> 0x30 >> 1 = 0x18
assign status[15] = {7'h18, state[0]};

/*   // translate to pretty strings
 ByteToDecimal str_a
 (
 .bits(gcd_op_a),
 .asciidecbits(abits)
 );
 ByteToDecimal str_b
 (
 .bits(gcd_op_b),
 .asciidecbits(bbits)
 );
 ByteToDecimal str_c
 (
 .bits(cmult_op_c),
 .asciidecbits(cbits)
 );
 ByteToDecimal str_d
 (
 .bits(cmult_op_d),
 .asciidecbits(dbits)
 );
 ByteToDecimal str_e
 (
 .bits(result_real),
 .asciidecbits(ebits)
 );
 ByteToDecimal str_f
 (
 .bits(result_imag),
 .asciidecbits(fbits)
 );
 
 // Access char arrays as bits
 
 genvar     i, j;
 generate
 for (i = 0; i < 16; i = i + 1) begin
 for (j = 0; j < 8; j = j + 1) begin
 assign sbits [(i * 8) + j] = status [i][j];
 end
 end
 endgenerate
 */
// Debug

assign USER_SMA_GPIO_N = clk;
assign USER_SMA_GPIO_P = USB_1_RX;

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