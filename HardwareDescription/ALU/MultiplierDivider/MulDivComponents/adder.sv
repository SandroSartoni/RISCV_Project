//doesn't handle overflow case!!!
module adder (add1,add0,carry_in,sum);
 parameter parallelism=32;
 input unsigned [parallelism-1:0] add1;
 input unsigned [parallelism-1:0] add0;
 input carry_in;
 output unsigned [parallelism-1:0] sum;

 logic unsigned [parallelism-1:0] temp_sum;
 assign sum = temp_sum;

 always_comb begin
   if (carry_in) begin
     temp_sum=add1+add0+1;
   end else begin
     temp_sum=add1+add0;
   end
 end
endmodule //adder
