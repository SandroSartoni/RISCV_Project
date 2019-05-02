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
//       |
//       || Reg1_ENABLE
//       ||| Reg2_ENABLE
//       |||| RegIMM_ENABLE  enabling reg 1, 2, IMM respectively. RegImm will provide the immediate depending on the instruction,
//       ||||
//       ||||| MUXA_SEL  muxing PC and RegA output
//       |||||| MUXB_SEL   muxing RegB and RegIMM output
//       ||||||
//       ||||||| DRAM_WE
//       |||||||| DRAM_RE
//       ||||||||
//       ||||||||| MUXC_SEL
//       |||||||||| MUXD_SEL
//       ||||||||||| RF_WE

       'b11111100000,   // branch
       'b10011000011,   // jal
       'b11010100011,   // jalr
       'b11011101001,   // load
       'b11111110000,   // store
       'b11011100001,   // immediate
       'b11101000001,   // rtype
       'b11101000001,   // fence    rtype opcode
       'b11101000001    // cstype

    };

  logic [`opcode_size-1:0] opcode;
  logic [`cw_length-1:0]  cw1, current_cw;
  logic [`cw_length-3:0]  cw2;
  logic [`cw_length-7:0]  cw3;
  logic [`cw_length-9:0]  cw4;
  logic [`cw_length-11:0] cw5;

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
  end

  always_ff @(clk) begin : cw_shift
    if (!nrst | stall)
      cw1 <= 'b0;
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
  end
endmodule
