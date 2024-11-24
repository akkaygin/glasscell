`default_nettype none

module memoryemulator(
  input logic Clock,
  
  input logic[1:0] Width,
  input logic[31:0] Address,
  input logic[31:0] DataIn,
  output logic[31:0] DataOut,

  input logic Cycle,
  input logic Strobe,
  input logic ReadWrite,

  output logic Acknowledge,
  output logic Stall
);

  localparam CAPACITY = 4096;

  logic[7:0] Memory[0:CAPACITY-1];

  initial begin
    for(int i = 0; i < CAPACITY; i++) begin
      Memory[i] = 0;
    end
  end

  always_ff@(posedge Clock) begin
    if(Cycle && Strobe && !ReadWrite) begin
      DataOut <= 0;
      if(Width == 0) begin
        DataOut[7:0] <= Memory[Address];
      end else if(Width == 1) begin
        DataOut[15:8] <= Memory[Address];
        DataOut[7:0] <= Memory[Address+1];
      end else if(Width == 2) begin
        DataOut[31:24] <= Memory[Address];
        DataOut[23:16] <= Memory[Address+1];
        DataOut[15:8] <= Memory[Address+2];
        DataOut[7:0] <= Memory[Address+3];
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
    end else begin
      DataOut <= 0;
    end
  end

  always_ff@(posedge Clock) begin
    Acknowledge <= Strobe;
  end

  assign Stall = 0;
endmodule