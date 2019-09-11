`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MultDivUnitDP.sv"

module MultDivUnit (clk,rst_n,opCode,lOp,rOp,result,done,valid,divByZero,divOverflow);
  parameter parallelism=32;
  input clk;
  input rst_n;
  input [2:0] opCode;
  input valid;
  input [parallelism-1:0] lOp;//must be rs2
  input [parallelism-1:0] rOp;//must be rs1
  output [parallelism-1:0] result;
  output done;
  output divByZero;
  output divOverflow;

  logic res_ready;
  logic div_by_zero;
  logic div_overflow;
  logic lOp_en;
  logic divisor_lShift;
  logic notLOp_en;
  logic saveReminder;
  logic [1:0] sumMux_sel;
  logic carryMux_sel;
  logic sum_en;
  logic carry_en;
  logic [1:0] leftAddMux_sel;
  logic [1:0] rightAddMux_sel;
  logic QCorrectBitMux_sel;
  logic rightAddMode;
  logic lRes_en;
  logic rRes_en;
  logic reminder_rShift;
  logic counterMux_sel;
  logic thrMux_sel;
  logic count_upDown;
  logic count_load;
  logic count_en;
  logic counterReg_en;
  logic prevReg_en;
  logic csa_clear;
  logic d_o_n_e;//to be conncected to done
  logic d_i_v_B_y_Z_e_r_o;//to be connected to divByZero
  logic d_i_v_O_v_e_r_f_l_o_w;//to be connected to divOverflow
  logic tc;
  logic signS;
  logic [1:0] magnitudeD;
  logic signD;
  logic signZ;
  logic divisorReady;
  logic load1;

  enum bit [4:0]{   idle            =5'b00000,
                    divByZeroState  =5'b00001,
                    divOverflowState=5'b00010,
                    loadData        =5'b00011,
                    divisorLShift   =5'b00100,
                    saveIterLoop    =5'b00101,
                    divKernelStep   =5'b00110,
                    computeQ        =5'b00111,
                    waitSignals     =5'b01000,
                    correctDown     =5'b01001,
                    correctUp       =5'b01010,
                    qInv            =5'b01011,
                    remCorrection   =5'b01100,
                    save_muliplicand=5'b01101,
                    save_mulitplier =5'b01110,
                    multKernelStep  =5'b01111,
                    save_product    =5'b10000,
                    opDone          =5'b10001} present_state, next_state;

  assign done=d_o_n_e;
  assign divByZero=d_i_v_B_y_Z_e_r_o;
  assign divOverflow=d_i_v_O_v_e_r_f_l_o_w;

  //instantiating the dp
  MultDivUnitDP #(parallelism) DP (.*);

  //assigning signs
  always_comb begin
    if (opCode[0]) begin
      signZ=1'b0;
      signD=1'b0;
    end else begin
      signZ=rOp[parallelism-1];
      signD=lOp[parallelism-1];
    end
  end

  //divisor magnitude for lShift
  always_comb begin
    if (lOp[parallelism-1] & opCode[0]) begin
      load1=1'b1;
    end else begin
      load1=1'b0;
    end
  end

  //divisor magnitude for loadCnt1
  always_comb begin
    if (magnitudeD[0] ^ magnitudeD[1]) begin
      divisorReady=1'b1;
    end else begin
      divisorReady=1'b0;
    end
  end

  //state transition
  always_ff @ (posedge clk) begin
    if (~rst_n)
      present_state<=idle;//reset synchronous
    else
      present_state<=next_state;
  end

  always_comb begin
    case (present_state)
      idle: if (valid) begin
              if (res_ready) begin
                next_state=opDone;
              end else if (div_by_zero) begin
                next_state=divByZeroState;
              end else if (div_overflow) begin
                next_state=divOverflowState;
              end else if (opCode[2]==1'b0) begin
                next_state=save_muliplicand;
              end else begin
                next_state=loadData;
              end
            end else begin
              next_state=idle;
            end
      divByZeroState: next_state=idle;
      divOverflowState: next_state=idle;
      loadData: if (load1) begin
                  next_state=saveIterLoop;
                end else begin
                  next_state=divisorLShift;
                end
      divisorLShift:  if (divisorReady) begin
                        next_state=saveIterLoop;
                      end else begin
                        next_state=divisorLShift;
                      end
      saveIterLoop: next_state=divKernelStep;
      divKernelStep:  if (tc) begin
                        next_state=computeQ;
                      end else begin
                        next_state=divKernelStep;
                      end
      computeQ: if (signD) begin
                  next_state=qInv;
                end else begin
                  next_state=waitSignals;
                end
      waitSignals:  if (signS ^ signZ) begin
                      if (signS ^ signD) begin
                        next_state=correctDown;
                      end else begin
                        next_state=correctUp;
                      end
                    end else begin
                      next_state=remCorrection;
                    end
      qInv: if (signS ^ signZ) begin
              if (signS ^ signD) begin
                next_state=correctDown;
              end else begin
                next_state=correctUp;
              end
            end else begin
              next_state=remCorrection;
            end
      correctDown: next_state=remCorrection;
      correctUp:  next_state=remCorrection;
      remCorrection: if (tc) begin
                        next_state=opDone;
                      end else begin
                        next_state=remCorrection;
                      end
      save_muliplicand: next_state=save_mulitplier;
      save_mulitplier:  next_state=multKernelStep;
      multKernelStep: if (tc) begin
                        next_state=save_product;
                      end else begin
                        next_state=multKernelStep;
                      end
      save_product: next_state=opDone;
      opDone: next_state=idle;
      default: next_state=idle;
    endcase
  end

  always_comb begin
    case (present_state)
      idle: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b1;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      divByZeroState: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b1;
        d_i_v_B_y_Z_e_r_o=1'b1;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      divOverflowState: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b1;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b1;
      end
      loadData: begin
        lOp_en=1'b1;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b00;
        carryMux_sel=1'b0;
        sum_en=1'b1;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b1;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b1;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      divisorLShift: begin
        lOp_en=1'b0;
        divisor_lShift=1'b1;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b1;
        count_load=1'b0;
        count_en=1'b1;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      saveIterLoop: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b1;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b01;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b1;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      divKernelStep: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b01;
        carryMux_sel=1'b0;
        sum_en=1'b1;
        carry_en=1'b1;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b1;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      computeQ: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b1;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b1;
        lRes_en=1'b1;
        rRes_en=1'b1;
        reminder_rShift=1'b0;
        counterMux_sel=1'b1;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b1;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      waitSignals: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      correctDown: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b10;
        rightAddMux_sel=2'b01;
        QCorrectBitMux_sel=1'b1;
        rightAddMode=1'b0;
        lRes_en=1'b1;
        rRes_en=1'b1;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      correctUp: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b11;
        rightAddMux_sel=2'b01;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b1;
        rRes_en=1'b1;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      qInv: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b10;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b1;
        lRes_en=1'b0;
        rRes_en=1'b1;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      remCorrection: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b1;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b1;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      save_muliplicand: begin
        lOp_en=1'b1;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b1;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b1;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      save_mulitplier: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b1;
        saveReminder=1'b0;
        sumMux_sel=2'b11;
        carryMux_sel=1'b1;
        sum_en=1'b1;
        carry_en=1'b0;
        leftAddMux_sel=2'b01;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      multKernelStep: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b10;
        carryMux_sel=1'b1;
        sum_en=1'b1;
        carry_en=1'b1;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b1;
        count_upDown=1'b1;
        count_load=1'b0;
        count_en=1'b1;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      save_product: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b1;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b11;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b1;
        rRes_en=1'b1;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      opDone: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b1;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
      default: begin
        lOp_en=1'b0;
        divisor_lShift=1'b0;
        notLOp_en=1'b0;
        saveReminder=1'b0;
        sumMux_sel=2'b0;
        carryMux_sel=1'b0;
        sum_en=1'b0;
        carry_en=1'b0;
        leftAddMux_sel=2'b0;
        rightAddMux_sel=2'b0;
        QCorrectBitMux_sel=1'b0;
        rightAddMode=1'b0;
        lRes_en=1'b0;
        rRes_en=1'b0;
        reminder_rShift=1'b0;
        counterMux_sel=1'b0;
        thrMux_sel=1'b0;
        count_upDown=1'b0;
        count_load=1'b0;
        count_en=1'b0;
        counterReg_en=1'b0;
        prevReg_en=1'b0;
        csa_clear=1'b0;
        d_o_n_e=1'b0;
        d_i_v_B_y_Z_e_r_o=1'b0;
        d_i_v_O_v_e_r_f_l_o_w=1'b0;
      end
    endcase
  end
endmodule
