`include "bpu.sv"
`include "icache_controller.sv"
import constants::*;

module fetch_unit
(
	input logic clk,
	input logic nrst,
	input logic pc_en,
	input logic[`opcode_size-1:0] op_decode,
	input logic [`data_size-1:0] rs1_decode,
	input logic [`data_size-1:0] rs2_decode,
	input logic [`pc_size-1:0] immediate_decode,
	input branch_type branch_op,
	input logic[`memory_word-1:0] mem_word, // Word from RAM
	input logic word_ready,
	output logic[`pc_size-1:0] ram_address,
    output logic miss_cache;
	output logic [`instr_size-1:0] instr_fetched,
	output logic chng2nop
);

logic[`pc_size-1:0] next_pc;
logic[`pc_size-1:0] curr_pc;
logic[`pc_size-1:0] bpu_pc;
logic[`pc_size-1:0] pc_four;
logic[`pc_size-1:0] pc_dec;
logic[`pc_size-1:0] alupc;
logic[`instr_size-1:0] fetched_inst;
logic mux_sel;
logic trgt_gen;
logic b_eval;
logic branch_outcome;
logic cache_miss;


// Define the PC+4 value and the next program counter value
assign pc_four = curr_pc + 'h4;
assign next_pc = mux_sel ? bpu_pc : pc_four;

// Program Counter register
always_ff @(posedge clk) begin : program_counter
	if(~nrst)
		curr_pc <= 'h0;
	else
		if(pc_en | cache_miss)
			curr_pc <= next_pc;
end : program_counter

// Program Counter piped
always_ff @(posedge clk) begin : piped_pc
	if(~nrst)
		pc_dec <= 'h0;
	else
		if(pc_en | cache_miss)
			pc_dec <= curr_pc;
end : piped_pc

// It's PC+offset (different wrt MIPS which was PC+4+offset)
assign alupc = {{pc_dec[`pc_size-1:2] + immediate_decode[`pc_size-1:2]},2'h0};

// Target_generated and branch_evaluated signals
assign trgt_gen = (op_decode == `jal_op);
assign b_eval = (op_decode == `branch_group); 

// Branch outcome: if 1'b0 it means do not branch, if 1'b1 it means branch
always_comb begin : branch_operations
	if(op_decode == `branch_group) begin
		case(branch_op)
			beq_inst : begin
				if(rs1_decode == rs2_decode)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bne_inst : begin
				if(rs1_decode != rs2_decode)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			blt_inst : begin
				if($signed(rs1_decode) < $signed(rs2_decode))
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bge_inst : begin
				if($signed(rs1_decode) >= $signed(rs2_decode))
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bltu_inst : begin
				if(rs1_decode < rs2_decode)
					branch_outcome = 1'b1;
				else
					branch_outcome = 1'b0;
			end

			bgeu_inst : begin
				if(rs1_decode >= rs2_decode)
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
	.op(fetched_inst[`opcode_size-1:0]),
	.pc(curr_pc),
	.alupc(alupc),
	.pcplf(pc_four),
	.jr_in(32'h0),
	.jr_bpu(1'h0),
	.pc_en(pc_en | cache_miss),
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

assign instr_fetched = fetched_inst;
assign miss_cache = cache_miss;

endmodule
