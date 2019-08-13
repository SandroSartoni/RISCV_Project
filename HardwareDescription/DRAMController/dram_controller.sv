`include "../Constants/constants.sv"
import constants::*;

module dram_controller
(
	input logic clk,				// Clock signal
	input logic nrst,				// Reset active on negedge
	input logic[8:0] dmem_addr,			// DRAM Address from RISCV Core
	input logic[`data_size-1:0] dmem_data,		// DRAM Data to be written from RISCV Core
	input logic dmem_re,				// DRAM Read Enable
	input logic dmem_we,				// DRAM Write Enable
	input load_conf load_type, 			// Load Type (lb, lh, lw, lbu, lhu)
	input store_conf store_type,			// Store Type (sb, sh, sw)
	input logic[`data_size-1:0] dmem_word, 		// DRAM word from Data RAM
	output logic[`data_size-1:0] dmem_out,		// DRAM Output Data to the RISCV Core
	output logic dram_re,				// DRAM Read Enable CTRL_IN
	output logic dram_we,				// DRAM Write Enable CTRL_IN
	output logic[`data_size-1:0] dram_datain,	// DRAM Input Word
	output logic[8:0] dram_address			// DRAM Address for the DRAM
);


// Address Field of the DRAM
assign dram_address = dmem_addr;


// Control bits for the DRAM
assign dram_re = dmem_re;
assign dram_we = dmem_we;


// Data to be written to DRAM depending on the store configuration
always_comb begin : dram_datain_assignment
	case(store_type)
		sb_conf : dram_datain = `data_size'(dmem_data[7:0]);
		sh_conf : dram_datain = `data_size'(dmem_data[15:0]);
		sw_conf : dram_datain = dmem_data;
	endcase
end : dram_datain_assignment

// Data retrieved from the DRAM and assembled depending on the load configuration
always_comb begin : dmem_out_assignment
	case(load_type)
		lb_conf : dmem_out = `data_size'(signed'(dmem_word[7:0]));
		lh_conf : dmem_out = `data_size'(signed'(dmem_word[15:0]));
		lw_conf : dmem_out = dmem_word;
		lbu_conf : dmem_out = `data_size'(dmem_word[7:0]);
		lhu_conf : dmem_out = `data_size'(dmem_word[15:0]);
	endcase
end : dmem_out_assignment


endmodule
