module ALU_tester;

int A;
int B;
logic [3:0] Control;
int Out;
logic ovfl;
logic [3:0] counter;
logic clk;

string op_type[16] = {"LUI","LW","ADD","XOR","OR","AND","SLL","SRL","SRA","SUB","SLT","SLTU","nop","nop","nop","nop"};

always #5 clk=~clk;
   

alu dut(.*);
 

// Stimuli
initial #0 begin //1

	clk=0;
        counter=0; 
	assign Control = counter;
	counter = 0;
	A = 32'hF00000A2;
	B = 32'h00000002;
	@(posedge clk);
	for(counter=1; counter>0; counter = counter+1) begin
		@(posedge clk);
	end
	$stop;
end

// Monitoring section
initial #0 begin
	$display("#########\tBeginning of Simulation\t##########");
	$monitor("Control: %s\tA: %h\tB: %h\tOut: %h\tovfl: %b",op_type[Control],A,B,Out,ovfl);
end

endmodule
