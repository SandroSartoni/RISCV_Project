// RISCV Core based on [xyz] architecture
// Set of allowed instructions: 

`include "../FetchUnit/fetch_unit.sv"
`include "../ControlUnit/cu.sv"
`include "../RegisterFile/reg_file.sv"
`include "../ForwardUnit/forwardunit.sv"
`include "../ALU/alu.sv"
`include "../DRAMController/dram_controller.sv"

import constants::*;

module riscv_core
(
	input logic clk,			// Clock signal
	input logic nrst,			// Reset active on negedge
	input logic[`memory_word-1:0] imem_word,// Word from RAM
	input logic word_ready,			// Bit from IRAM Controller, requested word from RAM is available
	input logic[`data_size-1:0] dmem_word,  // DRAM Word from Data RAM
	output logic[`pc_size-1:0] iram_address,// Address for the IRAM Controller (in case of Cache Miss)
	output logic i_miss,			// Bit to tell the IRAM Controller there's a miss
	output logic dram_re,			// Read Enable CTRL Bit for DRAM
	output logic dram_we,			// Write Enable CTRL Bit for DRAM
	output logic[8:0] dram_address,		// Address Field of the DRAM
	output logic[`data_size-1:0] dram_datain// Data Input Field of the DRAM
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
logic rd1_en;					// Read Register1 enable
logic rd2_en;					// Read Register2 enable
logic rf_we_d;
logic rf_we_e;
logic rf_we_m;
logic rf_we_w;
logic[`data_size-1:0] immediate_field;		// Immediate Field from the DecodeUnit
branch_type branch_op;				// Branch type operation
load_conf load_type[0:2];			// Load type operation
store_conf store_type[0:2];			// Store type operation
logic jr_bpu;					// Bit from CU that is 1'b1 when there's a JR in the Decode Stage
logic[`instr_size-1:0] instr_fetched;		// Instruction fetched in the FetchUnit (before pipeline reg, pre chng2nop)
logic[`instr_size-1:0] instr_fetched_fu;	// Instruction fetched in the FetchUnit (before pipeline reg, post chng2nop)
logic[`instr_size-1:0] instr_fetched_du;	// Instruction fetched in the DecodeUnit (after pipeline reg)
logic chng2nop;					// Change to NOP bit in the FetchUnit (before pipeline reg)
logic[`cw_length-1:0] cw_out;			// Control signals from Control Unit
logic miss_cache;				// Miss signal from Instruction Cache
logic[1:0] sel_fwdmux1;				// Forwarding Multiplexer Selector 1
logic[1:0] sel_fwdmux2;				// Forwarding Multiplexer Selector 2
logic[`data_size-1:0] op1_decode;		// First Operand in Decode Stage 
logic[`data_size-1:0] op2_decode;		// Second Operand in Decode Stage
logic[`pc_size-1:0] pc_dec;			// Program Counter in the Decode Stage
logic[`data_size-1:0] rd_data1;			// Out1 Data from Register File
logic[`data_size-1:0] rd_data2;			// Out2 Data from Register File
logic[`regfile_logsize-1:0] rs1_field_exe;	// RegisterSource_1 field in the ExecuteUnit
logic[`regfile_logsize-1:0] rs2_field_exe;	// RegisterSource_2 field in the ExecuteUnit
logic[`data_size-1:0] op1_execute;		// First Operand in Execute Stage (before mux)
logic[`data_size-1:0] op2_execute;		// Second Operand in Execute Stage (before mux)
logic[`data_size-1:0] imm_exe;			// Immediate Field in the Execute Stage
logic[`pc_size-1:0] pc_exe;			// Program Counter in the Execute Stage
logic[`data_size-1:0] alu_op1;			// First ALU's operand
logic[`data_size-1:0] alu_op2;			// Second ALU's operand
logic[`alu_control_size-1:0] ALU_control;	// Control bit of the ALU
logic[`data_size-1:0] alu_out;			// ALU's result in EXE stage
logic ovfl_bit;
logic[`pc_size-1:0] pc_mem;			// Program Counter in the Memory Stage
logic[`data_size-1:0] aluout_mem;		// ALU's result in MEM Stage
logic[`data_size-1:0] dmem_data;		// Data input for DRAM
logic[`data_size-1:0] dmem_out;			// Data output of the DRAM
logic dmem_re;
logic dmem_we;
logic[`data_size-1:0] alumem;
logic[`data_size-1:0] wr_datamem;		// Data output of the DRAM
logic[`data_size-1:0] wr_data;			// Register File input data
logic fet_dec_en;
logic dec_exe_en;
logic exe_mem_en;
logic mem_wr_en;


///////////////////
// Outer Signals //
///////////////////

assign i_miss = miss_cache;


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
        .rs1_decode(rd_data1),
        .rs2_decode(rd_data2),
	.wr_mem(wr_datamem),
	.rs1_field(rs1_field),
	.rs2_field(rs2_field),
	.wr_field(rdw_du),
        .immediate_decode(immediate_field),
        .branch_op(branch_op),
	.jr_bpu(jr_bpu),
        .mem_word(imem_word),
        .word_ready(word_ready),
	.wr_en(rf_we_d),
	.pc_val(pc_fu),
        .ram_address(iram_address),
        .miss_cache(miss_cache),
        .instr_fetched(instr_fetched),
        .chng2nop(chng2nop)
);

assign instr_fetched_fu = chng2nop ? 'h00000013 : instr_fetched;

// FetchUnit -> DecodeUnit pipeline registers
always_ff @(posedge clk) begin : fu_du_regs
	if(~nrst) begin
		instr_fetched_du <= 'h0;
		pc_dec <= 'h0;
	end
	else 
		if(fet_dec_en) begin
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
		`itype_op : begin//|| `jalr_op) : begin
			if((instr_fetched_du[14:12] != `slli_func) && (instr_fetched_du[14:12] != `srxi_func))
				immediate_field = `data_size'(signed'(instr_fetched_du[31:20]));
			else
				immediate_field = `data_size'(instr_fetched_du[24:20]);
		end

		`ldtype_op : begin
			immediate_field = `data_size'(signed'(instr_fetched_du[31:20]));
		end

		`stotype_op : begin
			immediate_field = `data_size'(signed'({instr_fetched_du[31:25],instr_fetched_du[11:7]}));
		end

		`btype_op : begin
			immediate_field = `data_size'(signed'({instr_fetched_du[31],instr_fetched_du[7],instr_fetched_du[30:25],instr_fetched_du[11:8],1'b0}));	
		end

		`lui_op : begin
			immediate_field = {instr_fetched_du[31:12],12'h000};
		end

		`auipc_op : begin
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
assign branch_op = (op_decode == `btype_op) ? branch_type'(instr_fetched_du[14:12]) : branch_type'('h0);

// Load Configuration field
assign load_type[0] = (op_decode == `ldtype_op) ? load_conf'(instr_fetched_du[14:12]) : load_conf'('h0);

// Store Configuration field
assign store_type[0] = (op_decode == `stotype_op) ? store_conf'(instr_fetched_du[14:12]) : store_conf'('h0);

// JALR related jr_bpu bit generation
assign jr_bpu = (op_decode == `jalr_op);

// Control unit instantiation
cu control_unit
(
	.clk(clk),
	.nrst(nrst),
	.stall(miss_cache),
	.chng2nop(chng2nop),
	.rf_we(rf_we_d),
	.instr_in(instr_fetched_fu),
	.ALU_control(ALU_control),
	.cw_out(cw_out)
);

// Control Word signals assignment
assign pc_en = cw_out[`cw_length-1];
assign fet_dec_en = cw_out[`cw_length-2]; 
assign rd1_en = cw_out[`cw_length-3];
assign rd2_en = cw_out[`cw_length-4];
assign dec_exe_en = cw_out[`cw_length-6];
assign muxA_sel = cw_out[`cw_length-7];
assign muxB_sel = cw_out[`cw_length-8];
assign exe_mem_en = cw_out[`cw_length-9];
assign dmem_we = cw_out[`cw_length-10];
assign dmem_re = cw_out[`cw_length-11];
assign mem_wr_en = cw_out[`cw_length-12];
assign muxC_sel = cw_out[`cw_length-13];
assign muxD_sel = cw_out[`cw_length-14];

// Register file instantiation
reg_file register_file
(
	.clk(clk),
	.nrst(nrst),
	.rd1_en(rd1_en),
	.rd1_addr(rs1_field),
	.rd2_en(rd2_en),
	.rd2_addr(rs2_field),
	.wr_en(rf_we_w),
	.wr_addr(rdw_wr),
	.wr_data(wr_data),
	.rd_data1(rd_data1),
	.rd_data2(rd_data2)
);

// DecodeUnit -> ExecuteUnit pipeline registers
always_ff @(posedge clk) begin : du_exu_regs
	if(~nrst) begin
		rdw_exu <= 'h0;
		op1_decode <= 'h0;
		op2_decode <= 'h0;
		imm_exe <= 'h0;
		pc_exe <= 'h0;
		rf_we_e <= 1'b0;
		rs1_field_exe <= 'h0;
		rs2_field_exe <= 'h0;
		load_type[1] <= load_conf'('h0);
		store_type[1] <= store_conf'('h0);
	end
	else
		if(dec_exe_en) begin
			op1_decode <= rd_data1;
			op2_decode <= rd_data2;
			imm_exe <= immediate_field;
			pc_exe <= pc_dec;
			rf_we_e <= rf_we_d;
			rs1_field_exe <= rs1_field;
			rs2_field_exe <= rs2_field;
			load_type[1] <= load_type[0];
			store_type[1] <= store_type[0];
		end

		// This is necessary in order not to have problems with
		// forwarding
		if(dec_exe_en)
			rdw_exu <= rdw_du;
		else
			rdw_exu <= 'h0;
end : du_exu_regs


////////////////////////////////////
// Execute Unit of the RISCV Core //
////////////////////////////////////

// Forward unit instantiation
forw_unit forward_unit
(
	.RegWrs_1d(rf_we_m), // Write enable for Destination Register in the MEM stage
	.RegWrs_2d(rf_we_w), // Write enable for Destination Register in the WRB stage
	.RegR1(rs1_field_exe),
	.RegR2(rs2_field_exe),
	.RegW_1d(rdw_mu),
	.RegW_2d(rdw_wr),
	.sel_mux1(sel_fwdmux1),
	.sel_mux2(sel_fwdmux2)
);

// Multiplexer driven by the Forward Unit
always_comb begin : op1_mux
	if(sel_fwdmux1 == 2'h0)		// No Forwarding Needed
		op1_execute = op1_decode;
	else if(sel_fwdmux1 == 2'h1)	// Forwarding from MEM Stage
		op1_execute = wr_data;
	else if(sel_fwdmux1 == 2'h2)	// Forwarding from EXE Stage
		op1_execute = aluout_mem;
end : op1_mux

always_comb begin : op2_mux
	if(sel_fwdmux2 == 2'h0)		// No Forwarding Needed
		op2_execute = op2_decode;
	else if(sel_fwdmux2 == 2'h1)	// Forwarding from MEM Stage
		op2_execute = wr_data;
	else if(sel_fwdmux2 == 2'h2)	// Forwarding from EXE Stage
		op2_execute = aluout_mem;
end : op2_mux

assign alu_op1 = (muxA_sel) ? op1_execute : pc_exe;
assign alu_op2 = (muxB_sel) ? imm_exe : op2_execute;

// ALU instantiation
alu arithm_log_unit
(
	.A(alu_op1),
	.B(alu_op2),
	.Control(ALU_control),
	.Out(alu_out),
	.ovfl(ovfl_bit)
);

// ExecuteUnit -> MemoryUnit pipeline registers
always_ff @(posedge clk) begin : exu_mu_regs
	if(~nrst) begin
		rdw_mu <= 'h0;
		aluout_mem <= 'h0;
		dmem_data <= 'h0;
		rf_we_m <= 1'b0;
		pc_mem <= 'h0;
		load_type[2] <= load_conf'('h0);
		store_type[2] <= store_conf'('h0);
	end
	else
		if(exe_mem_en) begin
			rdw_mu <= rdw_exu;
			aluout_mem <= alu_out;
			dmem_data <= op2_execute;
			rf_we_m <= rf_we_e;
			pc_mem <= pc_exe;
			load_type[2] <= load_type[1];
			store_type[2] <= store_type[1];
		end
end : exu_mu_regs


///////////////////////////////////
// Memory Unit of the RISCV Core //
///////////////////////////////////

// DRAM instantiation
dram_controller data_ram_controller
(
	.clk(clk),
	.nrst(nrst),
	.dmem_addr(aluout_mem[8:0]),
	.dmem_data(dmem_data),
	.dmem_re(dmem_re),
	.dmem_we(dmem_we),
	.load_type(load_type[2]),
	.store_type(store_type[2]),
	.dmem_word(dmem_word),
	.dmem_out(dmem_out),
	.dram_re(dram_re),
	.dram_we(dram_we),
	.dram_datain(dram_datain),
	.dram_address(dram_address)
);

// Mux that chooses between DRAM's out or ALU's out
assign alumem = (muxC_sel) ? aluout_mem : dmem_out;
assign wr_datamem = (muxD_sel) ? pc_mem : alumem;

// MemoryUnit -> WritebackUnit pipeline registers
always_ff @(posedge clk) begin : wr_mu_regs
	if(~nrst) begin
		rdw_wr <= 'h0;
		wr_data <= 'h0;
		rf_we_w <= 1'b0;
	end
	else
		if(mem_wr_en) begin
			rdw_wr <= rdw_mu;
			wr_data <= wr_datamem;
			rf_we_w <= rf_we_m;
		end
end : wr_mu_regs

endmodule
