module ALU_tester;

int A;
int B;
logic [3:0] Control;
int Out;
logic ovfl;
logic [3:0] counter;
logic clk;

always #5 clk=~clk;
   

ALU DUT(.*);
 

// Stimuli
initial #0 begin //1
	clk=0;
        counter=0;
	Control = 4'b0000; 
	A = 32'hF00000A2;
	B = 32'h00000002;
 	@(posedge clk);
	assign Control = counter;
	for(counter=0;counter<15; counter = counter+1) begin
	@(posedge clk);

end
	
end

// Monitoring section
initial #0 begin
	$display("#########\tBeginning of Simulation\t##########");
	$monitor("Control: %b\t A: %h\t B: %h\t Out: %b\t cont: %b\t ovfl: %b",Control,A,B,Out,counter,ovfl);
	end

endmodule
