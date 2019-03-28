
module ALU
(
	input logic [31:0] A,
	input logic [31:0] B,
	input logic [3:0] Control,
	output logic [31:0] Out,
	output logic ovfl
);

logic [19:0] luipart;
logic [11:0] notluipart;
logic compare_u_result;
logic compare_s_result;

parameter S0 = 4'b0000; //LUI
parameter S1 = 4'b0001; // LB LH LW LBU LHU SB SH SW
parameter S2 = 4'b0010; //ADDI ADD
parameter S3 = 4'b0011; //XORI XOR
parameter S4 = 4'b0100; //ORI OR
parameter S5 = 4'b0101; //ANDI AND
parameter S6 = 4'b0110; //SLLI SLL
parameter S7 = 4'b0111; //SRLI SRL
parameter S8 = 4'b1000; //SRAI SRA
parameter S9 = 4'b1001; //SUB
parameter S10 = 4'b1010; //SLT SLTI
parameter S11 = 4'b1011; //SLTU SLTIU
assign { >>{ notluipart,luipart}} = B;

always_comb
Compare_s:begin
	if (A<B) 
		compare_s_result = 1'b1;
	else  
		compare_s_result = 1'b0;
end

always_comb
Compare_u:begin
	if (unsigned'(A)<unsigned'(B)) 
		compare_u_result = 1'b1;
	else  
		compare_u_result = 1'b0;
end

always_comb
 MUX : begin
 case (Control) 
	S0: Out = {luipart,12'h0};
	S1: Out = A + B;//  in realtà sarà il kogge stone
	S2: Out = A + B;// in realtà sarà il kogge stone
	S3: Out = A ^ B;
	S4: Out = A | B;
	S5: Out = A & B;
	S6: Out = A << B;
	S7: Out = A >> B;
	S8: Out = A >>> B;
	S9: Out = A - B;
	S10: Out = compare_s_result;
	S11: Out = compare_u_result;
endcase 
end 
assign ovfl= 1'b1;
endmodule
