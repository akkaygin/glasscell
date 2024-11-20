`default_nettype none

module glasscell(
  input Clock,
  input Reset
);

  /*
    what do i need/the soc layout
    core interfaces with L1 caches, direct addressed
    caches go to an arbiter, address passes through the mmu
      maybe the mmu can do the lookup while the other cache
      is holding the bus, for long tlb/segment search
    then the L2? maybe, not necessary for now
    then dma? i dont even know how this works
      also different peripherals on the same bus will need another arbiter
    then the ram, memory accessed peripherals (these may go together with the dma)

    notes:
    - apple is using unified memory for the new chips, so its viable
    and possible, i should do the same with spu, fpu, vpu,...
    - a big(?) problem is when i fully convert the system to verilog
    how am i going to dynamically load the program into memory/disk
    if i can update a buffer from verilator this is simple
    - for now i can ignore the data cache and the arbiter, if i can
    read instructions from the simulated ram and the instruction cache
    the rest is easy to implement (lol, lmao)
  */

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
    InstructionReady,

    MemoryBusCycle,
    MemoryBusStrobe,
    MemoryBusReadWrite,
    MemoryBusAcknowledge,
    MemoryBusStall,

    MemoryAddress,
    MemoryDataIn
  );

  logic ReadComplete;
  logic WriteComplete;
  logic[31:0] DataToCore;
  logic ReadEnable;
  logic WriteEnable;
  logic[1:0] DataWidth;
  logic[31:0] DataFromCore;
  logic[31:0] DataAddress;
  /*
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
  */
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