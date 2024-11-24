`default_nettype none

module instructioncache(
  input logic Clock,
  input logic Reset,

  input logic[31:0] InstructionAddress,
  output logic[31:0] Instruction,
  output logic InstructionReady,

  output logic BusCycle,
  output logic BusStrobe,
  output logic BusReadWrite,
  input logic BusAcknowledge,
  input logic BusStall,

  output logic[31:0] MemoryAddress,
  input logic[31:0] MemoryDataIn
);

  logic[18:0] Tag = InstructionAddress[31:13];
  logic[7:0] Index = InstructionAddress[12:5];
  logic[2:0] Offset = InstructionAddress[4:2];

  logic[18:0] Tags1[0:255];
  logic[31:0] Lines1[0:255][0:7];
  logic Valid1[0:255];
  
  logic[18:0] Tags2[0:255];
  logic[31:0] Lines2[0:255][0:7];
  logic Valid2[0:255];

  logic LRU[0:255];
  logic State;

  logic[2:0] FetchCounter;

  initial begin
    State = 0;

    for(int i = 0; i < 255; i++) begin
      Valid1[i] = 0;
      Valid2[i] = 0;
    end
  end

  always_ff@(posedge Clock) begin
    if(Reset) begin
      State <= 0;

      for(int i = 0; i < 255; i++) begin
        Valid1[i] = 0;
        Valid2[i] = 0;
      end
    end else if(State == 0) begin
      BusCycle <= 0;
      BusStrobe <= 0;

      if(Tag == Tags1[Index] && Valid1[Index]) begin
        Instruction <= Lines1[Index][Offset];
        InstructionReady <= 1;
        LRU[Index] <= 1;
      end else if(Tag == Tags2[Index] && Valid2[Index]) begin
        Instruction <= Lines2[Index][Offset];
        InstructionReady <= 1;
        LRU[Index] <= 0;
      end else begin
        State <= 1;
        InstructionReady <= 0;

        BusCycle <= 1;
        BusStrobe <= 1;
        MemoryAddress <= {Tag, Index, 5'b0};
      end
    end else if(State == 1) begin
      // how do i handle busacknowledge without losing a clock
      if(FetchCounter == 7) begin
        State <= 0;
        BusCycle <= 0;
        BusStrobe <= 0;

        if(LRU[Index]) begin
          Valid2[Index] <= 1;
          InstructionReady <= 1;
          Instruction <= Lines2[Index][Offset];
        end else begin
          Valid1[Index] <= 1;
          InstructionReady <= 1;
          Instruction <= Lines1[Index][Offset];
        end
      end

      if(LRU[Index]) begin
        Lines2[Index][FetchCounter] <= MemoryDataIn;
      end else begin
        Lines1[Index][FetchCounter] <= MemoryDataIn;
      end

      FetchCounter <= FetchCounter + 1;
      MemoryAddress <= {Tag, Index, FetchCounter + 3'b001, 2'b0};
    end
  end

  assign BusReadWrite = 0;
endmodule