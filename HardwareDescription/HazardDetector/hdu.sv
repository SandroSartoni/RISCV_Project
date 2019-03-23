// This module detects hazards and produces a vector specifying the number of NOPs to be placed between the
// two colliding instruction in order to resolve the hazard.

`include "constants.sv"

module hdu
(
  input logic clk,
  input logic nrst,
  input logic[`data_size-1:0] instruction_in,
  output logic[1:0] num_nop,
  output logic pc_disable_hazard
);
