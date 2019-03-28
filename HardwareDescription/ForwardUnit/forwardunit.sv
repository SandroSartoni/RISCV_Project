
`define bit_for_reg 5

module forw_unit
(
	input logic RegWrs_1d,
	input logic RegWrs_2d,
	input logic [`bit_for_reg-1:0] RegR1,
	input logic [`bit_for_reg-1:0] RegR2,
	input logic [`bit_for_reg-1:0] RegW_1d,
	input logic [`bit_for_reg-1:0] RegW_2d,
	output logic [1:0] sel_mux1,
	output logic [1:0] sel_mux2
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
