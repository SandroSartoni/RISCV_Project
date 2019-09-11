module divOvfDetectBlock (divisor,dividend,overflow);
  parameter width = 32;
  input signed [width-1:0] divisor;
  input signed [width-1:0] dividend;
  output overflow;

  logic eqDivisor,eqDividend;

  always_comb begin //divisor check if =-1
    if (divisor==-1) begin
      eqDivisor<=1'b1;
    end else begin
      eqDivisor<=1'b0;
    end
  end

  always_comb begin //dividend check if =-2**(width-1)
  if (dividend==-2**(width-1)) begin
      eqDividend<=1'b1;
    end else begin
      eqDividend<=1'b0;
    end
  end
  assign overflow= eqDivisor & eqDividend;
endmodule //mux2to1
