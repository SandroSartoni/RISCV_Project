`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/shiftRegister.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/register.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/kernelLogic.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/mux4to1.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/mux2to1.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/adder.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/carrySaveAdder.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/syncCounter.sv"
`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/comparator.sv"


module MultDivUnitDP (clk,rst_n,opCode,lOp,rOp,result,res_ready,div_by_zero,div_overflow,lOp_en,divisor_lShift,notLOp_en,saveReminder,sumMux_sel,carryMux_sel,sum_en,carry_en,leftAddMux_sel,rightAddMux_sel,QCorrectBitMux_sel,rightAddMode,lRes_en,rRes_en,reminder_rShift,counterMux_sel,thrMux_sel,count_upDown,count_load,count_en,counterReg_en,prevReg_en,tc,signS,magnitudeD,csa_clear);
  parameter parallelism=32;
  input clk;
  input rst_n;
  input [2:0] opCode;
  input [parallelism-1:0] lOp;
  input [parallelism-1:0] rOp;
  output [parallelism-1:0] result;
  output res_ready;
  output div_by_zero;
  output div_overflow;
  //control signals
  input lOp_en;
  input divisor_lShift;
  input notLOp_en;
  input saveReminder;
  input [1:0] sumMux_sel;
  input carryMux_sel;
  input sum_en;
  input carry_en;
  input [1:0] leftAddMux_sel;
  input [1:0] rightAddMux_sel;
  input QCorrectBitMux_sel;
  input rightAddMode;
  input lRes_en;
  input rRes_en;
  input reminder_rShift;
  input counterMux_sel;
  input thrMux_sel;
  input count_upDown;
  input count_load;
  input count_en;
  input counterReg_en;
  input prevReg_en;
  input csa_clear;
  output tc;
  output signS;
  output [1:0] magnitudeD;
  //signals
  logic usignedL,usignedR;
  logic [parallelism:0] signCorrection_to_lOpReg;
  logic [parallelism:0] signCorrection_to_rOpReg;
  logic [parallelism:0] lOp_to_kernelLogic;
  logic [parallelism+2:0] sumHMux_to_sumHReg;
  logic [parallelism+1:0] sumLMux_to_sumLReg;
  logic [parallelism+2:0] carryHMux_to_carryHReg;
  logic [parallelism:0] notLOp_to_kernelLogic;
  logic [parallelism:0] leftAdder_to_outReg;
  logic [parallelism:0] firstPP;
  logic [parallelism+2:0] sumH;
  logic [parallelism+1:0] sumL;
  logic [parallelism+2:0] carryH;
  logic [parallelism-1:0] carryL;
  logic [parallelism-1:0] quotientCorrectBit;
  logic SignSel;
  logic Non0;
  logic newNQ;
  logic newQ;
  logic [parallelism:0] kl_to_csa;
  logic [parallelism+1:0] csaSum_to_outReg;
  logic [parallelism+1:0] csaCarry_to_outReg;
  logic [parallelism:0] leftOpleftAdd;
  logic [parallelism:0] rightOpleftAdd;
  logic [parallelism-1:0] leftOprightAdd;
  logic [parallelism-1:0] rightOprightAdd;
  logic [parallelism:0] sum_to_outAdders;
  logic [parallelism:0] carry_to_outAdders;
  logic [parallelism-1:0] rightAdder_to_outReg;
  logic [parallelism-1:0] rResOutReg;
  logic [parallelism+1:0] lResOutReg;
  logic [parallelism-1:0] res;
  logic [5:0] counterMux_to_counter;
  logic [5:0] thrMux_to_thr;
  logic [5:0] counterOut_to_counterReg;
  logic [5:0] counterRegOut;
  logic [2:0] prevOpCode;
  logic [parallelism-1:0] prevLOp;
  logic [parallelism-1:0] prevROp;
  logic lEquality;
  logic rEquality;
  logic opEquality;
  logic divZero;
  logic min;
  logic maxPos;

  //logic for driving usigned signals:
  //opCode  usignedL  usignedR
  //000         /         /
  //001         0         0
  //010         0         1
  //011         1         1
  //100-110     0         0
  //101-111     1         1
  always_comb begin
    case (opCode)
      3'b010:begin
        usignedL=1;
        usignedR=0;
      end
      3'b011:begin
        usignedL=1;
        usignedR=1;
      end
      3'b101:begin
        usignedL=1;
        usignedR=1;
      end
      3'b111:begin
        usignedL=1;
        usignedR=1;
      end
      default: begin
        usignedL=0;
        usignedR=0;
      end
    endcase
  end

  //sign extension 32->33 bits
  assign signCorrection_to_lOpReg = (usignedL) ? {1'b0,lOp[parallelism-1:0]} : {lOp[parallelism-1],lOp[parallelism-1:0]};
  assign signCorrection_to_rOpReg = (usignedR) ? {1'b0,rOp[parallelism-1:0]} : {rOp[parallelism-1],rOp[parallelism-1:0]};

  //left operand shift register
  shiftRegister #(parallelism+1) lOpRegister (  .parallelIn(signCorrection_to_lOpReg),
                                                .parallelOut(lOp_to_kernelLogic),
                                                .clk(clk),
                                                .rst_n(rst_n),
                                                .clear(csa_clear),
                                                .sample_en(lOp_en),
                                                .shiftLeft(divisor_lShift),
                                                .shiftRight(1'b0),
                                                .newBit(1'b0));
  assign magnitudeD = lOp_to_kernelLogic[parallelism-1:parallelism-2];
  //not left operand register
  register #(parallelism+1) notLOpRegister (  .parallelIn(leftAdder_to_outReg),
                                              .parallelOut(notLOp_to_kernelLogic),
                                              .clk(clk),
                                              .rst_n(rst_n),
                                              .clear(csa_clear),
                                              .sample_en(notLOp_en));

  //
  kernelLogic #(.parallelism(parallelism)) KL ( .data(lOp_to_kernelLogic),
                                                .notData(notLOp_to_kernelLogic),
                                                .saveReminder(saveReminder),
                                                .opCode(opCode),
                                                .sumMSBs(sumH[parallelism+2:parallelism-2]), //5 in this case(3.2)
                                                .carryMSBs(carryH[parallelism+2:parallelism-2]),
                                                .multDecisionBits(sumL[1:0]),
                                                .SignSel(SignSel),
                                                .Non0(Non0),
                                                .outData(kl_to_csa),
                                                .d_MSB(signCorrection_to_lOpReg[parallelism]));
  //first partial product for multiplication (33bits)
  assign firstPP = (signCorrection_to_rOpReg[0]) ? leftAdder_to_outReg : {parallelism+1{1'b0}};

  //mux access to sumH 35 bits (3.32)
  mux4to1 #(parallelism+3) sumHMux ( .inA({signCorrection_to_rOpReg[parallelism],signCorrection_to_rOpReg[parallelism],signCorrection_to_rOpReg}), //we need to multiply *2
                                    .inB({csaSum_to_outReg[parallelism+1:0],1'b0}),
                                    .inC({{2{csaSum_to_outReg[parallelism+1]}},csaSum_to_outReg[parallelism+1:1]}),
                                    .inD({{3{firstPP[parallelism]}},firstPP[parallelism:1]}),
                                    .out(sumHMux_to_sumHReg),
                                    .sel(sumMux_sel));
  //sumH register
  register #(parallelism+3) sumHReg (  .parallelIn(sumHMux_to_sumHReg),
                                    .parallelOut(sumH),
                                    .clk(clk),
                                    .rst_n(rst_n),
                                    .clear(csa_clear),
                                    .sample_en(sum_en));

  //new quotient bit
  assign newQ = (Non0 & ~SignSel);
  //mux access to sumL 34 bits
  mux4to1 #(parallelism+2) sumLMux ( .inA({parallelism+2{1'b0}}),
                                    .inB({sumL[parallelism:0],newQ}),
                                    .inC({csaSum_to_outReg[0],sumL[parallelism+1:1]}),
                                    .inD({firstPP[0],signCorrection_to_rOpReg}),
                                    .out(sumLMux_to_sumLReg),
                                    .sel(sumMux_sel));
  //sumL register
  register #(parallelism+2) sumLReg (  .parallelIn(sumLMux_to_sumLReg),
                                  .parallelOut(sumL),
                                  .clk(clk),
                                  .rst_n(rst_n),
                                  .clear(csa_clear),
                                  .sample_en(sum_en));
  //carryHMux
  mux2to1 #(parallelism+3) carryHMux ( .inA({csaCarry_to_outReg[parallelism:0],2'b0}),
                                    .inB({{2{csaCarry_to_outReg[parallelism+1]}},csaCarry_to_outReg[parallelism:0]}),
                                    .out(carryHMux_to_carryHReg),
                                    .sel(carryMux_sel));
  //carryH
  register #(parallelism+3) carryHReg (  .parallelIn(carryHMux_to_carryHReg),
                                    .parallelOut(carryH),
                                    .clk(clk),
                                    .rst_n(rst_n),
                                    .clear(csa_clear),
                                    .sample_en(carry_en));
  //new quotient not bit
  assign newNQ = (Non0 & SignSel);
  //carryL register
  register #(parallelism) carryLReg (  .parallelIn({carryL[parallelism-2:0],newNQ}),
                                  .parallelOut(carryL),
                                  .clk(clk),
                                  .rst_n(rst_n),
                                  .clear(csa_clear),
                                  .sample_en(carry_en));

  //carrysave adder
  carrySaveAdder #(parallelism+2) csa ( .addendA({kl_to_csa[parallelism],kl_to_csa[parallelism:0]}),
                                      .addendB(sumH[parallelism+1:0]),
                                      .addendC(carryH[parallelism+1:0]),
                                      .sum(csaSum_to_outReg),
                                      .carry(csaCarry_to_outReg));

  ///if it's the last step of the division we need to divide by 2
  // since it was already done automatically at the previous step
  assign sum_to_outAdders = (saveReminder) ? {sumH[parallelism+1:1]} : {1'b0,sumH[parallelism-2:0],sumL[parallelism+1]};
  assign carry_to_outAdders = (saveReminder) ? {carryH[parallelism+1:1]} : {1'b0,carryH[parallelism-2:0],1'b0};

  //mux left operand left adder
  mux4to1 #(parallelism+1) leftOpleftAdd_mux (  .inA(sum_to_outAdders),
                                              .inB(~lOp_to_kernelLogic),
                                              .inC(lOp_to_kernelLogic),
                                              .inD(notLOp_to_kernelLogic),
                                              .out(leftOpleftAdd),
                                              .sel(leftAddMux_sel));
  //mux right operand left adder
  mux4to1 #(parallelism+1) rightOpleftAdd_mux (  .inA(carry_to_outAdders),
                                              .inB({{parallelism{1'b0}},1'b1}),
                                              .inC(lResOutReg[parallelism+1:1]),
                                              .inD(lResOutReg[parallelism+1:1]),
                                              .out(rightOpleftAdd),
                                              .sel(leftAddMux_sel));
  //mux left operand right adder
  mux4to1 #(parallelism) leftOprightAdd_mux (  .inA(sumL[parallelism-1:0]),
                                              .inB(rResOutReg),
                                              .inC(~rResOutReg),
                                              .inD(sumL[parallelism:1]),
                                              .sel(rightAddMux_sel),
                                              .out(leftOprightAdd));
  //mux correct bit
  mux2to1 #(parallelism) QCorrectBit_mux (    .inA({{parallelism-1{1'b0}},1'b1}),
                                              .inB({{parallelism{1'b1}}}),
                                              .out(quotientCorrectBit),
                                              .sel(QCorrectBitMux_sel));

  //mux right op right adder
  mux4to1 #(parallelism) rightOprightAdd_mux (  .inA(~carryL[parallelism-1:0]),
                                              .inB(quotientCorrectBit),
                                              .inC({parallelism{1'b0}}),
                                              .inD({parallelism{1'b0}}),
                                              .sel(rightAddMux_sel),
                                              .out(rightOprightAdd));
  //left adder
  adder #(parallelism+1) leftAdder (  .add1(leftOpleftAdd),
                                    .add0(rightOpleftAdd),
                                    .carry_in(1'b0),
                                    .sum(leftAdder_to_outReg));
  //right adder
  adder #(parallelism) rightAdder (  .add1(leftOprightAdd),
                                    .add0(rightOprightAdd),
                                    .carry_in(rightAddMode),
                                    .sum(rightAdder_to_outReg));

  //reminder - prodH
  shiftRegister #(parallelism+2) remProdHRegister (  .parallelIn({leftAdder_to_outReg,1'b0}),
                                                    .parallelOut(lResOutReg),
                                                    .clk(clk),
                                                    .rst_n(rst_n),
                                                    .clear(1'b0),
                                                    .sample_en(lRes_en),
                                                    .shiftLeft(1'b0),
                                                    .shiftRight(reminder_rShift),
                                                    .newBit(lResOutReg[parallelism+1]));
  assign signS = (lResOutReg[parallelism+1]);

  //quotient - prodL
  register #(parallelism) quoProdLReg (  .parallelIn(rightAdder_to_outReg),
                                        .parallelOut(rResOutReg),
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .clear(1'b0),
                                        .sample_en(rRes_en));
  //assigning result
  assign result = res;
  always_comb begin
    case (opCode)
      3'b000: res=rResOutReg;
      3'b001: res=lResOutReg[parallelism:1];
      3'b010: res=lResOutReg[parallelism:1];
      3'b011: res=lResOutReg[parallelism:1];
      3'b100: res=rResOutReg;
      3'b101: res=rResOutReg;
      3'b110: res=lResOutReg[parallelism-1:0];
      3'b111: res=lResOutReg[parallelism-1:0];
      default: res={parallelism{1'b0}};
    endcase
  end
  //counter module
  mux2to1 #(6) counterMux (  .inA(6'b000001),
                              .inB(counterRegOut), //remember to set input carry
                              .out(counterMux_to_counter),
                              .sel(counterMux_sel));
  //threashold multiplexer
  mux2to1 #(6) threasholdMux (  .inA(6'b000001),
                              .inB(6'b011111), //remember to set input carry
                              .out(thrMux_to_thr),
                              .sel(thrMux_sel));

  syncCounter #(6) counter ( .clk(clk),
                            .rst_n(rst_n),
                            .clear(csa_clear),
                            .parallelLoad(counterMux_to_counter),
                            .threashold(thrMux_to_thr),
                            .upDown_n(count_upDown),
                            .load_en(count_load),
                            .cnt_en(count_en),
                            .terminalCount(tc),
                            .parallelOutput(counterOut_to_counterReg));

  register #(6) counterReg (  .parallelIn(counterOut_to_counterReg),
                              .parallelOut(counterRegOut),
                              .clk(clk),
                              .rst_n(rst_n),
                              .clear(csa_clear),
                              .sample_en(counterReg_en));

  //feedback circuit
  //leftOp
  register #(parallelism) prevLopReg (  .parallelIn(lOp),
                                        .parallelOut(prevLOp),
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .clear(1'b0),
                                        .sample_en(prevReg_en));
  //rightOp
  register #(parallelism) prevRopReg (  .parallelIn(rOp),
                                        .parallelOut(prevROp),
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .clear(1'b0),
                                        .sample_en(prevReg_en));
  //prevOp
  register #(3) prevOpReg (  .parallelIn(opCode),
                              .parallelOut(prevOpCode),
                              .clk(clk),
                              .rst_n(rst_n),
                              .clear(1'b0),
                              .sample_en(prevReg_en));
  //lcomp
  comparator #(parallelism) left_comparator ( .inA(lOp),
                                            .inB(prevLOp),
                                            .isEqual(lEquality));
  comparator #(parallelism) right_comparator ( .inA(rOp),
                                            .inB(prevROp),
                                            .isEqual(rEquality));
  always_comb begin
    if ((((prevOpCode==3'b001) || (prevOpCode==3'b010) || (prevOpCode==3'b011)) && (opCode==3'b000)) || (((opCode==3'b100) || (opCode==3'b110)) && ((prevOpCode==3'b100) || (prevOpCode==3'b110))) || (((opCode==3'b101) || (opCode==3'b111)) && ((prevOpCode==3'b101) || (prevOpCode==3'b111))) || (opCode==prevOpCode)) begin
      opEquality=1'b1;
    end else begin
      opEquality=1'b0;
    end
  end
  assign res_ready = (lEquality & rEquality & opEquality);

  comparator #(parallelism) zero_comparator ( .inA(lOp),
                                            .inB({parallelism{1'b0}}),
                                            .isEqual(divZero));
  assign div_by_zero = (divZero & opCode[2]);
  comparator #(parallelism) min_comparator ( .inA(lOp),
                                            .inB({parallelism{1'b1}}),
                                            .isEqual(min));
  comparator #(parallelism) maxPos_comparator ( .inA(rOp),
                                            .inB({1'b0,{parallelism-1{1'b1}}}),
                                            .isEqual(maxPos));
  assign div_overflow = (min & maxPos & opCode[2]);
endmodule
