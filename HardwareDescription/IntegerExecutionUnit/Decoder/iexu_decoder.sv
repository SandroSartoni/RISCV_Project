`include "constants.sv"
import constants::*;

module iexu_decoder
(
	input iexu_conf conf,
	output logic add_ctrl,
	output logic[3:0] logic_ctrl,
	output logic[1:0] shifter_ctrl,
	output logic[1:0] outmux_ctrl
);

	always_comb begin : ctrl_assignment

		case(conf)
			add_conf : begin
				add_ctrl = 1'b0;
				logic_ctrl = 4'hx;
				shifter_ctrl = 2'bxx;
				outmux_ctrl = 2'b00;
			end

			sub_conf : begin
				add_ctrl = 1'b1;
				logic_ctrl = 4'hx;
				shifter_ctrl = 2'bxx;
				outmux_ctrl = 2'b00;
			end

			and_conf : begin
				add_ctrl = 1'bx;
				logic_ctrl = 4'h8;
				shifter_ctrl = 2'bxx;
				outmux_ctrl = 2'b01;
			end

			or_conf : begin
				add_ctrl = 1'bx;
				logic_ctrl = 4'hE;
				shifter_ctrl = 2'bxx;
				outmux_ctrl = 2'b01;
			end

			xor_conf : begin
				add_ctrl = 1'bx;
				logic_ctrl = 4'h6;
				shifter_ctrl = 2'bxx;
				outmux_ctrl = 2'b01;
			end

			sll_conf : begin
				add_ctrl = 1'bx;
				logic_ctrl = 4'hx;
				shifter_ctrl = 2'b00;
				outmux_ctrl = 2'b10;
			end

			srl_conf : begin
				add_ctrl = 1'bx;
				logic_ctrl = 4'hx;
				shifter_ctrl = 2'b01;
				outmux_ctrl = 2'b10;
			end

			sra_conf : begin
				add_ctrl = 1'bx;
				logic_ctrl = 4'hx;
				shifter_ctrl = 2'b10;
				outmux_ctrl = 2'b10;
			end
		endcase

	end : ctrl_assignment


endmodule
