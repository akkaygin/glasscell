`default_nettype none

module instructioncache(
  input Clock,
  input Reset,

  input [31:0] InstructionAddress,
  output[31:0] Instruction,
  output InstructionReady,

  output BusCycle,
  output BusStrobe,
  output BusReadWrite,
  input BusAcknowledge,
  input BusStall,

  output[31:0] MemoryAddress,
  input[31:0] MemoryDataIn,
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

  logic[26:0] BaseFetchAddress;
  logic[2:0] FetchCounter;

  logic[31:0] _Instruction;
  logic _InstructionReady;

  logic _BusCycle;
  logic _BusStrobe;
  logic[31:0] _MemoryAddress;

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
        _Instruction <= Lines1[Index][Offset];
        _InstructionReady <= 1;
        LRU[Index] <= 1;
      end else if(Tag == Tags2[Index] && Valid2[Index]) begin
        _Instruction <= Lines2[Index][Offset];
        _InstructionReady <= 1;
        LRU[Index] <= 0;
      end else begin
        State <= 1;
        BaseFetchAddress <= {Tag, Index};
        _InstructionReady <= 0;

        BusCycle <= 1;
        BusStrobe <= 1;
        MemoryAddress <= {Tag, Index};

        // sets the valid bit before actually fetching
        if(LRU[FetchAddress[7:0]]) begin
          Valid2[Index] <= 1;
        end else begin
          Valid1[Index] <= 1;
        end
      end
    end else if(State == 1) begin
      BusCycle <= 1;
      BusStrobe <= 1;
      MemoryAddress <= BaseFetchAddress + FetchCounter;

      if(FetchCounter == 7) begin
        State <= 0;
      end

      if(LRU[BaseFetchAddress[7:0]]) begin
        Lines2[BaseFetchAddress[7:0]][FetchCounter] <= MemoryDataIn;
      end else begin
        Lines1[BaseFetchAddress[7:0]][FetchCounter] <= MemoryDataIn;
      end

      FetchCounter <= FetchCounter + 1;
    end
  end

  assign Instruction = _Instruction;
  assign InstructionReady = _InstructionReady;

  assign BusCycle = _BusCycle;
  assign BusStrobe = _BusStrobe;
  assign MemoryAddress = _MemoryAddress;

  assign BusReadWrite = 0;
endmodule