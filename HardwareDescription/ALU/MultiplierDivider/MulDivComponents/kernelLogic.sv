module kernelLogic (data,notData,saveReminder,opCode,sumMSBs,carryMSBs,multDecisionBits,SignSel,Non0,outData,d_MSB);
  parameter parallelism=32;
  parameter csaBits=5;
  input [parallelism:0] data;
  input [parallelism:0] notData;
  input saveReminder;
  input [2:0] opCode;
  input [csaBits-1:0] sumMSBs;
  input [csaBits-1:0] carryMSBs;
  input [1:0] multDecisionBits;
  input d_MSB;
  output SignSel;
  output Non0;
  output [parallelism:0] outData;

  logic [1:0] divisionControl;
  logic signD;

  //divisionControl combinatory logic
  logic unsigned [csaBits-1:0] tempU;
  logic signed [csaBits-1:0] temp;
  always_comb begin
    //I'm doing a sum but actually is implemented as a PLA or LUT;
    tempU=($unsigned(sumMSBs))+($unsigned(carryMSBs));
    temp=($signed(tempU));
    if (temp<-2) begin
      divisionControl=2'b00;
    end else if (temp>=0) begin
      divisionControl=2'b01;
    end else begin
      divisionControl=2'b11;
    end
  end

  //signD combinatory logic
  always_comb begin
    if(opCode[0]) begin                 //unsigned
      signD=0;
    end else begin
      signD=d_MSB;
    end
  end

  logic SS,N0;
  logic signed [parallelism:0] oData;
  assign SignSel=SS;
  assign Non0=N0;
  assign outData=oData;

  //outData driving combinatory logic
  always_comb begin
    if (saveReminder) begin              //case we are in saveReminder STATE
      //assigning by default SignSel and Non0
      SS=1'b0;
      N0=1'b0;
      oData={parallelism{1'b0}};
    end else begin
      if (opCode[2]==1'b1) begin        //case DIVISION
        if (!signD) begin    //case divisor is NEGATIVE
          case (divisionControl)
            2'b00: begin
              oData=data;
              SS=1'b1;
              N0=1'b1;
            end
            2'b01: begin
              oData=notData;
              SS=1'b0;
              N0=1'b1;
            end
            default: begin
              oData={parallelism{1'b0}};
              SS=1'b0;
              N0=1'b0;
            end
          endcase
        end else begin                //case divisor is POSITIVE
          case (divisionControl)
            2'b00: begin
              oData=notData;
              SS=1'b1;
              N0=1'b1;
            end
            2'b01: begin
              oData=data;
              SS=1'b0;
              N0=1'b1;
            end
            default: begin
              oData={parallelism{1'b0}};
              SS=1'b0;
              N0=1'b0;
            end
          endcase
        end
      end else begin                    //case MULTIPLICATION
        //assigning by default SignSel and Non0
        SS=1'b0;
        N0=1'b0;
        case (multDecisionBits)
          2'b10: oData=notData; //should be data
          2'b01: oData=data; // should be notData
          default: oData={parallelism{1'b0}};
        endcase
      end
    end
  end
endmodule //
