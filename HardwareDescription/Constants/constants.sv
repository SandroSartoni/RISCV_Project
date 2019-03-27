package constants;

	// Define parametric size
	`define data_size 32
	`define pc_size 32
	`define opcode_size 7
	`define regfile_logsize 5
	`define instr_size 32
    	`define regfile_size 32

	// Define opcodes & functions
	`define branch_group 7'h63
	`define jal_op 7'h6F
	`define jalr_op 7'h67
	`define beq_func 3'h0
	`define bne_func 3'h1
	`define blt_func 3'h4
	`define bge_func 3'h5
	`define bltu_func 3'h6
	`define bgeu_func 3'h7
	`define ldtype_op 7'b0000011		// lb, lh and so on
	`define itype_op 7'b0010011		// arithmetic immediate
	`define cstype_op 7'b1110011		// ecall, cssrw and so on
	`define rtype_op 7'b0110011		// all R types

	// Define user data types
	typedef enum logic[2:0] {
		add_conf = 3'b000,
		sub_conf = 3'b001,
		and_conf = 3'b010,
		or_conf = 3'b011,
		xor_conf = 3'b100,
		sll_conf = 3'b101,
		srl_conf = 3'b110,
		sra_conf = 3'b111
	} iexu_conf;

endpackage
