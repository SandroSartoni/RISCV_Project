`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MultDivUnitWrapper.sv"

import constants::muldiv_type;
import constants::mul_inst;
import constants::mulh_inst;
import constants::mulhsu_inst;
import constants::mulhu_inst;
import constants::div_inst;
import constants::divu_inst;
import constants::rem_inst;
import constants::remu_inst;

module alu
(
	input logic clk,
	input logic nrst,
	input logic [`data_size-1:0] A,
	input logic [`data_size-1:0] B,
	input logic [`alu_control_size-1:0] Control,
	input muldiv_type muldiv_inst,
	input logic valid_muldiv,
	output logic [`data_size-1:0] Out,
	output logic ovfl,
	output logic muldiv_done,
	output logic divByZero
);

logic compare_u_result;
logic compare_s_result;
logic[`data_size-1:0] muldiv_result;
logic divOverflow;

parameter S0 = 4'b0000; //LUI
parameter S1 = 4'b0001; // LB LH LW LBU LHU SB SH SW
parameter S2 = 4'b0010; //ADDI ADD AUIPC
parameter S3 = 4'b0011; //XORI XOR
parameter S4 = 4'b0100; //ORI OR
parameter S5 = 4'b0101; //ANDI AND
parameter S6 = 4'b0110; //SLLI SLL
parameter S7 = 4'b0111; //SRLI SRL
parameter S8 = 4'b1000; //SRAI SRA
parameter S9 = 4'b1001; //SUB
parameter S10 = 4'b1010; //SLT SLTI
parameter S11 = 4'b1011; //SLTU SLTIU
parameter S12 = 4'b1100; // MUL DIV

always_comb begin : Compare_s
	if (signed'(A) < signed'(B)) 
		compare_s_result = 1'b1;
	else  
		compare_s_result = 1'b0;
end

always_comb begin : Compare_u
	if (A < B) 
		compare_u_result = 1'b1;
	else  
		compare_u_result = 1'b0;
end

always_comb begin : MUX
 case (Control) 
	S0: Out = {B[19:0],12'h0};
	S1: Out = A + B;//  in realtà sarà il kogge stone
	S2: Out = A + B;// in realtà sarà il kogge stone
	S3: Out = A ^ B;
	S4: Out = A | B;
	S5: Out = A & B;
	S6: Out = A << B;
	S7: Out = A >> B;
	S8: Out = signed'(A) >>> B;
	S9: Out = A - B;
	S10: Out = compare_s_result;
	S11: Out = compare_u_result;
	default: Out = muldiv_result;
endcase 
end 

// Multiplier/Divider Module
MultDivUnitWrapper mul_div_unit_wrapper
(
	.clk(clk),
	.nrst(nrst),
	.opCode(muldiv_inst),
	.valid(valid_muldiv),
	.lOp(B),
	.rOp(A),
	.result(muldiv_result),
	.done(muldiv_done),
	.divByZero(divByZero),
	.divOverflow(divOverflow_s)
);

// Overflow bit logic
assign ovfl= (muldiv_done) ? divOverflow : 1'b0;

endmodule
