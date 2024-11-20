`default_nettype none

module sol32core(
  input Clock,
  input Reset,
  input Interrupt,
  output Mode,

  input InstructionReady,
  input[31:0] Instruction,
  output[31:0] InstructionPointer,

  input ReadComplete,
  input WriteComplete,
  input[31:0] DataIn,
  output ReadEnable,
  output WriteEnable,
  output[1:0] DataWidth,
  output[31:0] DataOut,
  output[31:0] MemoryAddress
);

  logic[31:0] CoreControlRegister;
  initial begin
    CoreControlRegister = '0;
  end

  assign Mode = !CoreControlRegister[31];

  logic InternalClock;
  always_comb begin
    InternalClock = Clock & InstructionReady;
  end

  logic[3:0] Source1Address;
  logic[3:0] Source2Address;
  logic[3:0] TargetAddress;
  logic[31:0] TargetIn;
  
  assign Source1Address = Instruction[27:24];
  assign Source2Address = Instruction[23:20];

  always_comb begin
    if(Instruction[6:4] == 3'b100) begin
      TargetAddress = 15;
    end else begin
      TargetAddress  = Instruction[31:28];
    end
  end

  logic TargetWriteEnable_SR;
  
  logic[31:0] Source1Out_SR;
  logic[31:0] Source2Out_SR;

  logic[31:0] InstructionPointerOut_SR;
  
  registerbank SupervisorRegisterBank(
    InternalClock, Reset,
    Mode,
    
    Source1Address,
    Source2Address,
    TargetAddress,

    TargetWriteEnable_SR,
    TargetIn,
    
    Source1Out_SR,
    Source2Out_SR,

    InstructionPointerOut_SR
  );

  assign TargetWriteEnable_SR = 1;
  assign TargetAddress = 15;
  assign Source1Address = 15;

  always_ff@(posedge InternalClock) begin
    TargetIn <= InstructionPointerOut_SR + 4;
    $display("rF: 0x%08X", InstructionPointerOut_SR);
  end
endmodule
