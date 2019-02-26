`include "constants.sv"

module reg_file
(
	input logic clk,				// Clock signal
	input logic nrst,				// Synchronous reset signal, active on '0'
	input logic rd1_en,				// Port 1 read enable signal
	input logic[`regfile_logsize-1:0] rd1_addr,	// Port 1 read address
	input logic rd2_en,				// Port 2 read enable signa
	input logic[`regfile_logsize-1:0] rd2_addr,	// Port 2 read address
	input logic wr_en,				// Write enable signal
	input logic[`regfile_logsize-1:0] wr_addr,	// Write address
	input logic[`data_size-1:0] wr_data,		// Data to be written
	output logic[`data_size-1:0] rd_data1,		// Port 1 output data
	output logic[`data_size-1:0] rd_data2		// Port 2 output data
);


logic[`data_size-1:0] registers[0:`regfile_size-1];	// Set of registers (32 regs of 32 bits each)
logic[`data_size-1:0] dataout1;
logic[`data_size-1:0] dataout2;


// If we're synthetizing for an FPGA, use posedge triggered flip flops
`ifdef FPGA_TARGET
	
	always_ff @(posedge clk) begin : ff_regfile

		if(~nrst)
			for(int i=0; i<`regfile_size; i++)
				registers[i] <= 'h0;
		else begin
			// If write is enabled
			if(wr_en) begin
                if(wr_addr != 'h0)
					    registers[wr_addr] <= wr_data;
                else
                        registers[0] <= 'h0;
			end
			
		end
	end : ff_regfile

    // If read @ the first port is enabled
    assign dataout1 = rd1_en ? ((wr_en && (rd1_addr == wr_addr) && (wr_addr != 'h0)) ? wr_data : registers[rd1_addr]) : 'h0;

    // If read @ the second port is enabled
    assign dataout2 = rd2_en ? ((wr_en && (rd2_addr == wr_addr) && (wr_addr != 'h0)) ? wr_data : registers[rd2_addr]) : 'h0;

// If we're synthetizing for an ASIC, use latches
`else

	always_latch begin : latch_regfile

		if(clk) begin
			if(~nrst)
				for(int i=0; i<`regfile_size; i++)
					registers[i] = 'h0;
			else begin
				// If write is enabled
				if(wr_en)
                    if(wr_addr != 'h0)
					    registers[wr_addr] = wr_data;
				// If read @ the first port is enabled
				if(rd1_en)
					dataout1 = registers[rd1_addr];
				else
					dataout1 = 'h0;
				// If read @ the second port is enabled
				if(rd2_en)
					dataout2 = registers[rd2_addr];
				else
					dataout2 = 'h0;
                     
			end
		end

	end : latch_regfile

`endif

assign rd_data1 = dataout1;
assign rd_data2 = dataout2;

endmodule
