`include "fetch_unit.sv"
import constants::*;

module fetch_unit_tester();

logic clk;
logic nrst;
logic pc_en;
logic[`opcode_size-1:0] op_decode;
logic[`data_size-1:0] rs1_decode;
logic[`data_size-1:0] rs2_decode;
logic[`pc_size-1:0] immediate_decode;
logic[`instr_size-1:0] instr_fetched;
logic[`instr_size-1:0] instr_decoded;
branch_type branch_op;
logic chng2nop;
logic chng2nop_p;
logic word_ready;
logic[`memory_word-1:0] mem_word;
logic[`pc_size-1:0] ram_address;
logic miss_cache;

logic[`memory_word-1:0] ram_words[0:1023]; // 1kB RAM

fetch_unit fu_riscv
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

always #5 clk = ~clk;

always_ff @(posedge clk) begin
	chng2nop_p <= chng2nop;
end

always_ff @(posedge clk) begin
	if(~nrst)
		instr_decoded <= 'h0;
	else
		if(pc_en)
			if(~chng2nop_p)
				instr_decoded <= instr_fetched;
			else
				instr_decoded <= 'h0;
end

assign op_decode = instr_decoded[6:0];

initial begin : IRAM_loading
	$readmemh("../RISCV_EXE/fu_tester.in",ram_words,0);
end : IRAM_loading

logic[6:0] counter;
logic[5:0] addr_displacement;

always_ff @(posedge clk) begin : cache_miss
	if(~(nrst & miss_cache)) begin
		word_ready <= 1'b0;
		counter <= 7'h00;
		addr_displacement <= 6'h00;
	end
	else begin
		if(counter[0]) begin
			word_ready <= 1'b1;
			mem_word <= ram_words[ram_address+addr_displacement];
			addr_displacement <= addr_displacement + 1'b1;
		end
		else
			word_ready <= 1'b0;

		counter <= counter + 1'b1;
	end
end : cache_miss

initial begin
	nrst = 1'b0;
	clk = 1'b0;
	pc_en = 1'b0;
	branch_op = beq_inst;
	@(posedge clk);
	pc_en = 1'b1;
	nrst = 1'b1;
	@(posedge clk);
end

endmodule
