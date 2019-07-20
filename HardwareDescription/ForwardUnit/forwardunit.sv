`include "constants.sv"

module forw_unit
(
	input logic RegWrs_1d,				// Write enable for Reg1
	input logic RegWrs_2d,				// Write enable for Reg2
	input logic [`regfile_logsize-1:0] RegR1,	// Reg1 field
	input logic [`regfile_logsize-1:0] RegR2,	// Reg2 field
	input logic [`regfile_logsize-1:0] RegW_1d,	// Reg1 to be written
	input logic [`regfile_logsize-1:0] RegW_2d,	// Reg2 to be written
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
