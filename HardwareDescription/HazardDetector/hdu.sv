`include "constants.sv"
`define table_size 512
`define table_logsize 9

module hdu
(
  input logic clk,
  input logic nrst,
  input logic[`data_size-1:0] instruction_in,
  output logic[1:0] num_nop,
  output logic pc_disable_hazard
);
