// TODO LIST:
// - Basic pipelining
// - Pipeline flushing when mispredicted
// - Stalling logic

`include "constants.sv"

module cu
(
    input logic posedge clk, nrst, stall, chng2nop,
    input logic [`instr_size-1:0] instr_in,
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
                        
       'b111111110100100,   // branch
       'b110011100100111,   // jal
       'b111011010100111,   // jalr
       'b111011110110101,   // load
       'b111111111100100,   // store
       'b111011110100101,   // immediate
       'b111101100100101,   // rtype
       'b111101100100101,   // fence    rtype opcode
       'b111101100100101    // cstype

    };

    logic [`opcode_size-1:0] opcode;
    logic [`cw_length-1:0]  cw1, current_cw;
    logic [`cw_length-3:0]  cw2;
    logic [`cw_length-7:0]  cw3;
    logic [`cw_length-9:0]  cw4;
    logic [`cw_length-11:0] cw5;

    logic[`regfile_logsize-1:0] rs1_field, rs1_field_previous;		// rs1 for hazards
    logic[`regfile_logsize-1:0] rs2_field, rs2_field_previous;		// rs2 for hazards
    logic[`regfile_logsize-1:0] rd_field, rd_field_previous;		// rd for hazards
    logic[`opcode_size-1:0] opcode_previous;                        // opcode for hazards
    
    assign opcode = instr_in[`opcode_size-1:0];

    logic F_stall, FD_stall;
    logic[3:0] counter;
    logic counting;     // simple flag for starting/resetting the counter
    
    statetype state, next_state;

    //super bulky case statement fetching each entry from the internal control word memory_word
    always_comb begin : cw_fetch
    case (opcode)
      `branch_group : current_cw = cw_memory[0];
      `jal_op       : current_cw = cw_memory[1];
      `jalr_op      : current_cw = cw_memory[2];
      `ldtype_op    : current_cw = cw_memory[3];
      `stotype_op   : current_cw = cw_memory[4];
      `itype_op     : current_cw = cw_memory[5];
      `rtype_op     : current_cw = cw_memory[6];
      `fence_op     : current_cw = cw_memory[7];
      `cstype_op    : current_cw = cw_memory[8];
    endcase
    end : cw_fetch

    always_comb begin : fsm_comb
    case (state)
        NORMAL :
            if (FD_stall)
                next_state = FD_DELAY_ONE;
            if (F_stall)
                next_state = F_DELAY_ONE;
            if (F_stall_mem) 
                next_state = F_DELAY_MEM;
                
        FD_DELAY_ONE :
            next_state = NORMAL;
        F_DELAY_ONE:
            next_state = NORMAL;
        F_DELAY_MEM :
            if ( counter == `mem_delay_const )
                next_state = NORMAL
    endcase
    if ( F_stall_mem )
        counting = 1;
    
    if ( counter == `mem_delay_const )
        counting = 0;
        
    end : fsm_comb

    always_ff @(posedge clk) begin : fsm_seq    // including a counter for memory delay
        
        if (~nrst)
            state <= RESET;
            counter <= 'b0;
            
        else 
            state <= next_state;
            if ( counting )
                counter <= counter + 1;
            else 
                counter = 'b0
    end : fsm_seq

    always_ff @(posedge clk) begin : output_logic
        if (stall)
            cw1 <= 'b0;
        if (~nrst) begin
            cw2 <= 'b0;
            cw3 <= 'b0;
            cw4 <= 'b0;
            cw5 <= 'b0;
        end
      
        else begin            
            case(state)
                NORMAL :
                    cw1 <= current_cw;
                    cw3 <= cw2[`cw_length-7:0];
                    cw4 <= cw3[`cw_length-9:0];
                    cw5 <= cw4[`cw_length-13:0];

                    if(chng2nop)    // the bpu mispredicted
                        cw2 <= 'b0;
                    else
                        cw2 <= cw1[`cw_length-3:0];
                
                FD_DELAY : 
                    cw1 <= {1'b0, cw1[`cw_length-1:0]};    // Disabling PC for one clk
                    cw2 <= cw2;
                    cw3 <= 'b0;                            // Bubble
                    cw4 <= cw2[`cw_length-9:0];
                    cw5 <= cw4[`cw_length-13:0];
                
                F_DELAY :
                    cw1 <= {1'b0, cw1[`cw_length-1:0]};    // Disabling PC for one clk
                    cw2 <= 'b0;                            // Bubble
                    cw3 <= cw1[`cw_length-7:0];
                    cw4 <= cw3[`cw_length-9:0];
                    cw5 <= cw4[`cw_length-13:0];
               
                F_DELAY_MEM :
                    cw1 <= {1'b0, cw1[`cw_length-1:0]};    // Disabling PC for one clk
                    cw2 <= 'b0;                            // Bubble
                    cw3 <= cw1[`cw_length-7:0];
                    cw4 <= cw3[`cw_length-9:0];
                    cw5 <= cw4[`cw_length-13:0];                
            endcase 
        end
    end : output_logic

    // Shifting the reg number to store the previous instruction's

    always_ff @(posedge clk) begin : hazard_shift
    
        rs1_field_previous <= rs1_field;
        rs2_field_previous <= rs2_field;
        rd_field_previous <= rd_field;
        opcode_previous <= opcode;
        
        if (!nrst) begin
            rs1_field_previous <= 'b0;
            rs2_field_previous <= 'b0;
            rd_field_previous <= 'b0;
            opcode_previous <= 'b0;
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

    // Logic for having the comparison:
    
    always_comb begin : hdu
        if( (rd_field == rs1_field_previous) || (rd_field == rs2_field_previous) ) begin
            if ( rd_field != 'b0 ) begin
                
                if ( opcode == `ldtype_op )         // First Load then ANY
                    FD_stall = 1
                else if ( opcode == `btype_op )     // First Branch then
                    if ( opcode_previous == `ldtype_op )    // Load
                        F_stall_mem = 1         // different state for different number of stalls
                    else                                    // OTHERS
                        F_stall = 1
                else 
                    
                    FD_stall = 0
                    F_stall_mem = 0
                    F_stall = 0
                end
            end
        end

endmodule
