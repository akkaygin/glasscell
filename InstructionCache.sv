`default_nettype none

module instructioncache(
  input Clock,
  input Reset,

  input[31:0] InstructionAddress,
  output[31:0] Instruction,
  output InstructionReady
);

  localparam WAYS = 2;
  localparam CACHE_CAPACITY = 16386;
  localparam LINE_CAPACITY = 64;
  localparam LINE_COUNT = ((CACHE_CAPACITY/WAYS)/LINE_CAPACITY);
  localparam LC_L2 = $clog2(LINE_COUNT);
  localparam OFFSET_WIDTH = $clog2(LINE_CAPACITY);
  localparam INDEX_WIDTH = $clog2((CACHE_CAPACITY/WAYS)/LINE_CAPACITY);
  localparam TAG_WIDTH = 32-(OFFSET_WIDTH+INDEX_WIDTH);

  logic[TAG_WIDTH-1:0] Tags[WAYS-1:0][LC_L2-1:0];
  logic[LINE_CAPACITY-1:0] Lines[WAYS-1:0][LC_L2-1:0];
  logic Valid[WAYS-1:0][LC_L2-1:0];

  logic[TAG_WIDTH-1:0] Tag = InstructionAddress[31:32-TAG_WIDTH];
  logic[INDEX_WIDTH-1:0] Index = InstructionAddress[31-TAG_WIDTH:32-TAG_WIDTH-INDEX_WIDTH];
  logic[OFFSET_WIDTH-1:0] Offset = InstructionAddress[OFFSET_WIDTH-1:0];

  // i need an evacuation policy, lru probably

  logic State;
  logic[TAG_WIDTH-1:0] FetchAddress;

  initial begin
    State <= 0;

    for(int i = 0; i < WAYS; i++) begin
      for(int j = 0; j < LC_L2; j++) begin
        Valid[i][j] <= 0;
      end
    end
  end

  always_ff@(posedge Clock) begin
    if(Reset) begin
      State <= 0;

      for(int i = 0; i < WAYS; i++) begin
        for(int j = 0; j < LC_L2; j++) begin
          Valid[i][j] <= 0;
        end
      end
    end else if(State == 0) begin
      logic Hit = 0;
      logic[$clog2(WAYS)-1:0] HitWay;
      for(int i = 0; i < WAYS; i++) begin
        if(Tag == Tags[i][Index] && Valid[i][Index]) begin
          Hit <= 1;
          //HitWay <= i;
        end
      end

      if(Hit) begin
        Instruction <= Lines[HitWay][Tag][Offset];
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