// This module is in charge of forwarding the correct
// register content to the BPU
// Example:
// addi x1,x2,x3	FDEMW
// nop			 FDEMW
// beq x1,x5,label	  FDEMW (no stall required, forwarding required)
//
// addi x1,x2,x3	FDEMW
// beq x1,x5,label	 FsDEMW (stall required, forwarding required)
//
// addi x1,x2,x3	FDEMW
// nop			 FDEMW
// nop			  FDEMW
// beq x1,x5,label	   FDEMW (no stall required, no forwarding required)

`include "../../Constants/constants.sv"

module bfu
(
	input logic[`opcode_size-1:0] opcode,
	input logic[`regfile_logsize-1:0] rs1_field,
	input logic[`regfile_logsize-1:0] rs2_field,
	input logic[`regfile_logsize-1:0] wr_field,
	input logic wr_en,
	output logic br_fwsel1, 
	output logic br_fwsel2 
);

logic wr_enp1;
logic wr_enp2;
logic[`regfile_logsize-1:0] wr_fieldp1;
logic[`regfile_logsize-1:0] wr_fieldp2;


assign br_fwsel1 = (((opcode == `btype_op) || (opcode == `jalr_op)) && (rs1_field == wr_fieldp2) && wr_enp2);
assign br_fwsel2 = (((opcode == `btype_op) || (opcode == `jalr_op)) && (rs2_field == wr_fieldp2) && wr_enp2);


always_ff @(posedge clk) begin : pipe_regs
	if(~nrst) begin
		wr_enp1 <= 1'b0;
		wr_enp2 <= 1'b0;
		wr_fieldp1 <= 'h0;
		wr_fieldp2 <= 'h0;
	end
	else begin
		wr_enp1 <= wr_en;
		wr_enp2 <= wr_enp1;
		wr_fieldp1 <= wr_field;
		wr_fieldp2 <= wr_fieldp1;
	end
end : pipe_regs


endmodule
