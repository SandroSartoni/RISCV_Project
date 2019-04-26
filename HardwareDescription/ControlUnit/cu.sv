`include "constants.sv"

module cu
(
    input logic clk, nrst,
    input logic [`instr_size-1:0] instr_in,
    output logic [`cw_length-1:0] cw_out
);

  localparam  logic [`cw_length:0] cw_memory [`cw_mem_size:0] =
    {
//		   | IR_ENABLE  enabling the fetching of intructions
//       || PC_ENABLE   enabling the incrementing of the PC
//       ||
//       ||| Reg1_ENABLE
//       |||| Reg2_ENABLE
//       ||||| RegIMM_ENABLE  enabling reg 1, 2, IMM respectively
//       |||||
//       |||||| MUXA_SEL  muxing PC and RegA output
//       ||||||| MUXB_SEL   muxing RegB and RegIMM output
//       |||||||| ALU_OUTREG_EN   outputting ALU result
//       ||||||||| EQ_COND          leaving this in place for beq&bne distinction
//       |||||||||
//       |||||||||| DRAM_WE
//       ||||||||||| DRAM_RE
//       |||||||||||| JUMP_EN
//       ||||||||||||| BRANCH_EN
//       |||||||||||||| PC_LATCH_EN
//       ||||||||||||||
//       ||||||||||||||| WB_MUX_SEL
//       |||||||||||||||| RF_WE
//       ||||||||||||||||| RF_W31_E
//       |||||||||||||||||| IS_SIGNED
//       ||||||||||||||||||| SIGN_EXTENDER
//       |||||||||||||||||||| SAVE_SIGN

       'b00000000000000000000,   // branch
       'b00000000000000000000,   // jal
       'b00000000000000000000,   // jalr
       'b00000000000000000000,   // load
       'b00000000000000000000,   // store
       'b00000000000000000000,   // immediate
       'b00000000000000000000,   // rtype
       'b00000000000000000000,   // fence
       'b00000000000000000000    // cstype

    };
