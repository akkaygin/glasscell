`default_nettype none

module sol32core(
  input logic Clock,
  input logic Reset,

  input logic InstructionReady,
  input logic[31:0] Instruction,
  output logic[31:0] InstructionAddress
);

  logic InternalClock;
  always_comb begin
    InternalClock = Clock & InstructionReady;
  end

  //logic[31:0] InstructionAddress;
  initial InstructionAddress = 0;

  always_ff@(posedge InternalClock) begin
    if(Reset) begin
      InstructionAddress <= 0;
    end else begin
      InstructionAddress <= InstructionAddress + 1;
    end
  end
endmodule
