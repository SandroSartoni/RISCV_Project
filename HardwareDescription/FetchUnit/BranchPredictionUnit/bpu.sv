`include "/home/sandro/GIT_RISCV/HardwareDescription/Constants/constants.sv"

`define table_size 512
`define table_logsize constants::log2(`table_size)

module bpu
(
	input logic clk,				// Clock signal (synchronous module that works @ posedge)
	input logic nrst,				// Synchronous reset signal that works on 
	input logic[`opcode_size-1:0] op, 		// Opcode of the instruction from RAM
	input logic[`pc_size-1:0] pc, 			// PC used to generate an address in the table (using its 10 LSBs)
	input logic[`pc_size-1:0] alupc, 		// Result from the adder in the decoder stage that sums PC+4+label (target addr for br and jmp)
	input logic[`pc_size-1:0] pcplf, 		// PC+4 in case there's a misprediction (branch predicted taken when actually it's not)
	input logic[`pc_size-1:0] jr_in, 		// Address to jump to when in JR instruction
	input logic jr_bpu,				// Bit from CU used to notify when we've a JR instruction
	input logic pc_en,				// Enable bit
	input logic trgt_gen, 				// Bit used to know when a target address (in jmp instructions) is generated
	input logic b_eval, 				// Bit used to know when the actual outcome of the branch is available
	input logic branch_outcome,			// If this bit is = 1'b1 it means that we've to branch, otherwise it's 1'b0
	output logic[`instr_size-1:0] npc, 		// New PC according to branch prediction or jmp instrucion
	output logic chng2nop,				// This is an output bit that tells the CU that the instruction fetched is wrong and has to be turned into a NOP
	output logic mux_sel				// PC multiplexer selector
);


	logic validity_bit [0:`table_size-1]; 					// Validity bit for the NPC_Table
	logic[1:0] branch_table [0:`table_size-1];				// Initialize all the entries to "01" (branch predicted not taken)
	logic[`pc_size-1:0] npc_table [0:`table_size-1]; 			// Initialize all the entries to 0x00000000
    	logic[`pc_size-`table_logsize-3:0] pc_aliasing [0:`table_size-1];	// Store the remaining bits of the PC to see whether we've aliasing or not
	logic mispredict; 							// It tells us whether we've a misprediction or not
	logic[1:0] prdct_pipe; 							// Stores the last prediction 
	logic valbit_pipe; 							// Pipelined validity bit
	logic cjmpa; 								// Used to correct the jmp address when the table is overwritten
	logic[`pc_size-1:0] pcplf_pipe; 					// PC+4 pipelined
	logic[`opcode_size-1:0] op_pipe; 					// Opcode pipelined
	logic[`table_logsize-1:0] pc_pipe; 					// PC pipelined
	logic aliasing, aliasing_pipe;                         			// Signal to evaluate if there's aliasing (instruction with the same pc[`table_logsize-1:0] portion)

	integer i;

	
	// NPC should work in this way: 
	// Branch instruction: at first send out the predicted address, then if prediction=not_taken & actual branch=taken -> change nothing (MUX will know when to select NPC or not)
	// If prediction=taken & actual branch=not_taken, send out pcplf_pipe
	// Jump: jump target address are always correct, the only exception is the first time such instruction is executed (target not known)
	// In this case, initially let NPC=PC+4 and then as soon as the actual target is known, update the table & send out that address
	always_comb begin : npc_assign
		if(((trgt_gen || mispredict) && (~valbit_pipe)) || aliasing_pipe)
            		npc = alupc;
        	else if(mispredict && prdct_pipe[1])
            		npc = pcplf_pipe;
        	else if(jr_bpu)
            		npc = jr_in;
        	else
            		npc = npc_table[pc[`table_logsize+1:2]];
    	end : npc_assign	

	// Address MUX selector
    	always_comb begin : mux_selector_assign
        	if(mispredict || cjmpa || jr_bpu || aliasing_pipe || (validity_bit[pc[`table_logsize+1:2]] && (op == `jal_op)))
            		mux_sel = 1'b1;
        	else if(op == `btype_op)
            		mux_sel = branch_table[pc[`table_logsize+1:2]][1];
        	else
            		mux_sel = 1'b0;
    	end : mux_selector_assign
			   
	// Here we evaluate whether there's misprediction or not;	   
    	assign mispredict = b_eval ? (prdct_pipe[1] ^ branch_outcome) : 1'b0;
	assign chng2nop = mispredict | aliasing_pipe | (~valbit_pipe && (op_pipe == `jal_op)) | jr_bpu;

    	// Is there an aliasing?
    	assign aliasing = (op == `btype_op || op == `jal_op) ? (pc[`pc_size-1:`table_logsize+2] != pc_aliasing[pc[`table_logsize+1:2]]) : 1'b0;

    	// Bit that tells the BPU that a jump target never evaluated before has been produced
	assign cjmpa = trgt_gen & (~valbit_pipe);


    	// Validity bit vector, Branch table and NPC table update
	always_ff @(posedge clk) begin : valbit_branch_npc_table_upd
		if(~nrst)
			for(i=0; i<`table_size; i++) begin
				validity_bit[i] <= 1'b0;
				branch_table[i] <= 2'b01;
                		npc_table[i] <= 'h0;
                		pc_aliasing[i] <= 'h0;
			end
            	else begin
			// Update validity bit and npc_table
			if(((mispredict || trgt_gen) && (~valbit_pipe)) || aliasing_pipe) begin
				validity_bit[pc_pipe] <= 1'b1;
                    		npc_table[pc_pipe] <= alupc;
                    		pc_aliasing[pc_pipe] <= pc[`pc_size-1:`table_logsize+2];
                	end
			// Update the branch predictor every time we've the exact prediction
			if(b_eval)
				if(branch_outcome && prdct_pipe[1])
					branch_table[pc_pipe] <= 2'b11;
				else if((branch_outcome && prdct_pipe == 2'b01) || ((~branch_outcome) && prdct_pipe == 2'b11))
					branch_table[pc_pipe] <= 2'b10;
				else if((branch_outcome && prdct_pipe == 2'b00) || ((~branch_outcome) && prdct_pipe == 2'b10))
					branch_table[pc_pipe] <= 2'b01;
				else
					branch_table[pc_pipe] <= 2'b00;
			end
	end : valbit_branch_npc_table_upd

	// Pipeline signal update process	
	always_ff @(posedge clk) begin : pipe_sig_update
        	if(~nrst) begin
            		valbit_pipe <= 'h0;
            		prdct_pipe <= 'h0;
		        aliasing_pipe <= 1'b0;
		        op_pipe <= 'h0;
		        pc_pipe <= 'h0;
		        pcplf_pipe <= 'h0;
        	end
        	else
	        	if(pc_en) begin
		        	valbit_pipe <= validity_bit[pc[`table_logsize+1:2]];
				prdct_pipe <= branch_table[pc[`table_logsize+1:2]];
                		aliasing_pipe <= aliasing;
				op_pipe <= op;
                		pc_pipe <= pc[`table_logsize+1:2];
				pcplf_pipe <= pcplf;
	        	end
	end : pipe_sig_update

endmodule
