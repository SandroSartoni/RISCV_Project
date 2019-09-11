//register that sincronously shifts left and right
//NOT TESTED ALONE
module shiftRegister (parallelIn,parallelOut,clk,rst_n,clear,sample_en,shiftLeft,shiftRight,newBit);
  parameter width = 32;
  input [width-1:0] parallelIn;     //input Sample, as for regular register
  output [width-1:0] parallelOut;   //output Sample, as for regular register
  input clk;
  input rst_n;                      //async. reset
  input clear;                      //sync. reset
  input sample_en;                  //enable the sampling of input to output
  input shiftLeft;                  //enable the shift left operation (synchronous)
  input shiftRight;                 //enable the shift right operation (synchronous)
  input newBit;                     //when shifting, take place of the new LSB or MSB depending on the operation

  logic [width-1:0] temp;
  assign parallelOut = temp;

  always_ff @ (posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      temp={width{1'b0}};
    end else begin
      if (clear) begin
        temp={width{1'b0}};
      end else begin
        if      (sample_en) begin
          temp=parallelIn;
        end else if (shiftLeft) begin
          temp={temp[width-2:0],newBit};
        end else if (shiftRight) begin
          temp={newBit,temp[width-1:1]};
        end else begin
          temp=temp;
        end
      end
    end
  end
endmodule // shiftRegister
