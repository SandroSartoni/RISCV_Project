// Simple wrapper that samples the inputs for the Mult/Div unit and keeps them constant
`include "/home/sandro/GIT_RISCV/HardwareDescription/Constants/constants.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MultDivUnit.sv"

module MultDivUnitWrapper
(
	input logic clk,
	input logic nrst,
	input logic[2:0] opCode,
	input logic valid,
	input logic [`data_size-1:0] lOp,
	input logic [`data_size-1:0] rOp,
	output logic [`data_size-1:0] result,
	output logic done,
	output logic divByZero,
	output logic divOverflow
);

logic [`data_size-1:0] lOp_sampled[0:1];
logic [`data_size-1:0] rOp_sampled[0:1];
logic [2:0] opCode_sampled[0:1];

assign lOp_sampled[0] = valid ? lOp : lOp_sampled[1];
assign rOp_sampled[0] = valid ? rOp : rOp_sampled[1];
assign opCode_sampled[0] = valid ? opCode : opCode_sampled[1];


// Operand sampling process
always_ff @(posedge clk) begin : Op_sampling
	if(~nrst) begin
		lOp_sampled[1] <= 'h0;
		rOp_sampled[1] <= 'h0;
		opCode_sampled[1] <= 'h0;
	end
	else begin
		if(valid) begin
			lOp_sampled[1] <= lOp_sampled[0];
			rOp_sampled[1] <= rOp_sampled[0];
			opCode_sampled[1] <= opCode_sampled[0];
		end
	end
end : Op_sampling


// MultiplierDivider Unit
MultDivUnit #(`data_size) muldiv_unit
(
	.clk(clk),
	.rst_n(nrst),
	.opCode(opCode_sampled[0]),
	.lOp(lOp_sampled[0]),
	.rOp(rOp_sampled[0]),
	.result(result),
	.done(done),
	.valid(valid),
	.divByZero(divByZero),
	.divOverflow(divOverflow)
);

endmodule
