#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vglasscell.h"
#include "Vglasscell___024root.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef uint32_t nat;

Vglasscell* glasscell;
VerilatedVcdC* tfp;

nat CycleCount = 0;
bool StepMode = false;
nat StepsRemaining = 32;

void ClockPosedge() {
  ++CycleCount;
  glasscell->eval();
  //tfp->dump(CycleCount*10-2);

  glasscell->Clock = 1;
  glasscell->eval();
  tfp->dump(CycleCount*10);  
}

void ClockNegedge() {
  glasscell->Clock = 0;
  glasscell->eval();
  tfp->dump(CycleCount*10+5);
}

nat MemoryNAT32[] = {
0x00000440,
0x68656C6C,
0x6F000000,
0x0F000000,
0x20100030,
0x10000100,
0xF31FFEC3,
};

uint8_t* Memory = (uint8_t*)MemoryNAT32;

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  glasscell = new Vglasscell;

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  glasscell->trace(tfp, 99);
  tfp->open("trace.vcd");

  glasscell->Reset = 1;
  ClockPosedge();
  ClockNegedge();
  ClockPosedge();
  ClockNegedge();
  glasscell->Reset = 0;

  for(int i = 0; i < 32; i += 4) {
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+0] = i+0;
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+1] = i+1;
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+2] = i+2;
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+3] = i+3;
    continue;
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+0] = Memory[i+3];
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+1] = Memory[i+2];
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+2] = Memory[i+1];
    glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory[i+3] = Memory[i+0];
  }

  for(int i = 0; i < 32; i += 4) {}

  while(StepsRemaining > 0) {
    glasscell->eval();
    ClockPosedge();
    ClockNegedge();
    glasscell->eval();
    
    StepsRemaining = StepsRemaining - 1;
  }
  
  tfp->close();
  return 0;
}
