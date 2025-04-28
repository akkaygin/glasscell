`default_nettype none

module memoryemulator(
  input Clock,
  
  input[1:0] Width,
  input[31:0] Address,
  input[31:0] DataIn,
  output[31:0] DataOut,

  input Cycle,
  input Strobe,
  input ReadWrite,

  output Acknowledge,
  output Stall
);

  localparam CAPACITY = 4096;

  logic[7:0] Memory[0:CAPACITY-1];
  logic State;

  logic[1:0] ReadWidth;
  logic[31:0] ReadAddress;

  initial begin
    State = 0;
    ReadWidth = 0;
    ReadAddress = 0;

    for(int i = 0; i < CAPACITY; i++) begin
      Memory[i] = 0;
    end
  end

  logic[31:0] _DataOut;
  logic _Acknowledge;
  always_ff@(posedge Clock) begin
    if(Cycle && Strobe && !ReadWrite) begin
      _DataOut <= 0;
      if(Width == 0) begin
        _DataOut[7:0] <= Memory[Address];
      end else if(Width == 1) begin
        _DataOut[15:8] <= Memory[Address];
        _DataOut[7:0] <= Memory[Address+1];
      end else if(Width == 2) begin
        _DataOut[31:24] <= Memory[Address];
        _DataOut[23:16] <= Memory[Address+1];
        _DataOut[15:8] <= Memory[Address+2];
        _DataOut[7:0] <= Memory[Address+3];
      end else begin
        // ignore
      end
      
    end else if(Cycle && Strobe && ReadWrite) begin
      if(Width == 0) begin
        Memory[Address] <= DataIn[7:0];
      end else if(Width == 1) begin
        Memory[Address] <= DataIn[15:8];
        Memory[Address+1] <= DataIn[7:0];
      end else if(Width == 2) begin
        Memory[Address] <= DataIn[31:24];
        Memory[Address+1] <= DataIn[23:16];
        Memory[Address+2] <= DataIn[15:8];
        Memory[Address+3] <= DataIn[7:0];
      end else begin
        // ignore
      end
    end
  end

  always_ff@(posedge Clock) begin
    _Acknowledge <= Strobe;
  end

  assign DataOut = _DataOut;
  assign Acknowledge = _Acknowledge;
  assign Stall = 0;

endmodule