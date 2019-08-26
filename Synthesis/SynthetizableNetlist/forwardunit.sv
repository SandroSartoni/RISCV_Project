`include "constants.sv"
`ifndef forw_unit_sv
`define forw_unit_sv

module forw_unit
(
	input logic RegWrs_1d,				// Write enable for WR after 1 cycle
	input logic RegWrs_2d,				// Write enable for WR after 2 cycles
	input logic [`regfile_logsize-1:0] RegR1,	// Operand_1 field
	input logic [`regfile_logsize-1:0] RegR2,	// Operand_2 field
	input logic [`regfile_logsize-1:0] RegW_1d,	// WR after 1 cycle
	input logic [`regfile_logsize-1:0] RegW_2d,	// WR after 2 cycles 
	output logic [1:0] sel_mux1,			// First mux selector
	output logic [1:0] sel_mux2			// Second mux selector
);


always_comb
begin
	if (RegR1 == 5'b00000) 
		sel_mux1 = 2'b00;
	else if ((RegR1 == RegW_1d)&&(RegWrs_1d==1'b1)) 
		sel_mux1 = 2'b10;
	else if ((RegR1 == RegW_2d)&&(RegWrs_2d==1'b1)) 
		sel_mux1 = 2'b01;
	else 
		sel_mux1=2'b00;

end

always_comb
begin
	if (RegR2 == 5'b00000) 
		sel_mux2 = 2'b00;
	else if ((RegR2 == RegW_1d)&&(RegWrs_1d==1'b1)) 
		sel_mux2 = 2'b10;
	else if ((RegR2 == RegW_2d)&&(RegWrs_2d==1'b1)) 
		sel_mux2 = 2'b01;
	else 
		sel_mux2=2'b00;

end

endmodule

`endif