package constants;

    // Define parametric size
	`define data_size 32
	`define pc_size 32
	`define opcode_size 7
	`define regfile_logsize 5
	`define instr_size 32
    `define regfile_size 32

    // Define opcodes
	`define j_op 7'b0000010
	`define jal_op 7'b000011
	`define beq_op 7'b000100
	`define bne_op 7'b000101

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
