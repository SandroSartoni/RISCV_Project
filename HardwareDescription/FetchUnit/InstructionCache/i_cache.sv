`include "constants.sv"

module i_cache
(
	input logic clk,                            // Clock signal
	input logic nrst,                           // Reset active on logic 1'b0
	input logic we,                             // Write enable signal
	input logic[0:`icache_blocksize-1] block_in,// Instruction from IRAM
	input logic[`pc_size-1:0] pc,               // Program Counter value
	output logic hit,                           // Hit/Miss signal
	output logic[`instr_size-1:0] fetched_inst  // Fetched instruction if hit
);

// Cache module, that comprises the:
//  -- Cache table: blocks to be accessed in case of Hit
//  -- Tag table: each entry contains a tag
//  -- Valbit: each entry has the validity bit for the corresponding cache entry
logic[0:`icache_blocksize-1] cache_table [0:(`icache_noofsets*`entriesperset)-1];
logic[(`pc_size-$clog2(`icache_blocksize/8)-$clog2(`icache_noofsets)-1):0] tag_table [0:(`icache_noofsets*`entriesperset)-1];
logic valbit [0:(`icache_noofsets*`entriesperset)-1];

// Decompose the PC value in TAG, Set Index, Block Offset
logic[`pc_size-$clog2(`icache_noofsets)-$clog2(`icache_blocksize/8)-1:0] tag;
logic[$clog2(`icache_noofsets)-1:0] set_index;
logic[$clog2(`icache_blocksize/8)-1:0] block_offset;

assign tag = pc[`pc_size-1:$clog2(`icache_blocksize/8)+$clog2(`icache_noofsets)];
assign set_index = pc[$clog2(`icache_blocksize/8)+$clog2(`icache_noofsets)-1:$clog2(`icache_blocksize/8)];
assign block_offset = pc[$clog2(`icache_blocksize/8)-1:0];


// Evaluate physical set_base_address
logic[$clog2(`icache_noofsets*`entriesperset)-1:0] set_base_address; // This vector has the base address of the set indicated by the current PC value

assign set_base_address[$clog2(`icache_noofsets*`entriesperset)-1:$clog2(`entriesperset)] = set_index;
assign set_base_address[$clog2(`entriesperset)-1:0] = 'h0;

// Hit/Miss signal logic
logic[`entriesperset-1:0] singlentry_hit; // Hit signal for each entry in a set
logic hit_s; // Hit signal given a PC value

always_comb begin : hit_or_miss

	for(int i=0; i<`entriesperset; i++)
		singlentry_hit[i] = (tag_table[set_base_address+i] == tag) & valbit[set_base_address+i];

end : hit_or_miss

assign hit_s = |singlentry_hit; // OR reduce of the vector of hit signals


// Decompose the instruction block entry
logic[`instr_size-1:0] instr_entry[0:(`icache_blocksize/`instr_size)-1];

generate

	for(genvar i=0; i<(`icache_blocksize/`instr_size); i++)
		assign instr_entry[i] = hit_s ? {cache_table[set_base_address+singlentry_hit-1][32*i+24:32*i+31],cache_table[set_base_address+singlentry_hit-1][32*i+16:32*i+23],
						 cache_table[set_base_address+singlentry_hit-1][32*i+8:32*i+15],cache_table[set_base_address+singlentry_hit-1][32*i:32*i+7]} :
						 (we ? {block_in[32*i+24:32*i+31],block_in[32*i+16:32*i+23],block_in[32*i+8:32*i+15],block_in[32*i:32*i+7]} : 'h0);

endgenerate


// Assign here output hit signal and fetched instruction (if any)
assign hit = hit_s;
assign fetched_inst = instr_entry[block_offset[$clog2(`icache_blocksize/8)-1:2]];


// Tag and Cache Table 
logic[$clog2(`entriesperset)-1:0] update_cnt[0:`icache_noofsets-1];

always_ff @(posedge clk) begin
	if(~nrst) begin
		for(int i=0; i<(`icache_noofsets*`entriesperset); i++) begin
			cache_table[i] <= 'h0;
			tag_table[i] <= 'h0;
			valbit[i] <= 1'b0;
		end 

		for(int i=0; i<`icache_noofsets; i++)
			update_cnt[i] <= 'h0;
	end
	else begin
		if(we) begin// Assuming Miss stalls the fetch unit
			cache_table[set_base_address+update_cnt[set_index]] <= block_in;
			tag_table[set_base_address+update_cnt[set_index]] <= tag;
			valbit[set_base_address+update_cnt[set_index]] <= 1'b1; 
			update_cnt[set_index] <= update_cnt[set_index] + 1'b1;
		end
	end
end

endmodule
