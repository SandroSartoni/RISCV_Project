// RISCV Core based on [xyz] architecture
// Set of allowed instructions: 

`include "fetch_unit.sv"
`include "cu.sv"
`include "reg_file.sv"
`include "forwardunit.sv"
`include "alu.sv"

import constants::*;

module riscv_core
(
	input logic clk,			// Clock signal
	input logic nrst,			// Reset active on negedge
	input logic[`memory_word-1:0] mem_word, // Word from RAM
	input logic word_ready,			// Bit from IRAM Controller, requested word from RAM is available
	...
	output logic[`pc_size-1:0] ram_address, // Address for the IRAM Controller (in case of Cache Miss)
	output logic miss_cache,		// Bit to tell the IRAM Controller there's a miss
	...
);

// Internal signals definition
logic pc_en;
logic[`opcode_size-1:0] op_decode;
logic[`data_size-1:0] rs1_decode;
logic[`data_size-1:0] rs2_decode;
logic[`pc_size-1:0] immediate_decode;
branch_type branch_op;
logic[`instr_size-1:0] instr_fetched;
logic chng2nop;
logic[`cw_length-1:0] cw_out;
logic stall;
logic[`data_size-1:0] rd_data1;
logic[`data_size-1:0] rd_data2;
...
logic[`data_size-1:0] alu_op1;
logic[`data_size-1:0] alu_op2;
logic[`data_size-1:0] alu_out;
logic ovfl_bit;

// Fetch Unit instantiation
fetch_unit fu
(
	.clk(clk),
	.nrst(nrst),
        .pc_en(pc_en),
        .op_decode(op_decode),
        .rs1_decode(rs1_decode),
        .rs2_decode(rs2_decode),
        .immediate_decode(immediate_decode),
        .branch_op(branch_op),
        .mem_word(mem_word),
        .word_ready(word_ready),
        .ram_address(ram_address),
        .miss_cache(miss_cache),
        .instr_fetched(instr_fetched),
        .chng2nop(chng2nop)
);

// Control unit instantiation
cu control_unit
(
	//TODO: download new version of CU and fill this block
);

// Register file instantiation
reg_file register_file
(
	.clk(clk),
	.nrst(nrst),
	.rd1_en(),
	.rd1_addr(),
	.rd2_en(),
	.rd2_addr(rd2_addr),
	.wr_en(),
	.wr_addr(),
	.wr_data(),
	.rd_data1(rd_data1),
	.rd_data2(rd_data2)
);

// Forward unit instantiation
forw_unit forward_unit
(
	//TODO: trying to understand what the heck those signals mean and
	//connect it
);

// ALU instantiation
alu arithm_log_unit
(
	.A(alu_out1),
	.B(alu_out2),
	.Control(),
	.Out(alu_out),
	.ovfl(ovfl_bit)
);

endmodule
