`include "constants.sv"

module logic_mod
(
	input logic [`data_size-1:0] op1,
	input logic [`data_size-1:0] op2,
	input logic [3:0] logic_sel,
	output logic [`data_size-1:0] logic_out
);

generate

	for(genvar i=0; i<`data_size; i++) begin : logic_blk_generation
		logic_blk logblk
		(
			.op1(op1[i]),
			.op2(op2[i]),
			.logic_sel(logic_sel),
			.logic_out(logic_out[i])
		);
	end

endgenerate

endmodule
