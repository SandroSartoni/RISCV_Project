`include "constants.sv"

module kogge_stone
#(
	parameter nbits = 32
)
(
	input logic[nbits-1:0] op1,
	input logic[nbits-1:0] op2,
	input logic cin,
	output logic[nbits-1:0] carry_network,
	output logic[nbits-1:0] prop_op
);

logic[nbits-1:0] g_network [0:$clog2(nbits)];
logic[nbits-1:0] p_network [0:$clog2(nbits)];
logic g_dummy;

generate

	for(genvar i=0; i<nbits; i++) begin
		if(!i)
			pg_gen prop_gen_blocks 
			(
				.a(op1[i]),
				.b(op2[i]),
				.g(g_dummy),
				.p(p_network[0][i])
			);
		else
			pg_gen prop_gen_blocks
			(
				.a(op1[i]),
				.b(op2[i]),
				.g(g_network[0][i]),
				.p(p_network[0][i])
			);			
	end

endgenerate

assign g_network[0][0] = (p_network[0][0] & cin) | g_dummy;

// General implementation
generate

	for(genvar layer = 0; layer < $clog2(nbits); layer ++)
		for(genvar no_of_blk = 0; no_of_blk < nbits; no_of_blk++)
			if(no_of_blk <= 2**(layer)-1) begin
				assign g_network[layer+1][no_of_blk] = g_network[layer][no_of_blk];
				assign p_network[layer+1][no_of_blk] = p_network[layer][no_of_blk];
			end
			else
				carry_prefix cp
				(
					.g_ij(g_network[layer][no_of_blk-2**(layer)]),
					.p_ij(p_network[layer][no_of_blk-2**(layer)]),
					.g_jp1k(g_network[layer][no_of_blk]),
					.p_jp1k(p_network[layer][no_of_blk]),
					.g_ik(g_network[layer+1][no_of_blk]),
					.p_ik(p_network[layer+1][no_of_blk])
				);

endgenerate

assign carry_network = g_network[$clog2(nbits)];
assign prop_op = p_network[0];

endmodule
