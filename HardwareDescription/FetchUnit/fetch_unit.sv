`include "/home/sandro/GIT_RISCV/HardwareDescription/FetchUnit/BranchPredictionUnit/bpu.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/FetchUnit/InstructionCache/icache_controller.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/FetchUnit/BranchForwardingUnit/bfu.sv"
import constants::branch_type;
import constants::beq_inst;
import constants::bne_inst;
import constants::blt_inst;
import constants::bge_inst;
import constants::bltu_inst;
import constants::bgeu_inst;

module fetch_unit
(
	input logic clk,
	input logic nrst,
	input logic pc_en,
	input logic[`opcode_size-1:0] op_decode,
	input logic[`data_size-1:0] rs1_decode,		// RegisterSource1 Value
	input logic[`data_size-1:0] rs2_decode,		// RegisterSource2 Value
	input logic[`data_size-1:0] wr_mem,		// WritingReg from MEM Stage Value
	input logic[`regfile_logsize-1:0] rs1_field,	// RegisterSource1 Address Field
	input logic[`regfile_logsize-1:0] rs2_field,	// RegisterSource2 Address Field
	input logic[`regfile_logsize-1:0] wr_field,	// WriteRegister Address Field
	input logic[`pc_size-1:0] immediate_decode,
	input branch_type branch_op,
	input logic jr_bpu,				// When 1'b1 there's a JR instruction in the Decode Stage
	input logic[`memory_word-1:0] mem_word,		// Word from RAM
	input logic word_ready,
	input logic wr_en,				// DestinationRegister Write Enable for BranchForwardingUnit
	output logic[`pc_size-1:0] pc_val,		// Current Program Counter value
	output logic[`pc_size-1:0] ram_address,
	output logic miss_cache,
	output logic[`instr_size-1:0] instr_fetched//,
	//output logic chng2nop
);

logic[`pc_size-1:0] next_pc;
logic[`pc_size-1:0] curr_pc;
logic[`pc_size-1:0] bpu_pc;
logic[`pc_size-1:0] pc_four;
logic[`pc_size-1:0] pc_dec;
logic[`pc_size-1:0] alupc;
logic[`instr_size-1:0] fetched_inst;
logic[`instr_size-1:0] fetched_inst_chng;
logic mux_sel;
logic trgt_gen;
logic b_eval;
logic branch_outcome;
logic cache_miss;
logic[`data_size-1:0] rs1;
logic[`data_size-1:0] rs2;
logic[`pc_size-1:0] jr_in;
logic br_fwsel1;
logic br_fwsel2;
logic chng2nop;

// Define the PC+4 value and the next program counter value
assign pc_four = curr_pc + 'h4;
assign next_pc = mux_sel ? bpu_pc : pc_four;
assign pc_val = pc_four;

// Program Counter register
always_ff @(posedge clk) begin : program_counter
	if(~nrst)
		curr_pc <= 'h0;
	else
		if(pc_en & ~cache_miss)
			curr_pc <= next_pc;
end : program_counter

// Program Counter piped
always_ff @(posedge clk) begin : piped_pc
	if(~nrst)
		pc_dec <= 'h0;
	else
		if(pc_en & ~cache_miss)
			pc_dec <= curr_pc;
end : piped_pc

// It's PC+offset (different wrt MIPS which was PC+4+offset)
assign alupc = {{pc_dec[`pc_size-1:2] + immediate_decode[`pc_size-1:2]},2'h0};
assign jr_in = rs1 + immediate_decode;

// Target_generated and branch_evaluated signals
assign trgt_gen = (op_decode == `jal_op);
assign b_eval = (op_decode == `btype_op); 

// Branch Forwarding Unit 
bfu branch_fwd_unit
(
	.clk(clk),
	.nrst(nrst),
        .opcode(op_decode),
        .rs1_field(rs1_field),
        .rs2_field(rs2_field),
        .wr_field(wr_field),
        .wr_en(wr_en),
        .br_fwsel1(br_fwsel1),
        .br_fwsel2(br_fwsel2)
);

// Branch Forwarding Multiplexers
assign rs1 = br_fwsel1 ? wr_mem : rs1_decode;
assign rs2 = br_fwsel2 ? wr_mem : rs2_decode;

// Branch outcome: if 1'b0 it means do not branch, if 1'b1 it means branch
always_comb begin : branch_operations
	if((op_decode == `btype_op) & ~cache_miss) begin
		case(branch_op)
			beq_inst : begin
				if(rs1 == rs2)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bne_inst : begin
				if(rs1 != rs2)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			blt_inst : begin
				if($signed(rs1) < $signed(rs2))
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bge_inst : begin
				if($signed(rs1) >= $signed(rs2))
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bltu_inst : begin
				if(rs1 < rs2)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			default : begin			//bgeu_inst
				if(rs1 >= rs2)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end
		endcase
	end 
	else
		branch_outcome = 1'b0;
end : branch_operations

// Branch Prediction Unit
bpu branch_pred_unit
(
	.clk(clk),
	.nrst(nrst),
	.op(fetched_inst_chng[`opcode_size-1:0]),
	.pc(curr_pc),
	.alupc(alupc),
	.pcplf(pc_four),
	.jr_in(jr_in),
	.jr_bpu(jr_bpu),
	.pc_en(pc_en),// | cache_miss),
	.trgt_gen(trgt_gen),
	.b_eval(b_eval),
	.branch_outcome(branch_outcome),
	.npc(bpu_pc),
	.chng2nop(chng2nop),
	.mux_sel(mux_sel)
);

// Instruction Cache controller
icache_controller instruction_cache_controller
(
	.clk(clk),
	.nrst(nrst),
	.pc(curr_pc),
	.mem_word(mem_word),
	.word_ready(word_ready),
	.ram_address(ram_address),
	.cache_miss(cache_miss),
	.inst_fu(fetched_inst)
);


assign fetched_inst_chng = chng2nop? 'h00000013 : fetched_inst;
assign instr_fetched = fetched_inst_chng;
assign miss_cache = cache_miss;

endmodule
