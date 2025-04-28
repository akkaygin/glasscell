`default_nettype none

module glasscell(
  input Clock,
  input Reset
);

  logic[1:0] MemoryDataWidth;
  logic[31:0] MemoryAddress;
  logic[31:0] MemoryDataIn;
  logic[31:0] MemoryDataOut;

  logic MemoryBusCycle;
  logic MemoryBusStrobe;
  logic MemoryBusReadWrite;
  logic MemoryBusAcknowledge;
  logic MemoryBusStall;

  memoryemulator MainMemory(
    Clock,
    
    MemoryDataWidth,
    MemoryAddress,
    MemoryDataIn,
    MemoryDataOut,

    MemoryBusCycle,
    MemoryBusStrobe,
    MemoryBusReadWrite,

    MemoryBusAcknowledge,
    MemoryBusStall
  );

  logic InstructionReady;
  logic[31:0] InstructionAddress;
  logic[31:0] Instruction;

  instructioncache L1InstrcutionCache(
    Clock,
    Reset,

    InstructionAddress,
    Instruction,
    InstructionReady

    // memory
  );

  logic ReadComplete;
  logic WriteComplete;
  logic[31:0] DataToCore;
  logic ReadEnable;
  logic WriteEnable;
  logic[1:0] DataWidth;
  logic[31:0] DataFromCore;
  logic[31:0] DataAddress;

  datacache L1DataCache(
    Clock,
    Reset,

    ReadComplete,
    WriteComplete,

    ReadEnable,
    WriteEnable,

    DataWidth,
    DataToCore,
    DataFromCore,
    DataAddress

    // memory
  );

  logic Interrupt;
  logic Mode;

  sol32core Core(
    Clock,
    Reset,
    Interrupt,
    Mode,

    InstructionReady,
    Instruction,
    InstructionAddress,

    ReadComplete,
    WriteComplete,
    DataToCore,
    ReadEnable,
    WriteEnable,
    DataWidth,
    DataFromCore,
    DataAddress
  );

endmodule