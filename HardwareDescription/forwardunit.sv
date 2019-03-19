'include "constants.sv"
'define bit_for_reg 5

module forw_unit
(
	input logic RegWrs_1d,
	input logic RegWrs_2d,
	input logic [bit_for_reg-1:0] RegR1,
	input logic [bit_for_reg-1:0] RegR2,
	input logic [bit_for_reg-1:0] RegW_1d,
	input logic [bit_for_reg-1:0] RegW_2d,
	output logic [1:0] sel_mux1,
	output logic [1:0] sel_mux2
);

always_comb
begin
	if (RegR1 == '00000') begin
		sel_mux1 = '00';
	end else if ((RegR1 == RegW_1d)and(RegWrs_1d=1)) begin
		sel_mux1 = '10';
	end else if ((RegR1 == RegW_2d)and(RegWrs_2d=1)) begin
		sel_mux1 = '01';
	end else begin
		sel_mux1='00';
	end
end

always_comb 
begin
	if (RegR2 == '00000') begin
		sel_mux2 = '00';
	end else if ((RegR2 == RegW_1d)and(RegWrs_1d=1)) begin
		sel_mux2 = '10';
	end else if ((RegR2 == RegW_2d)and(RegWrs_2d=1)) begin
		sel_mux2 = '01';
	end else begin
		sel_mux2 ='00';
	end
end

end module
	