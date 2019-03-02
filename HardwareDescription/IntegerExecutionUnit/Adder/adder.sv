`include "constants.sv"

module adder
#(
	nbits = 32
)
(
	input logic[nbits-1:0] op1,	// First adder's operand
	input logic[nbits-1:0] op2,	// Second adder's operand
	input logic add_ctrl,		// If 1'b0 then sum, if 1'b1 then subtract
	input logic sgnd,		// If signd = 0, it's an unsigned op
	output logic[nbits-1:0] op_sum,	// Sum/subtraction of the operands
	output logic ovfl		// Overflow bit
);

logic[nbits:0] carry_network;
logic[nbits-1:0] prop_op;
logic[nbits-1:0] op2_xord;

// Negate op2 depending on add_ctrl
generate

	for(genvar i = 0; i < nbits; i++)
		assign op2_xord[i] = op2[i] ^ add_ctrl;

endgenerate

// Kogge Stone tree
kogge_stone #(nbits) kgst_tree
(
	.op1(op1),
	.op2(op2_xord),
	.cin(add_ctrl),
	.carry_network(carry_network[nbits:1]),
	.prop_op(prop_op)
);

assign carry_network[0] = add_ctrl;

// Generate sum bits
generate
	
	for(genvar i = 0; i < nbits; i++)
		assign op_sum[i] = prop_op[i] ^ carry_network[i];
	
endgenerate

assign ovfl = (op1[nbits-1] ~^ op2_xord[nbits-1]) ? (sgnd ? (carry_network[nbits] ^ carry_network[nbits-1]) : carry_network[nbits]) : 1'b0;

endmodule
