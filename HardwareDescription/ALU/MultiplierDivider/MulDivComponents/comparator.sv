module comparator (inA,inB,isEqual);
  parameter width = 32;
  input [width-1:0] inA;
  input [width-1:0] inB;
  output isEqual;

  assign isEqual = (inA==inB) ? 1'b1 : 1'b0;

endmodule //mux2to1
