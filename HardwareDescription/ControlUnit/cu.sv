// TESTED:

// - basic fetching and pipelining
// - chng2nop at the second clock cycle
// - hazards:
//      load / any
//      any / branch 
//      load / branch

`include "../Constants/constants.sv"

module cu
(
	input logic clk, nrst, stall, chng2nop,
	output logic rf_we,
	input logic [`instr_size-1:0] instr_in,
	output logic [`alu_control_size-1:0] ALU_control,
	output logic [`cw_length-1:0] cw_out
);

  localparam  logic [`cw_length-1:0] cw_memory [`cw_mem_size-1:0] =
    {
//       | PC_ENABLE   enabling the incrementing of the PC
//       || FD_REG_EN   pipeline reg
//       ||
//       ||| Reg1_ENABLE
//       |||| Reg2_ENABLE
//       ||||| RegIMM_ENABLE  enabling reg 1, 2, IMM respectively. RegImm will provide the immediate depending on the instruction,
//       |||||| DE_REG_EN   pipeline reg
//       ||||||
//       ||||||| MUXA_SEL  muxing PC and RegA output
//       |||||||| MUXB_SEL   muxing RegB and RegIMM output
//       ||||||||| EM_REG_EN    pipeline reg
//       |||||||||
//       |||||||||| DRAM_WE
//       ||||||||||| DRAM_RE
//       |||||||||||| MW_REG_EN     pipeline reg
//       ||||||||||||
//       ||||||||||||| MUXC_SEL
//       |||||||||||||| MUXD_SEL
//       ||||||||||||||| RF_WE

       'b110011011001101,   // auipc
       'b110011111001101,   // lui
       'b111111111001100,   // branch
       'b110011101001111,   // jal
       'b111011011001111,   // jalr
       'b111011111011001,   // load
       'b111111111101100,   // store
       'b111011111001101,   // immediate
       'b111101101001101,   // rtype
       'b111101101001101,   // fence    rtype opcode
       'b111101101001101    // cstype

    };

    logic [`opcode_size-1:0] opcode;
    logic [`opcode_size-1:0] opcode_pipe;
    logic [`instr_size-1:0] instr_pipe;
    logic [`cw_length-1:0]  cw1, current_cw, prev_cw;
    logic [`cw_length-3:0]  cw2;
    logic [`cw_length-7:0]  cw3;
    logic [`cw_length-9:0]  cw4;

    logic[`regfile_logsize-1:0] rs1_field, rs1_field_previous;		// rs1 for hazards
    logic[`regfile_logsize-1:0] rs2_field, rs2_field_previous;		// rs2 for hazards
    logic[`regfile_logsize-1:0] rd_field, rd_field_previous;		// rd for hazards
    logic[`opcode_size-1:0] opcode_previous, opcode_temp;           // opcode for hazards. temp is
                                                                    //  for having a delay b/w opcode and 
                                                                    //  opcode_previous

    logic [`alu_control_size-1:0] ALU_control_temp;
    
    logic F_stall, FD_stall, F_stall_mem, F_stall_del, FD_stall_del;
    logic[3:0] counter;
    logic counting, start_counting, stop_counting;     // simple flags for starting/resetting the counter
    
    assign rf_we = cw1[0];								
    assign opcode = instr_in[`opcode_size-1:0];
    

        // For the CU fsm
    typedef enum {  
        RESET,
        NORMAL, 
        F_DELAY_MEM
    } statetype;
    
    statetype state, next_state;


// ALU control process    
always_ff @(posedge clk) begin : alu_assign
	if(~nrst)
		ALU_control_temp <= 'h0;
	else begin
		case(opcode_pipe)
		
			`lui_op		: ALU_control_temp <= 'd0;
			`ldtype_op	: ALU_control_temp <= 'd1;
			`stotype_op	: ALU_control_temp <= 'd1;
			`auipc_op	: ALU_control_temp <= 'd2;
			`rtype_op:      

				case (instr_pipe[14:12])      // func field
			    
					`addsub_func:
				
						if (~instr_pipe[`instr_size-2])
							ALU_control_temp <= 'd2;    // ADD
						else
							ALU_control_temp <= 'd9;    // SUB
				    
			    		`xor_func   :   ALU_control_temp <= 'd3;
			    		`or_func    :   ALU_control_temp <= 'd4;
			    		`and_func   :   ALU_control_temp <= 'd5;
					`sll_func   :   ALU_control_temp <= 'd6;
					`srx_func   :   
				
						if (~instr_pipe[`instr_size-2])
				    			ALU_control_temp <= 'd7;    // SRL
						else
				    			ALU_control_temp <= 'd8;    // SRA
				    
			    		`slt_func   :   ALU_control_temp <= 'd10;
			    		`sltu_func  :   ALU_control_temp <= 'd11;
			    
				endcase
		
			`itype_op:
		    
				case (instr_pipe[14:12])      // func field
		    
					`addi_func  :   ALU_control_temp <= 'd2;
					`xori_func  :   ALU_control_temp <= 'd3;
					`ori_func   :   ALU_control_temp <= 'd4;
					`andi_func  :   ALU_control_temp <= 'd5;
					`slli_func  :   ALU_control_temp <= 'd6;
			    		`srxi_func  :   
			    
						if (~instr_pipe[`instr_size-2])
				    			ALU_control_temp <= 'd7;    // SRLI
						else
				    			ALU_control_temp <= 'd8;    // SRAI
			    
			    		`slti_func  :   ALU_control_temp <= 'd10;
			    		`sltiu_func  :   ALU_control_temp <= 'd11;
			    
				endcase
		endcase
	end
end : alu_assign


// Opcode and Instruction pipelined
always_ff @(posedge clk) begin : opcode_pipe_reg
	if(~nrst) begin
		opcode_pipe <= 'h0;
		instr_pipe <= 'h0;
	end
	else begin
		if(~stall) begin
			opcode_pipe <= opcode;
			instr_pipe <= instr_in;
		end
	end
end
    
    
// Assigning the datapath outputs
always_comb begin : out_assign
	if (~nrst)
		cw_out = 'h0;
	else if (FD_stall_del || F_stall || F_stall_mem) begin // If there's a LOAD stall or a BRANCH stall or a LOAD-BRANCH stall, disable the fetch unit 
        
		cw_out = {2'b0, cw1[`cw_length-3: `cw_length-6],
                		cw2[`cw_length-7: `cw_length-9],
                		cw3[`cw_length-10:`cw_length-14],
				cw4[`cw_length-15]};
        
	end
	else begin
    
		cw_out = {current_cw[`cw_length-1], 
                	  current_cw[`cw_length-2], 
                     	  cw1[`cw_length-3: `cw_length-6],
                     	  cw2[`cw_length-7: `cw_length-9],
                     	  cw3[`cw_length-10:`cw_length-14],
                     	  cw4[`cw_length-15]};
        
	end
    
end : out_assign


// ALU Control signal bits
assign ALU_control = ALU_control_temp;


// Super bulky case statement fetching each entry from the internal control word memory_word
always_comb begin : cw_fetch
	if(~nrst | stall)
		current_cw = 'b0;
	else if(FD_stall_del)
		current_cw = prev_cw;
	else begin
		case (opcode)
			`auipc_op		: current_cw = cw_memory[10];
			`lui_op			: current_cw = cw_memory[9];
			`btype_op		: current_cw = cw_memory[8];
			`jal_op			: current_cw = cw_memory[7];
			`jalr_op		: current_cw = cw_memory[6];
			`ldtype_op		: current_cw = cw_memory[5];
			`stotype_op		: current_cw = cw_memory[4];
			`itype_op		: current_cw = cw_memory[3];
			`rtype_op		: current_cw = cw_memory[2];
			`fence_op		: current_cw = cw_memory[1];
			`cstype_op		: current_cw = cw_memory[0];
			'b0			: current_cw = 'b110000000000000;  // enabling pc during icache loading
		endcase
	end
end : cw_fetch


always_ff @(posedge clk) begin : prev_cw_assignment
	if(~nrst)
		prev_cw <= 'h0;
	else
		prev_cw <= current_cw;
end : prev_cw_assignment


    always_comb begin : fsm_comb
    case (state)
        
        RESET : begin
        
            if(~nrst)
                next_state = RESET;
            else
                next_state = NORMAL;
        end
        
        NORMAL : begin
            if (F_stall_mem) 
                next_state = F_DELAY_MEM;
        end

        F_DELAY_MEM :
            if ( stop_counting )
                next_state = NORMAL;
    endcase
    end : fsm_comb


// F_stall_mem counter ctrl logic
always_comb begin : counting_log
	if ( F_stall_mem )
		start_counting = 1;
	else if ( counter == `mem_delay_const )
		stop_counting = 1;
	else begin
		stop_counting = 0;
		start_counting = 0;
	end
end : counting_log


    always_ff @(posedge clk) begin : fsm_seq    // including a counter for memory delay
        
        if (~nrst) begin
            state <= RESET;
            counter <= 'b0;
            counting <= 0;
        end
        
        else begin
            state <= next_state;
            
            if(start_counting)
                counting <= 1;

            if ( counting )
                counter <= counter + 1;
            else if (stop_counting) begin
            
                counting <= 0;
                counter <= 'b0;
                
            end
        end        
        
    end : fsm_seq

    always_ff @(posedge clk) begin : output_logic
        
        F_stall_del <= F_stall;
        FD_stall_del <= FD_stall;
    

        if (~stall) begin            
            case(state)
                
                RESET : begin
                    
                    cw1 <= 'b0;
                    cw2 <= 'b0;
                    cw3 <= 'b0;
                    cw4 <= 'b0;
                
                end
                
                NORMAL : begin
                    if (FD_stall) begin
                        cw1 <= 'h0048;
                        cw2 <= cw1[`cw_length-7:0];                            // Bubble
                        cw3 <= cw2[`cw_length-9:0];
                        cw4 <= cw3[`cw_length-13:0];
                    end    
                    else if (F_stall) begin
                        cw1 <= 'h0248;                            // Bubble
                        cw2 <= cw1[`cw_length-7:0];
                        cw3 <= cw2[`cw_length-9:0];
                        cw4 <= cw3[`cw_length-13:0];
                    end
                    else if (F_stall_mem) begin
                        cw1 <= 'h0248;                            // Bubble
                        cw2 <= cw1[`cw_length-7:0];
                        cw3 <= cw2[`cw_length-9:0];
                        cw4 <= cw3[`cw_length-13:0];
                    end
                    else begin
                        case (opcode)
                          `btype_op     : cw1 <= cw_memory[8];
                          `jal_op       : cw1 <= cw_memory[7];
                          `jalr_op      : cw1 <= cw_memory[6];
                          `ldtype_op    : cw1 <= cw_memory[5];
                          `stotype_op   : cw1 <= cw_memory[4];
                          `itype_op     : cw1 <= cw_memory[3];
                          `rtype_op     : cw1 <= cw_memory[2];
                          `fence_op     : cw1 <= cw_memory[1];
                          `cstype_op    : cw1 <= cw_memory[0];
                          'b0           : cw1 <= 'b10000000000000;  // enabling pc during icache loading
                        endcase
                        
                        cw2 <= cw1[`cw_length-7:0];
                        cw3 <= cw2[`cw_length-9:0];
                        cw4 <= cw3[`cw_length-13:0];

                        if(chng2nop)    // the bpu mispredicted
                            cw1 <= 'b0;
                        else
                            cw1 <= current_cw[`cw_length-3:0];
                    end 
                end
                
                F_DELAY_MEM : begin
			if(F_stall_mem) begin
                        	//cw1 <= 'h0248;                            // Bubble
                        	cw2 <= cw1[`cw_length-7:0];
                        	cw3 <= cw2[`cw_length-9:0];
                        	cw4 <= cw3[`cw_length-13:0];
			end
			else begin
				case (opcode)
                        		`btype_op     : cw1 <= cw_memory[8];
                          		`jal_op       : cw1 <= cw_memory[7];
                          		`jalr_op      : cw1 <= cw_memory[6];
                          		`ldtype_op    : cw1 <= cw_memory[5];
                          		`stotype_op   : cw1 <= cw_memory[4];
                          		`itype_op     : cw1 <= cw_memory[3];
                         		`rtype_op     : cw1 <= cw_memory[2];
                          		`fence_op     : cw1 <= cw_memory[1];
                          		`cstype_op    : cw1 <= cw_memory[0];
                          		'b0           : cw1 <= 'b10000000000000;  // enabling pc during icache loading
                        	endcase

                        	cw2 <= cw1[`cw_length-7:0];
                        	cw3 <= cw2[`cw_length-9:0];
                        	cw4 <= cw3[`cw_length-13:0];

                        	if(chng2nop)    // the bpu mispredicted
                            		cw1 <= 'b0;
                        	else
                            		cw1 <= current_cw[`cw_length-3:0];
                    	end

                end
            endcase 
        end
	else
		if(~nrst) begin
			cw1 <= 'h0;
			cw2 <= 'h0;
			cw3 <= 'h0;
			cw4 <= 'h0;
		end
	//end
    end : output_logic

    // Shifting the reg number to store the previous instruction

    always_ff @(posedge clk) begin : hazard_shift
        if (~nrst) begin
            rs1_field_previous <= 'b0;
            rs2_field_previous <= 'b0;
            rd_field_previous <= 'b0;
            opcode_previous <= 'b0;
        end
	else begin
		if(~(F_stall_mem | FD_stall_del)) begin
			rs1_field_previous <= rs1_field;
			rs2_field_previous <= rs2_field;
			rd_field_previous <= rd_field;
			opcode_temp <= opcode;
			opcode_previous <= opcode_temp;
		end
        end
    end : hazard_shift


// Decoding the operands for hazard detection
// RegisterSource_1 Field
always_comb begin : rs1_assign
	if((opcode == `jal_op) || (opcode == `lui_op) || (opcode == `auipc_op))
		rs1_field = 'h0;
	else
		rs1_field = instr_in[19:15];
end : rs1_assign


// RegisterSource_2 Field
always_comb begin :  rs2_assign
	if((opcode == `jal_op) || (opcode == `lui_op) || (opcode == `auipc_op) || (opcode == `ldtype_op) || (opcode == `itype_op))
		rs2_field = 'h0;
	else
		rs2_field = instr_in[24:20];
end : rs2_assign


// RegisterDestination (Writing Reg) Field
always_comb begin : rdw_assign
	if((opcode == `stotype_op) || (opcode == `btype_op))
		rd_field = 'h0;
	else
		rd_field = instr_in[11:7];
end : rdw_assign


// Add the comparison b/w rd_current and previous and the appropriate masking to stall them
// F_stall and F_stall_mem are separated to have a different number of cycle stalls
//      if and when we decide to emulate memory latencies
always_comb begin : hdu
    
	if((rs1_field == rd_field_previous) || (rs2_field == rd_field_previous)) begin
		if (rd_field_previous != 'b0) begin
			if (opcode_temp == `ldtype_op) begin      // First Load then branch
				if ((opcode == `btype_op) && (counter != 4'h1))
					F_stall_mem = 1;        // Branch
				else if ((opcode == `btype_op) && (counter == 4'h1))
					F_stall_mem = 0;
				else
					FD_stall = 1;           // Any
			end
			else if (opcode == `btype_op) begin           // any / branch
				FD_stall = 0;
				F_stall_mem = 0;
				F_stall = 1;
			end
			else begin
				FD_stall = 0;
				F_stall_mem = 0;
				F_stall = 0;
			end
               	end
	end
	else begin 
		FD_stall = 0;
		F_stall_mem = 0;
		F_stall = 0;
	end

end : hdu

endmodule
