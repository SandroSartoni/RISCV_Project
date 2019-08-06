`include "../Constants/constants.sv"

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
  
  #5
  nrst = 1;
  #4       //       rs2   rs1                  rd 
  instr_in = {7'd0, 5'd2, 5'd3, `addsub_func , 5'd4, `ldtype_op};
  #2
  instr_in = {7'd0, 5'd5, 5'd4, `addsub_func , 5'd7, `rtype_op};
  #2    // hazard begin
<<<<<<< HEAD:HardwareDescription/Testbench/tb_cu.sv
  instr_in = {7'd0, 5'd1, 5'd0, `addsub_func , 5'd8, `rtype_op}; // 1
=======
  instr_in = {7'd0, 5'd2, 5'd3, `addsub_func , 5'd4, `ldtype_op}; // 1
>>>>>>> 625389ffd5024bd898b4bac93024088cef61355c:HardwareDescription/ControlUnit/tb_cu.sv
  #2
  /*instr_in = {7'd0, 5'd2, 5'd4, `addsub_func , 5'd5, `btype_op};  // 2
  #2    // end
  instr_in = {7'd0, 5'd2, 5'd3, `addsub_func , 5'd4, `btype_op};*/
	$stop;
end

endmodule
