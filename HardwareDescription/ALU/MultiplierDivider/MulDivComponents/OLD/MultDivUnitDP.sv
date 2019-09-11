module MultDivUnitDP (clk,rst_n,opCode,operand0,operand1,result,res_ready,div_by_zero,overflow_div,overflow_mult,previousDataRegn_en,ad_en,divisor_lShift,notAd_en,sumH_sel,sumL_sel,carryH_sel,carryL_sel,sumH_sel,regn_clr,rev_en,carrySave_sel,sumH_en,sumL_en,carryH_en,carryL_en,op_lxAdd_sel,lxOp_rxAdd_sel,rxOp_rxAdd_sel);
  parameter parallelism=32;
  parameter opCode_width=3;
  input clk;
  input rst_n;
  input [opCode_width-1:0] opCode;
  input [parallelism-1:0] operand0; //multiplicand/divisor
  input [parallelism-1:0] operand1; //multiplier/dividend
  output [parallelism-1:0] result;
  output res_ready;
  output div_by_zero;
  output overflow_div;
  output overflow_mult;
  //control signals
  input previousDataRegn_en;
  input ad_en;
  input divisor_lShift;
  input notAd_en;
  input [1:0] sumH_sel;
  input [1:0] sumL_sel;
  input carryH_sel;
  input carryL_sel;
  input sumH_en;
  input sumL_en;
  input carryH_en;
  input carryL_en;
  input regn_clr;
  input rev_en;
  input save_reminder;
  input carrySave_sel;
  input op_lxAdd_sel;
  input lxOp_rxAdd_sel;
  input rxOp_rxAdd_sel;
  //signals
  logic [parallelism-1:0] adReg_to_comparator;
  logic [parallelism-1:0] mzReg_to_comparator;
  logic [parallelism-1:0] carrylMux_to_carryL;
  logic [parallelism-1:0] carryL_to_rev;
  logic opFF_to_comparator;
  logic ad_Equality;
  logic mz_Equality;
  logic opPrec_Equality;
  logic SignSel;
  logic Non0;
  logic [parallelism:0] op0_to_regn;
  logic [parallelism:0] op1_to_regn;
  logic [parallelism:0] ad_to_kernelLogic;
  logic [parallelism:0] leftAdder_to_outReg;
  logic [parallelism:0] notAd_to_kernelLogic;
  logic [parallelism:0] csaSum;
  logic [parallelism:0] csaCarry;
  logic [parallelism:0] condSum_to_rev;
  logic [parallelism:0] sumhMux_to_sumH;
  logic [parallelism:0] sumlMux_to_sumL;
  logic [parallelism:0] sumH_to_cond2;
  logic [parallelism:0] sumL_to_rev;
  logic [parallelism:0] remCorrectionH_to_csa;
  logic [parallelism:0] carryH_to_remCorrection;
  logic [parallelism:0] remCorrectionL_to_csa;
  logic [parallelism:0] kl_to_csa;
  logic [parallelism:0] sumRev_to_sumlMux;
  logic [parallelism:0] sumlRevOutput_in;
  logic [parallelism:0] sumlRev_to_csa;
  logic [parallelism:0] op2Mux_to_csa;
  logic [parallelism:0] op3Mux_to_csa;
  logic [parallelism:0] carryhMux_to_carryH;
  logic [parallelism:0] revSum_to_remCorrection;
  logic [parallelism:0] carryHRev_to_csa;
  logic [parallelism:0] carrylRevOutput_in;
  logic [parallelism:0] carrylRev_to_csa;
  logic [parallelism:0] rev_to_carryL;
  logic [parallelism:0] carryhMux_to_carryH;
  logic [parallelism:0] lxOp1Mux_to_lxOp1Adder;
  logic [parallelism:0] lxOp0Mux_to_lxOp0Adder;
  logic [parallelism:0] rxOp1Mux_to_rxOp1Adder;
  logic [parallelism:0] corrMux_to_rxOp0Adder;
  logic [parallelism:0] rxOp0Mux_to_rxOp0Adder;

  //begin describing architecture

  //////////////////SAME DATA AS PREVIOS OPERATION HW PART/////////////////////
  //a/d(t-1) register
  register #(parallelism) a_d ( .parallelIn(operand0),
                                .parallelOut(adReg_to_comparator),
                                .clk(clk),
                                .rst_n(rst_n),
                                .clear(1'b0),
                                .sample_en(previousDataRegn_en));
  //m/z(t-1) register
  register #(parallelism) m_z ( .parallelIn(operand1),
                                .parallelOut(mzReg_to_comparator),
                                .clk(clk),
                                .rst_n(rst_n),
                                .clear(1'b0),
                                .sample_en(previousDataRegn_en));
  //previous operation ff
  register #(1) opPrec_ff     ( .parallelIn(opCode[2]),
                                .parallelOut(opFF_to_comparator),
                                .clk(clk),
                                .rst_n(rst_n),
                                .clear(1'b0),
                                .sample_en(previousDataRegn_en));
  comparator #(parallelism) ad_comparator ( .inA(adReg_to_comparator),
                                            .inB(operand0),
                                            .isEqual(ad_Equality));
  comparator #(parallelism) mz_comparator ( .inA(mzReg_to_comparator),
                                            .inB(operand1),
                                            .isEqual(mz_Equality));
  comparator #(1) opPrec_comparator ( .inA(opFF_to_comparator),
                                      .inB(opCode[2]),
                                      .isEqual(opPrec_Equality));
  assign res_ready= ad_Equality & mz_Equality & opPrec_Equality;

  /////////////////////////////DIV BY ZERO DETECTION///////////////////////////
  divZeroDetect #(parallelism) divZeroDetect ( .divisor(operand0),
                                                .divByZero(div_by_zero));
  assign div_by_zero = (source);

  ///////////////////////////DIV OVERFLOW DETECTION////////////////////////////
  divOvfDetectBlock #(parallelism) divOvfDetectBlock (  .divisor(operand0),
                                                        .dividend(operand1),
                                                        .overflow(overflow_div));
  ///////////////////////////////////CONDITIONING//////////////////////////////
  operand0Conditioning #( .PAR(parallelism),.OPCODE_WIDTH(opCode_width)) operand0Conditioning ( .signalIn(operand0),
                                                                                                .signalOut(op0_to_regn),
                                                                                                .opCode(opCode));
  operand1Conditioning #( .PAR(parallelism),.OPCODE_WIDTH(opCode_width)) operand1Conditioning ( .signalIn(operand1),
                                                                                                .signalOut(op1_to_regn),
                                                                                                .opCode(opCode));
  //multiplicand and divisor (shift) register
  shiftRegister #(parallelism+1) adRegister ( .parallelIn(operand0),
                                              .parallelOut(ad_to_kernelLogic),
                                              .clk(clk),
                                              .rst_n(rst_n),
                                              .clear(1'b0),
                                              .sample_en(ad_en),
                                              .shiftLeft(divisor_lShift),
                                              .shiftRight(1'b0),
                                              .newBit(1'b0));
  //multiplicand and divisor 2's complement
  register #(parallelism+1) notAdRegister ( .parallelIn(leftAdder_to_outReg),
                                            .parallelOut(notAd_to_kernelLogic),
                                            .clk(clk),
                                            .rst_n(rst_n),
                                            .clear(1'b0),
                                            .sample_en(notAd_en));
  //input mux for SumH
  mux4to1 #(parallelism+1) inSumH_mux ( .inA(op1_to_regn),
                                        .inB({csaSum[parallelism-1:0],1'b0}),
                                        .inC(condSum_to_rev),
                                        .inD({parallelism+1{1'b0}}),
                                        .sel(sumH_sel),
                                        .out(sumhMux_to_sumH));
  //sumH register
  register #(parallelism+1) sumH (  .parallelIn(sumhMux_to_sumH),
                                    .parallelOut(sumH_to_cond2),
                                    .clk(clk),
                                    .rst_n(rst_n),
                                    .clear(1'b0),
                                    .sample_en(sumH_en));
  //cond2 block
  mux2to1 #(parallelism+1) cond2 (  .inA(sumH_to_cond2),
                                    .inB({sumH_to_cond2[parallelism-1:0],sumL_to_rev[parallelism]}),
                                    .out(condSum_to_rev),
                                    .sel(rev_en));
  //rev block for sum H part
  revertingBlock #(parallelism+1) sumHoutRev (  .signalIn(condSum_to_rev),
                                              .signalOut(revSum_to_remCorrection),
                                              .rev_en(rev_en));
  //save_reminder correction (I'm dividing by 2)
  assign remCorrectionH_to_csa = (save_reminder) ? {revSum_to_remCorrection[parallelism],revSum_to_remCorrection[parallelism:1]} : revSum_to_remCorrection;
  //kernel logic
  kernelLogic #(.parallelism(parallelism)) KL ( .data(ad_to_kernelLogic),
                                                .notData(notAd_to_kernelLogic),
                                                .saveReminder(save_reminder),
                                                .opCode(opCode),
                                                .sumMSBs(sumH_to_cond2[parallelism:parallelism-4]), //4 in this case
                                                .carryMSBs(carryH_to_remCorrection[parallelism:parallelism-4]),
                                                .SignSel(SignSel),
                                                .Non0(Non0),
                                                .outData(kl_to_csa),
                                                .z_MSB(mzReg_to_comparator[parallelism-1]),
                                                .d_MSB(adReg_to_comparator[parallelism-1]));
  //sumL register
  register #(parallelism+1) sumL (  .parallelIn(sumlMux_to_sumL),
                                    .parallelOut(sumL_to_rev),
                                    .clk(clk),
                                    .rst_n(rst_n),
                                    .clear(regn_clr),
                                    .sample_en(sumL_en));
  //q_p next bit logic
  assign q_p = Non0 & ~SignSel;
  //q_n next bit logic
  assign q_n = Non0 & SignSel;
  //mux4to1 at sumL input
  mux4to1 #(parallelism+1) inSumL_mux ( .inA(rxAdd_to_outReg),
                                        .inB(sumRev_to_sumlMux),
                                        .inC({sumL_to_rev[parallelism-1:0],q_p}),
                                        .inD({parallelism+1{1'b0}}),
                                        .sel(sumL_sel),
                                        .out(sumlMux_to_sumL));
  //rev block for input sum of partial products
  revertingBlock #(parallelism+1) sumInRev (  .signalIn(csaSum),
                                            .signalOut(sumRev_to_sumlMux),
                                            .rev_en(rev_en));
  //conditioning of sumL in order to extend the sign correctly even if data is
  //    reverted
  assign sumlRevOutput_in = (rev_en) ? {sumL_to_rev[parallelism-1:0],sumL_to_rev[0]} : {sumL_to_rev[parallelism-1],sumL_to_rev[parallelism-1:0]};

  //rev block for output sum of partial products
  revertingBlock #(parallelism+1) sumOutRev ( .signalIn(sumlRevOutput_in),
                                              .signalOut(sumlRev_to_csa),
                                              .rev_en(rev_en));
  //mux operand 2 of csa
  mux2to1 #(parallelism+1) csaOp2Mux (  .inA(remCorrectionH_to_csa),
                                        .inB(sumlRev_to_csa),
                                        .out(op2Mux_to_csa),
                                        .sel(carrySave_sel));
  //register fo carry H and L
  register #(parallelism+1) carryH (  .parallelIn(carryhMux_to_carryH),
                                      .parallelOut(carryH_to_remCorrection),
                                      .clk(clk),
                                      .rst_n(rst_n),
                                      .clear(regn_clr),
                                      .sample_en(carryH_en));
  register #(parallelism) carryL (  .parallelIn(carrylMux_to_carryL),
                                    .parallelOut(carryL_to_rev),
                                    .clk(clk),
                                    .rst_n(rst_n),
                                    .clear(regn_clr),
                                    .sample_en(carryL_en));
  //save_reminder correction (I'm dividing by 2)
  assign remCorrectionL_to_csa = (save_reminder) ? {carryH_to_remCorrection[parallelism],carryH_to_remCorrection[parallelism:1]} : carryH_to_remCorrection;
  //rev carryH
  revertingBlock #(parallelism+1) carryHoutRev (  .signalIn(remCorrectionL_to_csa),
                                                  .signalOut(carryHRev_to_csa),
                                                  .rev_en(rev_en));
  //conditioning of sumL in order to extend the sign correctly even if data is
  //    reverted
  assign carrylRevOutput_in = (rev_en) ? {carryL_to_rev[parallelism-1:0],carryL_to_rev[0]} : {carryL_to_rev[parallelism-1],carryL_to_rev[parallelism-1:0]};
  //rev carryL
  revertingBlock #(parallelism+1) carryLoutRev (  .signalIn(carrylRevOutput_in),
                                                  .signalOut(carrylRev_to_csa),
                                                  .rev_en(rev_en));
  //mux operand 3 of csa
  mux2to1 #(parallelism+1) csaOp3Mux (  .inA(carryHRev_to_csa),
                                        .inB(carrylRev_to_csa),
                                        .out(op3Mux_to_csa),
                                        .sel(carrySave_sel));
  //mux input carry H
  mux2to1 #(parallelism+1) inCarryH_mux ( .inA({csaCarry[parallelism-2:0],1'b0,1'b0}),
                                          .inB({remCorrectionL_to_csa[parallelism-1:0],rev_to_carryL[parallelism]}),
                                          .out(carryhMux_to_carryH),
                                          .sel(carryH_sel));
  //rev carryL
  revertingBlock #(parallelism+1) carryLinRev (  .signalIn(csaCarry[parallelism-1:0],1'b0),
                                                  .signalOut(rev_to_carryL),
                                                  .rev_en(rev_en));
  //mux input carry L
  mux2to1 #(parallelism) inCarryL_mux ( .inA({carrylRev_to_csa[parallelism-2:0],q_n}),
                                        .inB(rev_to_carryL[parallelism-1:0]),
                                        .out(carrylMux_to_carryL),
                                        .sel(carryL_sel));
  //carrysave adder
  carrySaveAdder #(parallelism) csa ( .addendA(kl_to_csa),
                                      .addendB(op2Mux_to_csa),
                                      .addendC(op3Mux_to_csa),
                                      .sum(csaSum),
                                      .carry(csaCarry));
  //input operands of adders
  mux2to1 #(parallelism+1) op1_lxAdder_mux (  .inA(csaSum),
                                              .inB(~ad_to_kernelLogic),
                                              .out(lxOp1Mux_to_lxOp1Adder),
                                              .sel(op_lxAdd_sel));
  mux2to1 #(parallelism+1) op0_lxAdder_mux (  .inA(csaCarry[parallelism-1],1'b0),
                                              .inB({{parallelism{1'b0}},1'b1}), //constant 1
                                              .out(lxOp0Mux_to_lxOp0Adder),
                                              .sel(op_lxAdd_sel));
  mux2to1 #(parallelism+1) op1_rxAdder_mux (  .inA(sumlRev_to_csa),
                                              .inB(~sumlRev_to_csa),
                                              .out(rxOp1Mux_to_rxOp1Adder),
                                              .sel(lxOp_rxAdd_sel));
  mux4to1 #(parallelism+1) op0_rxAdder_mux (  .inA(~carrylRev_to_csa),
                                              .inB(carrylRev_to_csa),
                                              .inC(corrMux_to_rxOp0Adder),
                                              .inD({parallelism+1{1'b0}}),
                                              .sel(rxOp_rxAdd_sel),
                                              .out(rxOp0Mux_to_rxOp0Adder));
  //correction mux
  mux4to1 #(parallelism+1) correctMux ( .inA({{parallelism{1'b0}},1'b1}),
                                        .inB(~{{parallelism{1'b0}},1'b1}),
                                        .inC({parallelism+1{1'b0}}),
                                        .inD({parallelism+1{1'b0}}),
                                        .sel(correction_sel),
                                        .out(corrMux_to_rxOp0Adder));
  //adders

endmodule //MultDivUnitDP
