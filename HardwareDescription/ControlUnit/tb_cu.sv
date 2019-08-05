`include "constants.sv"

module tb_CU;


  bit clk, nrst, stall, chng2nop;
  logic[`instr_size -1 :0] instr_in;
  logic[`cw_length -1 :0] datapath_out;

  cu CU(
    .instr_in(instr_in),
    .cw_out(datapath_out),
    .clk(clk),
    .nrst(nrst),
    .stall(stall),
    .chng2nop(chng2nop)
  );

always #1 clk = ~clk;

initial begin
  nrst = 0;
  stall = 0;
  chng2nop = 0;
  
  instr_in = 'b0;
  
  #5 nrst = 1;
  instr_in = {7'd0, 5'd2, 5'd3, `addsub_func , 5'd4, `rtype_op};
  
  
  
end

endmodule
