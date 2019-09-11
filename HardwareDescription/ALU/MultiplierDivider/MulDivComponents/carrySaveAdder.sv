`include "/home/sandro/GIT_RISCV/HardwareDescription/ALU/MultiplierDivider/MulDivComponents/fullAdder.sv"

module carrySaveAdder (addendA,addendB,addendC,sum,carry);
  parameter width = 32;
  input [width-1:0] addendA;
  input [width-1:0] addendB;
  input [width-1:0] addendC;
  output [width-1:0] sum;
  output [width-1:0] carry;

  genvar i;
  generate
    for (i=0; i < width; i++) begin
      fullAdder fx(.a(addendA[i]),.b(addendB[i]),.c_in(addendC[i]),.s(sum[i]),.c_out(carry[i]));
    end
  endgenerate

endmodule //carrySaveAdder
