`include "../RISCVCore/riscv_core.sv"
`include "../DRAM/dram.sv"
import constants::*;

module riscv_tester();

logic clk;
logic nrst;
logic word_ready;
logic[`memory_word-1:0] mem_word;
logic[`pc_size-1:0] ram_address;
logic i_miss;
logic[`data_size-1:0] dmem_word;
logic[`data_size-1:0] dram_datain;
logic[8:0] dram_address;
logic dram_re;
logic dram_we;


logic[`memory_word-1:0] ram_words[0:1023]; // 1kB RAM

riscv_core riscv_processor
(
	.clk(clk),
	.nrst(nrst),
	.imem_word(mem_word),
	.word_ready(word_ready),
	.dmem_word(dmem_word),
	.iram_address(ram_address),
	.i_miss(i_miss),
	.dram_re(dram_re),
	.dram_we(dram_we),
	.dram_address(dram_address),
	.dram_datain(dram_datain)
);

always #5 clk = ~clk;

// DRAM Instantiation
dram data_ram
(
	.clk(clk),
	.nrst(nrst),
	.dmem_addr(dram_address),
	.dmem_data(dram_datain),
	.dmem_re(dram_re),
	.dmem_we(dram_we),
	.dmem_out(dmem_word)
);


// IRAM Section
initial begin : IRAM_loading
	$readmemh("../../Executables/instr_tester.in",ram_words,0);
end : IRAM_loading

logic[6:0] counter;
logic[5:0] addr_displacement;

always_ff @(posedge clk) begin : cache_miss
	if(~(nrst & i_miss)) begin
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
	@(posedge clk);
	nrst = 1'b1;
	@(posedge clk);
end

endmodule
