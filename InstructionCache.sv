`default_nettype none

module instructioncache(
  input Clock,
  input Reset,

  input [31:0] InstructionAddress,
  output[31:0] Instruction,
  output InstructionReady
);

  logic[18:0] Tag = InstructionAddress[31:13];
  logic[6:0] Index = InstructionAddress[12:6];
  logic[3:0] Offset = InstructionAddress[5:2];

  logic[18:0] Tags1[0:127];
  logic[31:0] Lines1[0:127][0:15];
  logic Valid1[0:127];
  logic LRU1[0:127];
  
  logic[18:0] Tags2[0:127];
  logic[31:0] Lines2[0:127][0:15];
  logic Valid2[0:127];
  logic LRU2[0:127];

  logic State;
  logic[18:0] FetchAddress;

  logic[31:0] _Instruction;
  logic _InstructionReady;

  initial begin
    State = 0;

    for(int i = 0; i < 64; i++) begin
      Valid1[i] = 0;
      Valid2[i] = 0;
    end
  end

  always_ff@(posedge Clock) begin
    if(Reset) begin
      State <= 0;

      for(int i = 0; i < 64; i++) begin
        Valid1[i] = 0;
        Valid2[i] = 0;
      end
    end else if(State == 0) begin
      if(Tag == Tags1[Index] && Valid1[Index]) begin
        _Instruction <= Lines1[Index][Offset];
        _InstructionReady <= 1;
      end else if(Tag == Tags2[Index] && Valid2[Index]) begin
        _Instruction <= Lines2[Index][Offset];
        _InstructionReady <= 1;
      end else begin
        State <= 1;
        FetchAddress <= Tag;
        _InstructionReady <= 0;
      end
    end else if(State == 1) begin
      // something something fetch routine to get 64 bytes
      State <= 0;
    end
  end

  assign Instruction = _Instruction;
  assign InstructionReady = _InstructionReady;
endmodule