// TODO LIST:
// - Basic pipelining
// - Pipeline flushing when mispredicted
// - Stalling logic

`include "constants.sv"

module cu
(
    input logic clk, nrst, stall, chng2nop,
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

       'b1111111100000,   // branch
       'b1100111000011,   // jal
       'b1110101100011,   // jalr
       'b1110111101001,   // load
       'b1111111110000,   // store
       'b1110111100001,   // immediate
       'b1111011000001,   // rtype
       'b1111011000001,   // fence    rtype opcode
       'b1111011000001    // cstype

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

  assign opcode = instr_in[`opcode_size-1:0];

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

  always_ff @(clk) begin : cw_shift
    if (stall)
      cw1 <= 'b0;
      if (!nrst) begin
        cw2 <= 'b0;
        cw3 <= 'b0;
        cw4 <= 'b0;
        cw5 <= 'b0;
      end
      
    else begin
      cw1 <= current_cw;
      cw3 <= cw2[`cw_length-7:0];
      cw4 <= cw3[`cw_length-9:0];
      cw5 <= cw4[`cw_length-11:0];

      if(chng2nop)    // the bpu mispredicted
        cw2 <= 'b0;
      else
        cw2 <= cw1[`cw_length-3:0];
    end
  end : cw_shift

    // Shifting the reg number to store the previous instruction's

    always_ff @(clk) begin : hazard_shift
    
        rs1_field_previous <= rs1_field;
        rs2_field_previous <= rs2_field;
        rd_field_previous <= rd_field;
        
        if (!nrst) begin
            rs1_field_previous <= 'b0;
            rs2_field_previous <= 'b0;
            rd_field_previous <= 'b0;
        end
    
    end : hazard_shift

    // Decoding the operands to determine the hazards

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

endmodule
