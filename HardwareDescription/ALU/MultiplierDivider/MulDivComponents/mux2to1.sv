module mux2to1 (inA,inB,sel,out);
  parameter width = 32;
  input [width-1:0] inA;
  input [width-1:0] inB;
  input sel;
  output [width-1:0] out;

  logic [width-1:0] temp;
  assign out = (temp);

  always_comb begin
    if (sel) begin
      temp=inB;
    end else begin
      temp=inA;
    end
  end
endmodule //mux2to1
