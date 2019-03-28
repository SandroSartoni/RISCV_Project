
`define bit_for_reg 5

module forw_unit_tester;


//logic clk;				// Clock signal
//logic nrst;				// Synchronous reset signal, active on '0'
logic RegWrs_1d;//logic rd1_en;				// Port 1 read enable signal
logic RegWrs_2d;//logic[`regfile_logsize-1:0] rd1_addr;	// Port 1 read address
logic [`bit_for_reg-1:0] RegR1;//logic rd2_en;				// Port 2 read enable signa
logic [`bit_for_reg-1:0] RegR2;//logic[`regfile_logsize-1:0] rd2_addr;	// Port 2 read address
logic [`bit_for_reg-1:0] RegW_1d;
logic [`bit_for_reg-1:0] RegW_2d;
logic [1:0] sel_mux1;
logic [1:0] sel_mux2; //logic wr_en;			// Write enable signal
//logic[`regfile_logsize-1:0] wr_addr;	// Write address
//logic[`data_size-1:0] wr_data;		// Data to be written
//logic[`data_size-1:0] rd_data1;		// Port 1 output data
//logic[`data_size-1:0] rd_data2;		// Port 2 output data



forw_unit DUT(.*);

// Clk signal
//always #5 clk=~clk;

// Stimuli
initial #0 begin //1
	RegWrs_1d = 1'b0;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00001;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00001;
	RegW_2d = 5'b00011;
	# 5;//2
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00001;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00001;
	RegW_2d = 5'b00011;
	# 5;//3
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b0;
	RegR2 = 5'b00001;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00011;
	RegW_2d = 5'b00001;
	# 5;//4
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00001;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00011;
	RegW_2d = 5'b00001;
	# 5;//5
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00000;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00001;
	RegW_2d = 5'b00000;
	# 5;//6
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00000;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00000;
	RegW_2d = 5'b00001;
	# 5;//7
	RegWrs_1d = 1'b0;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00000;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00000;
	RegW_2d = 5'b00001;
	# 5;//8
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b0;
	RegR2 = 5'b00000;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00000;
	RegW_2d = 5'b00001;
	# 5;//9
	RegWrs_1d = 1'b1;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00001;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00001;
	RegW_2d = 5'b00001;
	# 5;//10
	RegWrs_1d = 1'b0;
	RegWrs_2d = 1'b1;
	RegR2 = 5'b00001;
	RegR1 = 5'b00000;
	RegW_1d = 5'b00001;
	RegW_2d = 5'b00001;
	#5;
	$stop;
end

// Monitoring section
initial #0 begin
	$display("#########\tBeginning of Simulation\t##########");
	$monitor("RegWrs_1d: %b\t RegWrs_2d: %b\t RegR1: %b\t RegR2: %b\t RegW_1d: %b\t RegW_2d: %b\t sel_mux1: %b\t sel_mux2: %b",RegWrs_1d,RegWrs_2d,RegR1,RegR2,RegW_1d,RegW_2d,sel_mux1,sel_mux2);
	//$monitor("clk: %b\tnrst: %b\trd1_en: %b\trd1_addr: %h\trd2_en: %b\trd2_addr: %h\twr_en: %b\twr_addr: %h\twr_data: %h\trd_data1: %h\trd_data2: %h",clk,nrst,rd1_en,rd1_addr,rd2_en,rd2_addr,wr_en,wr_addr,wr_data,rd_data1,rd_data2);
end

endmodule
