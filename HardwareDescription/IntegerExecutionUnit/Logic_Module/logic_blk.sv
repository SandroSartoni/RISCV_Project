module logic_blk
(
	input logic op1,
	input logic op2,
	input logic [3:0] logic_sel,
	output logic logic_out
);

logic nand_out0;
logic nand_out1;
logic nand_out2;
logic nand_out3;

assign nand_out0 = ~((~op1) & (~op2) & logic_sel[0]);
assign nand_out1 = ~(op1 & (~op2) & logic_sel[1]);
assign nand_out2 = ~((~op1) & op2 & logic_sel[2]);
assign nand_out3 = ~(op1 & op2 & logic_sel[3]);

assign logic_out = ~(nand_out0 & nand_out1 & nand_out2 & nand_out3);

endmodule
