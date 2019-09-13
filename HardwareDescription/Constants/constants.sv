`ifndef constants_sv
`define constants_sv

package constants;

	// Define parametric size
	`define data_size	        32
	`define pc_size		        32
	`define opcode_size	        7
	`define regfile_logsize		5
	`define instr_size	        32
	
	`define regfile_size		32
	`define memory_word	        8
    	`define mem_delay_const		4'h2   // Used in the hdu, it's ( 1 + the dmem delay )
    	`define alu_control_size	4

	// I-Cache parameters
	`define icache_blocksize	64*8 // Bytes*no_of_bits (in a byte)
	`define icache_noofsets		4 //64
	`define entriesperset		8

	// Define cu sizes
	`define cw_length	15	// number of control signals
	`define cw_mem_size	11	// number of distinct instructions


	// Define opcodes
	// BRANCH Opcodes Group
	`define btype_op	7'h63
        `define beq_func	3'h0
        `define bne_func	3'h1
        `define blt_func	3'h4
        `define bge_func	3'h5
        `define bltu_func	3'h6
        `define bgeu_func	3'h7

	// JTYPE Opcode
	`define jal_op		7'h6F

	// JALR Opcode (ITYPE-like)
	`define jalr_op		7'h67

	// UTYPE Opcodes Group
	`define lui_op		7'h37
	`define auipc_op	7'h17

	// LOAD Opcodes Group
	`define ldtype_op	7'h03
        `define lb_func		3'h0
        `define lh_func		3'h1
        `define lw_func		3'h2
        `define lbu_func	3'h4
        `define lhu_func	3'h5
	
	// STORE Opcodes Group
	`define stotype_op	7'h23
        `define sb_func		3'h0
        `define sh_func		3'h1
        `define sw_func		3'h2
	
	// ITYPE Opcodes Group
	`define itype_op	7'h13
        `define addi_func	3'h0
        `define slli_func	3'h1
        `define slti_func	3'h2
        `define sltiu_func	3'h3
        `define xori_func	3'h4
        `define srxi_func	3'h5		// this is both srai and srli, a byte in the immediate field discriminates them
        `define ori_func	3'h6
        `define andi_func	3'h7
	
	// RTYPE Opcodes Group
	`define rtype_op	7'h33
        `define addsub_func	3'h0		// same as srxi
        `define sll_func	3'h1
        `define slt_func	3'h2
        `define sltu_func	3'h3
        `define xor_func	3'h4
        `define srx_func	3'h5		// same as srxi
        `define or_func		3'h6
        `define and_func	3'h7

        `define muldiv_op	7'h33
	
	// fence
	`define fence_op	7'h0F
	//`define or_func		3'h0
	//`define or_func		3'h1
	
	// cstype
	`define cstype_op	7'h73		// ecall, cssrw and so on
	`define ecallbreak_func	3'h0		// same as srxi
	`define csrrw_func	3'h1
	`define csrrs_func	3'h2
	`define csrrc_func	3'h3
	`define csrrwi_func	3'h5
	`define csrrsi_func	3'h6
	`define csrrci_func	3'h7

	// Define user data types
	typedef enum logic[2:0] {
		lb_conf = 3'h0,
		lh_conf	= 3'h1,
		lw_conf = 3'h2,
		lbu_conf = 3'h4,
		lhu_conf = 3'h5
	} load_conf;

	typedef enum logic[2:0] {
		sb_conf = 3'h0,
		sh_conf = 3'h1,
		sw_conf = 3'h2
	} store_conf;

	typedef enum logic[2:0] {
		beq_inst = 3'b000,
		bne_inst = 3'b001,
		blt_inst = 3'b100,
		bge_inst = 3'b101,
		bltu_inst = 3'b110,
		bgeu_inst = 3'b111
	} branch_type;

	typedef enum logic[2:0] {
		mul_inst = 3'h0,
		mulh_inst = 3'h1,
		mulhsu_inst = 3'h2,
		mulhu_inst = 3'h3,
		div_inst = 3'h4,
		divu_inst = 3'h5,
		rem_inst = 3'h6,
		remu_inst = 3'h7
	} muldiv_type;

	// For the CU fsm
	typedef enum logic [1:0]{  
		NORMAL, 
		FD_DELAY_ONE,
		F_DELAY_ONE, 
		F_DELAY_MEM
	} statetype;
   
	// User defined Functions
	function automatic integer log2;
		input [31:0] v;
		reg [31:0] value;
		begin
			value = v;
			if (value == 1) begin
				log2 = 1;
			end
			else begin
				value = value-1;
				for (log2=0; value>0; log2=log2+1)
					value = value>>1;
			end
		end
	endfunction

endpackage

`endif
