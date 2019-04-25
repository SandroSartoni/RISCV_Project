`include "i_cache.sv"

module icache_controller
(
	input logic clk,			// Clock signal
	input logic nrst,			// Reset active on logic zero
	input logic[`pc_size-1:0] pc,		// Program Counter
	input logic[`memory_word-1:0] mem_word,	// Word from RAM
	input logic word_ready,			// Word coming from RAM is available
	output logic[`pc_size-1:0] ram_address,	// Address to send to the RAM
	output logic cache_miss,		// If the cache has a miss, stall the Fetch Unit
	output logic[`instr_size-1:0] inst_fu	// Instruction to the Fetch Unit
);

//logic[`instr_size-1:0] fetched_inst;
logic hit_cache;
logic we_cache;
logic[`icache_blocksize-1:0] block_in_cache;
logic[`memory_word-1:0] byte_from_mem [0:(`icache_blocksize/`memory_word)-1];
logic[$clog2(`icache_blocksize/`memory_word)-1:0] entries_written;

// Reading from RAM process
// Entries_written drives the write enable signal of the cache
always_ff @(posedge clk) begin
	if(~nrst | hit_cache)
		entries_written <= 'h0;
	else
		if(word_ready)
			entries_written <= entries_written + 1'b1;
end

assign we_cache = &entries_written;

// Here we assign the words from the RAM to the byte_from_mem array of bytes
always_ff @(posedge clk) begin
	if(~nrst)
		for(int i=0; i<(`icache_blocksize/`memory_word); i++)
			byte_from_mem[i] <= 'h0;
	else
		if(word_ready)
			byte_from_mem[entries_written] <= mem_word;
end
	
// Assign all the words coming from RAM to a single signal that feeds the
// I_Cache
generate

	for(genvar i=0; i<(`icache_blocksize/`memory_word); i++)
		assign block_in_cache[`memory_word*i:(`memory_word*(i+1)-1)] = byte_from_mem[i];

endgenerate

// Instruction Cache instantiation
i_cache instruction_cache
(
	.clk(clk),
	.nrst(nrst),
	.we(we_cache),
	.block_in(block_in_cache),
	.pc(pc),
	.hit(hit_cache),
	.fetched_inst(inst_fu)//(fetched_inst)
);

assign cache_miss = ~hit_cache;
assign ram_address = pc;

// Select the correct instruction to be fetched (depending on the presence of
// a Hit/Miss)
//assign inst_fu = hit_cache ? fetched_inst : 'h0;

endmodule
