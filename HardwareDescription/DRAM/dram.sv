// Simulation-only file
`include "../Constants/constants.sv"

module dram
(
	input logic clk,
	input logic nrst,
	input logic[8:0] dmem_addr, //16kB mem
	input logic[`data_size-1:0] dmem_data,
	input logic dmem_re,
	input logic dmem_we,
	output logic[`data_size-1:0] dmem_out
);

logic[7:0] dram_word [31:0];
int i;

always_ff @(posedge clk) begin
	if(~nrst)
		for(i=0; i<512; i++)
			dram_word[i] <= 32'h00000000;
	else
		if(dmem_we)
			dram_word[dmem_addr] <= dmem_data;
end

assign dmem_out = (dmem_re) ? dram_word[dmem_addr] : 32'h00000000;

endmodule
