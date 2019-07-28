// RISCV Core based on [xyz] architecture
// Set of allowed instructions: 

`include "../FetchUnit/fetch_unit.sv"
//`include "../ControlUnit/cu.sv"
`include "../RegisterFile/reg_file.sv"
`include "../ForwardUnit/forwardunit.sv"
`include "../ALU/alu.sv"

import constants::*;

module riscv_core
(
	input logic clk,			// Clock signal
	input logic nrst,			// Reset active on negedge
	input logic[`memory_word-1:0] mem_word, // Word from RAM
	input logic word_ready,			// Bit from IRAM Controller, requested word from RAM is available
//	...
	output logic[`pc_size-1:0] ram_address, // Address for the IRAM Controller (in case of Cache Miss)
	output logic miss_cache//,		// Bit to tell the IRAM Controller there's a miss
//	...
);

// Internal signals definition
logic pc_en;					// Program Counter enable (in case of stalls)
logic[`pc_size-1:0] pc_fu;			// Program Counter in the Fetch Unit
logic[`opcode_size-1:0] op_decode;		// Opcode field from the DecodeUnit
logic[`regfile_logsize-1:0] rs1_field;		// RegisterSource_1 field from the DecodeUnit
logic[`regfile_logsize-1:0] rs2_field;		// RegisterSource_2 field from the DecodeUnit
logic[`regfile_logsize-1:0] rdw_du;		// RegisterDestination field from the DecodeUnit
logic[`regfile_logsize-1:0] rdw_exu;		// RegisterDestination field from the ExecutionUnit
logic[`regfile_logsize-1:0] rdw_mu;		// RegisterDestination field from the MemoryUnit
logic[`regfile_logsize-1:0] rdw_wr;		// RegisterDestination field from the WritebackUnit
logic[`data_size-1:0] immediate_field;		// Immediate Field from the DecodeUnit
branch_type branch_op;				// Branch type operation
logic[`instr_size-1:0] instr_fetched_fu;	// Instruction fetched in the FetchUnit (before pipeline reg)
logic[`instr_size-1:0] instr_fetched_du;	// Instruction fetched in the DecodeUnit (after pipeline reg)
logic chng2nop_fu;				// Change to NOP bit in the FetchUnit (before pipeline reg)
logic chng2nop_du;				// Change to NOP bit in the DecodeUnit (after pipeline reg)
logic[`cw_length-1:0] cw_out;
logic stall;
logic[1:0] sel_fwdmux1;				// Forwarding Multiplexer Selector 1
logic[1:0] sel_fwdmux2;				// Forwarding Multiplexer Selector 2
logic[`data_size-1:0] op1_decode;		// First Operand in Decode Stage 
logic[`data_size-1:0] op2_decode;		// Second Operand in Decode Stage
logic[`pc_size-1:0] pc_dec;			// Program Counter in the Decode Stage
logic[`data_size-1:0] rd_data1;			// Out1 Data from Register File
logic[`data_size-1:0] rd_data2;			// Out2 Data from Register File
logic[`data_size-1:0] op1_execute;		// First Operand in Execute Stage (before mux)
logic[`data_size-1:0] op2_execute;		// Second Operand in Execute Stage (before mux)
logic[`data_size-1:0] imm_exe;			// Immediate Field in the Execute Stage
logic[`pc_size-1:0] pc_exe;			// Program Counter in the Execute Stage
logic[`data_size-1:0] alu_op1;			// First ALU's operand
logic[`data_size-1:0] alu_op2;			// Second ALU's operand
logic[`data_size-1:0] alu_out;			// ALU's result in EXE stage
logic ovfl_bit;
logic[`data_size-1:0] aluout_mem;		// ALU's result in MEM Stage
logic[`data_size-1:0] dmem_data;		// Data input for DRAM
logic[`data_size-1:0] dmem_out;			// Data output of the DRAM
logic[`data_size-1:0] wr_datamem;		// Data output of the DRAM
logic[`data_size-1:0] wr_data;			// Register File input data



//////////////////////////////////
// Fetch Unit of the RISCV Core //
//////////////////////////////////

// Fetch Unit instantiation
fetch_unit fu
(
	.clk(clk),
	.nrst(nrst),
        .pc_en(pc_en),
        .op_decode(op_decode),
        .rs1_decode(op1_decode),
        .rs2_decode(op2_decode),
        .immediate_decode(immediate_decode),
        .branch_op(branch_op),
        .mem_word(mem_word),
        .word_ready(word_ready),
	.pc_val(pc_fu),
        .ram_address(ram_address),
        .miss_cache(miss_cache),
        .instr_fetched(instr_fetched_fu),
        .chng2nop(chng2nop)
);

// FetchUnit -> DecodeUnit pipeline registers
always_ff @(posedge clk) begin : fu_du_regs
	if(~nrst) begin
		chng2nop_du <= 1'b0;
		instr_fetched_du <= 'h0;
		pc_dec <= 'h0;
	end
	else begin
		chng2nop_du <= chng2nop_fu;
		instr_fetched_du <= instr_fetched_fu;
		pc_dec <= pc_fu;
	end
end : fu_du_regs


///////////////////////////////////
// Decode Unit of the RISCV Core //
///////////////////////////////////

// Decompose the instruction in all of the fields
// Opcode Field
assign op_decode = instr_fetched_du[`opcode_size-1:0];

// RegisterSource_1 Field
always_comb begin : rs1_assign
	if((op_decode == `jal_op) || (op_decode == `lui_op) || (op_decode == `auipc_op))
		rs1_field = 'h0;
	else
		rs1_field = instr_fetched_du[19:15];
end : rs1_assign

// RegisterSource_2 Field
always_comb begin :  rs2_assign
        if((op_decode == `jal_op) || (op_decode == `lui_op) || (op_decode == `auipc_op) || (op_decode == `ldtype_op) || (op_decode == `itype_op))
                rs2_field = 'h0;
        else
                rs2_field = instr_fetched_du[24:20];
end : rs2_assign

// RegisterDestination (Writing Reg) Field
always_comb begin : rdw_assign
        if((op_decode == `stotype_op) || (op_decode == `btype_op))
                rdw_du = 'h0;
        else
                rdw_du = instr_fetched_du[11:7];
end : rdw_assign

// Immediate Field
always_comb begin : imm_assign
	case(op_decode)
		(`itype_op || `jalr_op) : begin
			immediate_field = `data_size'(signed'(instr_fetched_du[31:20]));
		end

		`stotype_op : begin
			immediate_field = `data_size'(signed'({instr_fetched_du[31:25],instr_fetched_du[11:7]}));
		end

		`btype_op : begin
			immediate_field = `data_size'(signed'({instr_fetched_du[31],instr_fetched_du[7],instr_fetched_du[30:25],instr_fetched_du[11:8],1'b0}));	
		end

		(`lui_op || `auipc_op) : begin
			immediate_field = {instr_fetched_du[31:12],12'h000};
		end

		`jal_op : begin
			immediate_field = `data_size'(signed'({instr_fetched_du[31],instr_fetched_du[19:12],instr_fetched_du[20],instr_fetched_du[30:21],1'b0}));
		end

		default : begin
			immediate_field = 'h0;
		end
	endcase
end : imm_assign

// Branch Operation field
assign branch_op = (op_decode == `btype_op) ? instr_fetched_du[14:12] : 'h0;

// Control unit instantiation
//cu control_unit
//(
	//TODO: download new version of CU and fill this block
//);

// Register file instantiation
reg_file register_file
(
	.clk(clk),
	.nrst(nrst),
	.rd1_en(),
	.rd1_addr(rs1_field),
	.rd2_en(),
	.rd2_addr(rs2_field),
	.wr_en(),
	.wr_addr(rdw_wr),
	.wr_data(wr_data),
	.rd_data1(rd_data1),
	.rd_data2(rd_data2)
);

// Forward unit instantiation
forw_unit forward_unit
(
	.RegWrs_1d(), // Write enable for Destination Register in the EXE stage
	.RegWrs_2d(), // Write enable for Destination Register in the MEM stage
	.RegR1(rs1_field),
	.RegR2(rs2_field),
	.RegW_1d(rdw_exu),
	.RegW_2d(rdw_mu),
	.sel_mux1(sel_fwdmux1),
	.sel_mux2(sel_fwdmux2)
);

// Multiplexer driven by the Forward Unit
always_comb begin : op1_mux
	if(sel_fwdmux1 == 2'h0)		// No Forwarding Needed
		op1_decode = rd_data1;
	else if(sel_fwdmux1 == 2'h1)	// Forwarding from MEM Stage
		op1_decode = ;
	else if(sel_fwdmux1 == 2'h2)	// Forwarding from EXE Stage
		op1_decode = alu_out;
end : op1_mux

always_comb begin : op2_mux
	if(sel_fwdmux2 == 2'h0)		// No Forwarding Needed
		op2_decode = rd_data2;
	else if(sel_fwdmux2 == 2'h1)	// Forwarding from MEM Stage
		op2_decode = ;
	else if(sel_fwdmux2 == 2'h2)	// Forwarding from EXE Stage
		op2_decode = alu_out;
end : op2_mux

// DecodeUnit -> ExecuteUnit pipeline registers
always_ff @(posedge clk) begin : du_exu_regs
	if(~nrst) begin
		rdw_exu <= 'h0;
		op1_execute <= 'h0;
		op2_execute <= 'h0;
		imm_exe <= 'h0;
		pc_exe <= 'h0;
	end
	else begin
		rdw_exu <= rdw_du;
		op1_execute <= op1_decode;
		op2_execute <= op2_decode;
		imm_exe <= immediate_field;
		pc_exe <= pc_dec;
	end
end : du_exu_regs


////////////////////////////////////
// Execute Unit of the RISCV Core //
////////////////////////////////////

assign alu_in1 = (segnale di controllo del muxa) ? pc_exe : op1_execute;
assign alu_in2 = (segnale di controllo del muxb) ? op2_execute : imm_exe;

// ALU instantiation
alu arithm_log_unit
(
	.A(alu_in1),
	.B(alu_in2),
	.Control(),
	.Out(alu_out),
	.ovfl(ovfl_bit)
);

// ExecuteUnit -> MemoryUnit pipeline registers
always_ff @(posedge clk) begin : exu_mu_regs
	if(~nrst) begin
		rdw_mu <= 'h0;
		aluout_mem <= 'h0;
		dmem_data <= 'h0;
	end
	else begin
		rdw_mu <= rdw_exu;
		aluout_mem <= alu_out;
		dmem_data <= op2_execute;
	end
end : exu_mu_regs


///////////////////////////////////
// Memory Unit of the RISCV Core //
///////////////////////////////////

// DRAM instantiation

// Mux that chooses between DRAM's out or ALU's out
assign wr_datamem = (segnale di controllo del muxc) ? aluout_mem : dmem_out;

// MemoryUnit -> WritebackUnit pipeline registers
always_ff @(posedge clk) begin : wr_mu_regs
	if(~nrst) begin
		rdw_wr <= 'h0;
		wr_data <= 'h0;
	end
	else begin
		rdw_wr <= rdw_mu;
		wr_data <= wr_datamem;
	end
end : wr_mu_regs


//////////////////////////////////////
// Writeback Unit of the RISCV Core //
//////////////////////////////////////


endmodule
