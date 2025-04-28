`default_nettype none

module datacache(
  input Clock,
  input Reset,

  output ReadComplete,
  output WriteComplete,

  input ReadEnable,
  input WriteEnable,

  input[1:0] DataWidth,
  output[31:0] DataToCore,
  input[31:0] DataFromCore,
  input[31:0] DataAddress
);

  logic[18:0] Tag = DataAddress[31:13];
  logic[6:0] Index = DataAddress[12:6];
  logic[5:0] Offset = DataAddress[5:0];

  logic[18:0] Tags1[0:127];
  logic[7:0] Lines1[0:127][0:63];
  logic Valid1[0:127];
  logic LRU1[0:127];
  
  logic[18:0] Tags2[0:127];
  logic[7:0] Lines2[0:127][0:63];
  logic Valid2[0:127];
  logic LRU2[0:127];

  logic State;
  logic[18:0] FetchAddress;

  logic[31:0] _DataToCore;
  logic _ReadComplete;
  logic _WriteComplete;

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
        Valid1[i] <= 0;
        Valid2[i] <= 0;
      end
    end else if(State == 0) begin
      if(Tag == Tags1[Index] && Valid1[Index]) begin
        _DataToCore <= 0;
        if(DataWidth == 0) begin
          _DataToCore[7:0] <= Lines1[Index][Offset];
        end else if(DataWidth == 1) begin
          _DataToCore[7:0] <= Lines1[Index][Offset];
          _DataToCore[15:8] <= Lines1[Index][Offset+1];
        end else if(DataWidth == 2) begin
          _DataToCore[7:0] <= Lines1[Index][Offset];
          _DataToCore[15:8] <= Lines1[Index][Offset+1];
          _DataToCore[23:16] <= Lines1[Index][Offset+2];
          _DataToCore[31:24] <= Lines1[Index][Offset+3];
        end
        _ReadComplete <= 1;
      end else if(Tag == Tags2[Index] && Valid2[Index]) begin
        _DataToCore <= 0;
        if(DataWidth == 0) begin
          _DataToCore[7:0] <= Lines1[Index][Offset];
        end else if(DataWidth == 1) begin
          _DataToCore[7:0] <= Lines1[Index][Offset];
          _DataToCore[15:8] <= Lines1[Index][Offset+1];
        end else if(DataWidth == 2) begin
          _DataToCore[7:0] <= Lines1[Index][Offset];
          _DataToCore[15:8] <= Lines1[Index][Offset+1];
          _DataToCore[23:16] <= Lines1[Index][Offset+2];
          _DataToCore[31:24] <= Lines1[Index][Offset+3];
        end
        _ReadComplete <= 1;
      end else begin
        State <= 1;
        FetchAddress <= Tag;
        _ReadComplete <= 0;
      end
    end else if(State == 1) begin
      // something something fetch routine to get 64 bytes
      State <= 0;
    end
  end

  assign ReadComplete = _ReadComplete;
  assign WriteComplete = _WriteComplete;
  assign DataToCore = _DataToCore;
endmodule