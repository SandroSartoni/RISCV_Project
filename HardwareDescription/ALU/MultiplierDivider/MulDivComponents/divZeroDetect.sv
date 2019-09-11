module divZeroDetect (divisor,divByZero);
  parameter width=32;
  input divisor;
  output divByZero;
  assign divByZero = (divisor==0) ? 1'b1 : 1'b0;
endmodule //divZeroDetect
