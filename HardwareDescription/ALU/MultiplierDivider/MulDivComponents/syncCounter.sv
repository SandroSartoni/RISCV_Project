//synchronous counter
module syncCounter (clk,rst_n,clear,parallelLoad,threashold,upDown_n,load_en,cnt_en,terminalCount,parallelOutput);
  parameter WIDTH=16;
  input clk;                            //synchronization signal
  input rst_n;                          //asynchronous reset signal
  input clear;                          //synchronouus reset signal
  input [WIDTH-1:0] parallelLoad;       //starting number to start counting
  input [WIDTH-1:0] threashold;         //threashold at which tc is rised
  input upDown_n;                       //1 for counting up, 0 for cunting down
  input load_en;                        //enable for loading the parallelLoad input
  input cnt_en;                         //enable for counting according to upDown_n signal
  output terminalCount;                 //rised when threashold is reached
  output [WIDTH-1:0] parallelOutput;    //shows current counting number

  logic unsigned [WIDTH-1:0] counter;
  logic tc;
  assign parallelOutput = counter;
  assign terminalCount  = tc;
  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      counter={WIDTH{1'b0}};
    end else begin
      if (clear) begin
        counter={WIDTH{1'b0}};
      end else begin
        if (load_en) begin
          counter=parallelLoad;
        end else begin
          if (cnt_en) begin
            if (upDown_n) begin
              counter=counter+1;
            end else begin
              counter=counter-1;
            end
          end
        end
      end
    end
  end

  always_comb begin
    if (threashold==counter) begin
      tc<=1'b1;
    end else begin
      tc<=1'b0;
    end
  end
endmodule
