module mux4to1 (inA,inB,inC,inD,sel,out);
  parameter width = 32;
  input [width-1:0] inA;
  input [width-1:0] inB;
  input [width-1:0] inC;
  input [width-1:0] inD;
  input [1:0] sel;
  output [width-1:0] out;

  logic [width-1:0] temp;
  assign out = (temp);

  always_comb begin
    if (sel==2'b00) begin
      temp=inA;
    end else if (sel==2'b01) begin
      temp=inB;
    end else if (sel==2'b10) begin
      temp=inC;
    end else begin
      temp=inD;
    end
  end
endmodule //mux4to1
