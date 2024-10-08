`default_nettype none
`timescale 10ps/1ps

module sol32core(
  input Clock,
  input Reset,
  input Interrupt,
  output Mode,

  input[31:0] Instruction,
  output[31:0] InstructionPointer,

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

  assign Mode = CoreControlRegister[31];

  always_ff@(posedge Clock) begin : Ctr
    if(Interrupt) begin
      CoreControlRegister[31] <= 0;
    end
  end

  logic InternalClock;
  assign InternalClock = Clock;

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
  logic[31:0] TargetOut_SR;

  logic[31:0] InstructionPointerOut_SR;
  
  registerbank SupervisorRegisterBank(
    InternalClock, Reset,
    !CoreControlRegister[31],
    
    Source1Address,
    Source2Address,
    TargetAddress,

    TargetWriteEnable_SR,
    TargetIn,
    
    Source1Out_SR,
    Source2Out_SR,
    TargetOut_SR,

    InstructionPointerOut_SR
  );

  logic TargetWriteEnable_UR;
  
  logic[31:0] Source1Out_UR;
  logic[31:0] Source2Out_UR;
  logic[31:0] TargetOut_UR;

  logic[31:0] InstructionPointerOut_UR;
  
  registerbank UserRegisterBank(
    InternalClock, Reset,
    CoreControlRegister[31],
    
    Source1Address,
    Source2Address,
    TargetAddress,

    TargetWriteEnable_UR,
    TargetIn,
    
    Source1Out_UR,
    Source2Out_UR,
    TargetOut_UR,

    InstructionPointerOut_UR
  );

  assign InstructionPointer = CoreControlRegister[31] ?
      InstructionPointerOut_UR : InstructionPointerOut_SR;

  logic[31:0] Source1;
  logic[31:0] Source2;
  logic[31:0] Result;
  logic[3:0] MinInstr;

  logic[31:0] Embedded;
  always_comb begin : EmbeddedSESH
    if(Instruction[6:4] == 3'b000) begin
      Embedded = {{22{Instruction[7]}}, Instruction[17:8]} << {Instruction[19:18], 3'b000};
    end else if(Instruction[6:4] == 3'b001) begin
      Embedded = {{16{Instruction[7]}}, Instruction[23:8]};
    end else if(Instruction[6:4] == 3'b100 || Instruction[6:3] == 4'b0111) begin
      Embedded = {{14{Instruction[7]}}, Instruction[31:28], Instruction[19:8], 2'b00};
    end else if(Instruction[6:3] == 4'b0110) begin
      Embedded = {{14{Instruction[7]}}, Instruction[27:24], Instruction[19:8], 2'b00};
    end else begin
      Embedded = {{20{Instruction[7]}}, Instruction[19:8]};
    end
  end

  always_comb begin : CJInSet
    if(Instruction[6:4] == 3'b100) begin
      MinInstr = 0;
      Source1 = InstructionPointer;
      Source2 = Embedded;
      
      CompSource1 = (CoreControlRegister[31] ?
          Source1Out_UR : Source1Out_SR);
      CompSource2 = (CoreControlRegister[31] ?
          Source2Out_UR : Source2Out_SR);
    end else begin
      MinInstr = Instruction[3:0];
      Source1 = (CoreControlRegister[31] ?
          Source1Out_UR : Source1Out_SR);
      Source2 = (CoreControlRegister[31] ?
          Source2Out_UR : Source2Out_SR) + Embedded;
        
      CompSource1 = 0;
      CompSource2 = 0;
    end
  end

  logic[3:0] ALUFlags;

  logic[31:0] Result_ALU2;
  logic[3:0] ALU2Flags;
  alu2 ALU2(
    MinInstr,
    Source1,
    Source2,
    ALU2Flags,
    Result_ALU2
  );

  logic[31:0] Result_ALU1;
  logic[3:0] ALU1Flags;
  alu1 ALU1(
    MinInstr,
    Source1,
    ALU1Flags,
    Result_ALU1
  );

  always_ff@(posedge Clock) begin : ALUFlagsSel
    if(Instruction[6:4] == 3'b000) begin
      ALUFlags = ALU2Flags;
    end else begin
      ALUFlags = ALU1Flags;
    end
  end
  
  logic[31:0] CompSource1;
  logic[31:0] CompSource2;
  logic Result_COMP;
  comparator Comparator(
    Instruction[3:0],
    ALUFlags,
    CompSource1,
    CompSource2,
    Result_COMP
  );

  assign ReadEnable = Instruction[6:3] == 4'b0110;
  assign WriteEnable = Instruction[6:3] == 4'b0111;
  assign DataWidth = Instruction[1:0];
  assign MemoryAddress = Source2;

  always_comb begin : TargetWECtr
    if(Instruction[6:0] == 7'h7E) begin
      TargetWriteEnable_SR = 0;
      TargetWriteEnable_UR = 1;
    end else if(Instruction[6:4] == 3'b011 && Instruction[3]) begin
      TargetWriteEnable_SR = 0;
      TargetWriteEnable_UR = 0;
    end else begin
      if(Instruction[6:4] == 3'b100) begin
        TargetWriteEnable_SR = Result_COMP & ~CoreControlRegister[31];
        TargetWriteEnable_UR = Result_COMP & CoreControlRegister[31];
      end else begin
        TargetWriteEnable_SR = ~CoreControlRegister[31];
        TargetWriteEnable_UR = CoreControlRegister[31];
      end
    end
  end

  assign DataOut = Source1;

  always_comb begin : ResultSel
    logic[31:0] ResImm;

    if(Instruction[6:0] == 7'h7E) begin
      ResImm = TargetOut_SR;
    end else if(Instruction[6:0] == 7'h7F) begin
      ResImm = TargetOut_UR;
    end else if(Instruction[6:0] == 7'h77) begin
      ResImm = CoreControlRegister;
    end else if(Instruction[6:3] == 4'b0110) begin
      ResImm = DataIn;
    end else begin
      case(Instruction[6:4])
        3'b000: ResImm = Result_ALU2;
        3'b001: ResImm = Result_ALU2;

        3'b010: ResImm = Result_ALU1;

        3'b100: ResImm = Result_ALU2;
        default: ResImm = 0;
      endcase
    end

    TargetIn = ResImm;
  end
endmodule
