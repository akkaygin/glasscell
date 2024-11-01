`default_nettype none

module insturctioncache(
  input Clock,
  input Reset,

  input[31:0] InstructionAddress,
  output[31:0] Instruction,
  output InstructionReady
);

  localparam TAG_WIDTH = 19;
  localparam INDEX_WIDTH = 7;
  localparam OFFSET_WIDTH = 6;
  localparam WAYS = 2;
  localparam SETS = 2**INDEX_WIDTH;
  localparam LINE_SIZE = 2**(3+OFFSET_WIDTH);

  logic[TAG_WIDTH-1:0] Tags[WAYS-1:0][SETS-1:0];
  logic[LINE_SIZE-1:0] Lines[WAYS-1:0][SETS-1:0];
  logic Valid[WAYS-1:0][SETS-1:0];

  logic[TAG_WIDTH-1:0] Tag = InstructionAddress[31:32-TAG_WIDTH];
  logic[INDEX_WIDTH-1:0] Index = InstructionAddress[31-TAG_WIDTH:32-TAG_WIDTH-INDEX_WIDTH];
  logic[OFFSET_WIDTH-1:0] Offset = InstructionAddress[OFFSET_WIDTH-1:0];

  logic[$clog2(WAYS)-1:0] HitWay;
  logic[WAYS-1:0] ValidWay;
  logic[TAG_WIDTH-1:0] TagWay[WAYS-1:0];
  logic[LINE_SIZE-1:0] DataWay[WAYS-1:0];

  logic State;
  logic[TAG_WIDTH-1:0] FetchAddress;

  always_ff@(posedge Clock) begin
    if(Reset) begin
      State <= 0;

      for(int i = 0; i < SETS; i++) begin
        for(int j = 0; j < WAYS; j++) begin
          valid[j][i] <= 0;
        end
      end
    end else if(State == 0) begin
      logic Hit = 0;
      for(int i = 0; i < WAYS; i++) begin
        ValidWay[i] = Valid[i][Index];
        TagWay[i] = Tags[i][Index];
        DataWay[i] = Lines[i][Index];
        if(ValidWay[i] && (TagWay[i] == Tag)) begin
          HitWay <= i;
          Hit <= 1;
        end
      end

      if(Hit) begin
        Instruction <= DataWay[HitWay];
        InstructionReady <= 1;
      end else begin
        State <= 1;
        FetchAddress <= Tag;
        InstructionReady <= 0;
      end
    end else if(State == 1) begin
      // something something fetch routine to get 64 bytes
    end
  end
endmodule