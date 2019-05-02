package constants;

	// Define parametric size
	`define data_size 32
	`define pc_size 32
	`define opcode_size 7
	`define regfile_logsize 5
	`define instr_size 32
	`define regfile_size 32
    `define memory_word 8

	// I-Cache parameters
	`define icache_blocksize 64*8 // Bytes*no_of_bits (in a byte)
	`define icache_noofsets 64
	`define entriesperset 16

// Define cu sizes
	`define cw_length 11	// number of control signals
	`define cw_mem_size 9	// number of distinct instructions

	// Define opcodes

// branch
	`define branch_group 7'h63
	`define beq_func 3'h0
	`define bne_func 3'h1
	`define blt_func 3'h4
	`define bge_func 3'h5
	`define bltu_func 3'h6
	`define bgeu_func 3'h7
// jal
	`define jal_op 7'h6F
//jalr
	`define jalr_op 7'h67
// load
	`define ldtype_op 7'b0000011
	`define lb_func	3'h0
	`define lh_func	3'h1
	`define lw_func	3'h2
	`define lbu_func 3'h4
	`define lhu_func 3'h5
// store
	`define stotype_op 7'b0100011
	`define sb_func	3'h0
	`define sh_func	3'h1
	`define sw_func	3'h2
// immediate
	`define itype_op 7'b0010011
	`define addi_func	3'h0
	`define slti_func	3'h2
	`define sltiu_func	3'h3
	`define xori_func	3'h4
	`define ori_func	3'h6
	`define andi_func	3'h7
	`define slli_func	3'h1
	`define srxi_func	3'h5		// this is both srai and srli, a byte in the immediate field discriminates them
// rtype
	`define rtype_op 7'b0110011
	`define addsub_func	3'h0	// same as srxi
	`define sll_func	3'h1
	`define slt_func	3'h2
	`define sltu_func	3'h3
	`define xor_func	3'h4
	`define srx_func	3'h5	// same as srxi
	`define or_func		3'h6
	`define and_func	3'h7

	`define mul_func	3'h0	// same as srxi
	`define mulh_func	3'h1
	`define mulhsu_func	3'h2
	`define mulhu_func	3'h3
	`define div_func	3'h4
	`define divu_func	3'h5	// same as srxi
	`define rem_func	3'h6
	`define remu_func	3'h7
// fence
	`define fence_op 7'b0001111
	`define or_func		3'h0
	`define or_func		3'h1
// cstype
	`define cstype_op 7'b1110011		// ecall, cssrw and so on
	`define ecallbreak_func		3'h0	// same as srxi
	`define csrrw_func		3'h1
	`define csrrs_func		3'h2
	`define csrrc_func		3'h3
	`define csrrwi_func		3'h5
	`define csrrsi_func		3'h6
	`define csrrci_func		3'h7

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

	typedef enum logic[2:0] {
		beq_inst = 3'b000,
		bne_inst = 3'b001,
		blt_inst = 3'b100,
		bge_inst = 3'b101,
		bltu_inst = 3'b110,
		bgeu_inst = 3'b111
	} branch_type;

endpackage
