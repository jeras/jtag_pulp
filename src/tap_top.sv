// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// synopsys translate_off
//`include "timescale.v"
// synopsys translate_on

// Define IDCODE Value

// Length of the Instruction register

// Supported Instructions
`define IDCODE          4'b0010
`define REG1            4'b0100
`define REG2            4'b0101
`define REG3            4'b0110
`define REG_CLK_BYP     4'b0111
`define REG_OBSERV      4'b1000
`define REG6            4'b1001
`define BYPASS          4'b1111

// Top module
module tap_top #(
  parameter int unsigned IR_LENGTH = 4,
  parameter logic [32-1:0] IDCODE_VALUE = 32'h10102001
  // 0001             version
  // 0000000000000001 part number (IQ)
  //                  0001 PULPissimo
  //                  0002 PULP
  //                  0003 bigPULP
  //                  0102 Vincent Vega(derived from PULP)
  // 00000000001      manufacturer id
  //                  1 ETH
  //                  2 Greenwaves
  // 1                required by standard
)(
  // JTAG pins
  input  logic tms_i,      // JTAG test mode select pad
  input  logic tck_i,      // JTAG test clock pad
  input  logic rst_ni,     // JTAG test reset pad
  input  logic td_i,       // JTAG test data input pad
  output logic td_o,       // JTAG test data output pad
//output logic tdo_padoe_o,    // Output enable for JTAG test data output pad

  // TAP states
  output logic shift_dr_o,
  output logic update_dr_o,
  output logic capture_dr_o,

  // Select signals for boundary scan or mbist
  output logic memory_sel_o,
  output logic fifo_sel_o,
  output logic confreg_sel_o,
  output logic clk_byp_sel_o,
  output logic observ_sel_o,

  // TDO signal that is connected to TDI of sub-modules.
  output logic scan_in_o,

  // TDI signals from sub-modules
  input  logic memory_out_i,      // from reg1 module
  input  logic fifo_out_i,    // from reg2 module
  input  logic confreg_out_i,     // from reg4 module
  input  logic clk_byp_out_i,
  input  logic observ_out_i
);

// Registers
logic   test_logic_reset;
logic   run_test_idle;
logic   sel_dr_scan;
logic   capture_dr;
logic   shift_dr;
logic   exit1_dr;
logic   pause_dr;
logic   exit2_dr;
logic   update_dr;
logic   sel_ir_scan;
logic   capture_ir;
logic   shift_ir, shift_ir_neg;
logic   exit1_ir;
logic   pause_ir;
logic   exit2_ir;
logic   update_ir;
logic   idcode_sel;
logic   memory_sel;
logic   fifo_sel;
logic   confreg_sel;
logic   bypass_sel;

logic   clk_byp_sel;
logic   observ_sel;

logic [4:1] tms_q;
logic   tms_reset;

assign scan_in_o = td_i;
assign shift_dr_o = shift_dr;
assign update_dr_o = update_dr;
assign capture_dr_o = capture_dr;

assign memory_sel_o = memory_sel;
assign fifo_sel_o = fifo_sel;
assign confreg_sel_o = confreg_sel;

assign clk_byp_sel_o  = clk_byp_sel;
assign observ_sel_o   = observ_sel;


always_ff @ (posedge tck_i)
tms_q <= {tms_q[3:1], tms_i};

assign tms_reset = &{tms_q, tms_i};    // 5 consecutive TMS=1 causes reset

/**********************************************************************************
*                                                                                 *
*   TAP State Machine: Fully JTAG compliant                                       *
*                                                                                 *
**********************************************************************************/

always_ff @ (posedge tck_i, negedge rst_ni)
if (~rst_ni) begin
  test_logic_reset <= 1'b1;
  run_test_idle    <= 1'b0;
  sel_dr_scan      <= 1'b0;
  capture_dr       <= 1'b0;
  shift_dr         <= 1'b0;
  exit1_dr         <= 1'b0;
  pause_dr         <= 1'b0;
  exit2_dr         <= 1'b0;
  update_dr        <= 1'b0;
  sel_ir_scan      <= 1'b0;
  capture_ir       <= 1'b0;
  shift_ir         <= 1'b0;
  exit1_ir         <= 1'b0;
  pause_ir         <= 1'b0;
  exit2_ir         <= 1'b0;
  update_ir        <= 1'b0;
end else begin
  if (tms_reset) begin
    test_logic_reset <= 1'b1;
    run_test_idle    <= 1'b0;
    sel_dr_scan      <= 1'b0;
    capture_dr       <= 1'b0;
    shift_dr         <= 1'b0;
    exit1_dr         <= 1'b0;
    pause_dr         <= 1'b0;
    exit2_dr         <= 1'b0;
    update_dr        <= 1'b0;
    sel_ir_scan      <= 1'b0;
    capture_ir       <= 1'b0;
    shift_ir         <= 1'b0;
    exit1_ir         <= 1'b0;
    pause_ir         <= 1'b0;
    exit2_ir         <= 1'b0;
    update_ir        <= 1'b0;
  end else begin
    test_logic_reset <=  tms_i & (test_logic_reset | sel_ir_scan);
    run_test_idle    <= ~tms_i & (test_logic_reset | run_test_idle | update_dr | update_ir);
    sel_dr_scan      <=  tms_i & (                   run_test_idle | update_dr | update_ir);
    capture_dr       <= ~tms_i & (sel_dr_scan);
    shift_dr         <= ~tms_i & (capture_dr | shift_dr | exit2_dr);
    exit1_dr         <=  tms_i & (capture_dr | shift_dr);
    pause_dr         <= ~tms_i & (exit1_dr | pause_dr);
    exit2_dr         <=  tms_i & (pause_dr);
    update_dr        <=  tms_i & (exit1_dr | exit2_dr);
    sel_ir_scan      <=  tms_i & (sel_dr_scan);
    capture_ir       <= ~tms_i & (sel_ir_scan);
    shift_ir         <= ~tms_i & (capture_ir | shift_ir | exit2_ir);
    exit1_ir         <=  tms_i & (capture_ir | shift_ir);
    pause_ir         <= ~tms_i & (exit1_ir | pause_ir);
    exit2_ir         <=  tms_i & (pause_ir);
    update_ir        <=  tms_i & (exit1_ir | exit2_ir);
  end
end

/**********************************************************************************
*   jtag_ir:  JTAG Instruction Register                                           *
**********************************************************************************/
logic [IR_LENGTH-1:0] jtag_ir;          // Instruction register
logic [IR_LENGTH-1:0] latched_jtag_ir, latched_jtag_ir_neg;
logic                 instruction_tdo;

always_ff @(posedge tck_i, negedge rst_ni)
if(~rst_ni)
  jtag_ir[IR_LENGTH-1:0] <= '0;
else begin
  if(capture_ir)
    jtag_ir <=  4'b0101;          // This value is fixed for easier fault detection
  else if(shift_ir)
    jtag_ir[IR_LENGTH-1:0] <=  {td_i, jtag_ir[IR_LENGTH-1:1]};
end

assign  instruction_tdo =  jtag_ir[0];

/**********************************************************************************
*   idcode logic                                                                  *
**********************************************************************************/
logic [32-1:0] idcode_reg;
logic          idcode_tdo;

always_ff @(posedge tck_i, negedge rst_ni)
if (~rst_ni)
  idcode_reg <= IDCODE_VALUE;
else begin
  if(idcode_sel & shift_dr)
    idcode_reg <=  {td_i, idcode_reg[31:1]};
  else if(idcode_sel & (capture_dr | exit1_dr))
    idcode_reg <= IDCODE_VALUE;
end

assign idcode_tdo = idcode_reg[0];

/**********************************************************************************
*   Bypass logic                                                                  *
**********************************************************************************/
logic bypassed_tdo;
logic bypass_reg;

always_ff @(posedge tck_i, negedge rst_ni)
if (~rst_ni)
  bypass_reg<= 1'b0;
else begin
  if(shift_dr)
    bypass_reg<= td_i;
end

assign bypassed_tdo = bypass_reg;

/**********************************************************************************
*   Activating Instructions                                                       *
**********************************************************************************/
// Updating jtag_ir (Instruction Register)
always_ff @(posedge tck_i, negedge rst_ni)
if (~rst_ni)
    latched_jtag_ir <= `IDCODE;   // IDCODE seled after reset
else begin
  if (tms_reset)
    latched_jtag_ir <= `IDCODE;   // IDCODE seled after reset
  else if(update_ir)
    latched_jtag_ir <= jtag_ir;
end

/**********************************************************************************
*   End: Activating Instructions                                                  *
**********************************************************************************/

// Updating jtag_ir (Instruction Register)
always_comb
begin
  idcode_sel  = 1'b0;
  memory_sel  = 1'b0;
  fifo_sel    = 1'b0;
  confreg_sel = 1'b0;
  bypass_sel  = 1'b0;
  clk_byp_sel = 1'b0;
  observ_sel  = 1'b0;
  case(latched_jtag_ir)    /* synthesis parallel_case */
    `IDCODE:      idcode_sel  = 1'b1;    // ID Code
    `REG1:        memory_sel  = 1'b1;    // REG1
    `REG2:        fifo_sel    = 1'b1;    // REG2
    `REG3:        confreg_sel = 1'b1;    // REG3
    `REG_CLK_BYP: clk_byp_sel = 1'b1;    // REG4
    `REG_OBSERV:  observ_sel  = 1'b1;    // REG5
    `BYPASS:      bypass_sel  = 1'b1;    // BYPASS
    default:      bypass_sel  = 1'b1;    // BYPASS
  endcase
end

/**********************************************************************************
*   Multiplexing TDO data                                                         *
**********************************************************************************/
always_ff @(negedge tck_i)
if(shift_ir_neg)
  td_o <= instruction_tdo;
else begin
  case(latched_jtag_ir_neg)    // synthesis parallel_case
    `IDCODE:      td_o <= idcode_tdo;        // Reading ID code
    `REG1:        td_o <= memory_out_i;      // REG1
    `REG2:        td_o <= fifo_out_i;        // REG2
    `REG3:        td_o <= confreg_out_i;     // REG3
    `REG_CLK_BYP: td_o <= confreg_out_i;     // REG4
    `REG_OBSERV:  td_o <= clk_byp_out_i;     // REG5
    `BYPASS:      td_o <= bypassed_tdo;      // BYPASS
    default:      td_o <= bypassed_tdo;      // BYPASS instruction
  endcase
end

// Tristate control for td_o pin
//always_ff @(negedge tck_i)
//tdo_padoe_o <=  shift_ir | shift_dr ;

always_ff @(negedge tck_i)
begin
  shift_ir_neg <=  shift_ir;
  latched_jtag_ir_neg <=  latched_jtag_ir;
end

endmodule
