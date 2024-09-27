#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vsol32core.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <raylib.h>

typedef uint32_t nat;

/* Raylib Extensions */
typedef struct {
  int centerX;
  int centerY;
  float radius;
} Circle;

void DrawTextRec(Font font, const char *text, Rectangle position, Color tint) {
  Vector2 textSize = MeasureTextEx(font, text, position.height, 0);

  float calcdw = 0;
  if (textSize.x < position.width) {
    float extraSpace = position.width - textSize.x;
    int textLength = strlen(text);
    if (textLength > 1) {
        calcdw = extraSpace / (textLength - 1);
    }
  }

  DrawTextEx(font, text, {position.x, position.y}, position.height, calcdw, tint);
}
/* End of Raylib Extensions */

Vsol32core* glasscell;
VerilatedVcdC* tfp;

void pretick() {
  glasscell->eval();
}

void tick(int tc) {
  //tb->eval();
  tfp->dump(tc*10-2);
  
  glasscell->Clock = 1;
  glasscell->eval();
  tfp->dump(tc*10);
  
  glasscell->Clock = 0;
  glasscell->eval();
  tfp->dump(tc*10+5);

  tfp->flush();
}

nat MemoryNAT32[] = {
  0x100000F0, 0x100000F0, 0x100000F0, 0x100000F0,
  0xFFFFFFFF, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
};

uint8_t* Memory = (uint8_t*)MemoryNAT32;

// Accesses are big endian
nat ReadMemory(nat Address, nat Width) {
  if(Address < sizeof(Memory)) {
    switch(Width)
    {
    case 0: return Memory[Address];
    case 1: return Memory[Address + 1] | (Memory[Address] << 8);
    case 2: return Memory[Address + 3] | (Memory[Address + 2] << 8)
                | (Memory[Address + 1] << 16) | (Memory[Address] << 24);
    default: return 0;
    }
  } else {
    return 0;
  }
}

void WriteMemory(nat Address, nat Data, nat Width) {
  if(Address < sizeof(Memory)) {
    switch(Width)
    {
    case 0:
        Memory[Address] = Data & 0xFF;
        break;
    case 1:
        Memory[Address + 1] = Data & 0xFF;
        Memory[Address] = (Data >> 8) & 0xFF;
        break;
    case 2:
        Memory[Address + 3] = Data & 0xFF;
        Memory[Address + 2] = (Data >> 8) & 0xFF;
        Memory[Address + 1] = (Data >> 16) & 0xFF;
        Memory[Address] = (Data >> 24) & 0xFF;
        break;
    }
  }
}

/* Blinkenlights */
void DrawBlinkenlights(uint32_t Data, nat Width, Rectangle Bounds) {
  for(nat i = 0; i < Width; i++) {
    if((Data >> (Width - 1 - i)) & 1)
      DrawRectangle(Bounds.x + (Bounds.width * i / Width),
        Bounds.y, Bounds.width / Width, Bounds.height, RED);
    else
      DrawRectangle(Bounds.x + (Bounds.width * i / Width),
        Bounds.y, Bounds.width / Width, Bounds.height, WHITE);
    
    DrawRectangleLinesEx({Bounds.x + (Bounds.width * i / Width),
      Bounds.y, Bounds.width / Width, Bounds.height}, 1, {0x20, 0x20, 0x20, 0xFF});
  }
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  glasscell = new Vsol32core;

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  glasscell->trace(tfp, 99);
  tfp->open("trace.vcd");

  nat tc = 0;
  bool StepMode = true;
  bool Step = false;

  glasscell->Reset = 1;
  glasscell->Instruction = 0;
  tick(++tc);
  tick(++tc);
  glasscell->Reset = 0;

  SetConfigFlags(FLAG_MSAA_4X_HINT); 
  InitWindow(1024, 960, "glasscell Simulator");
  SetTargetFPS(60);

  while(!WindowShouldClose()) {
    if(!(tc < 32)) {
      tfp->close();
      break;
    }

    if(StepMode) {
      if(Step) {
        pretick();
        glasscell->Instruction = ReadMemory(glasscell->InstructionPointer, 3);
        glasscell->DataIn = ReadMemory(glasscell->MemoryAddress, 3);
        if(glasscell->WriteEnable) {
          WriteMemory(glasscell->MemoryAddress, glasscell->DataOut, 3);
        }
        tick(++tc);

        Step = false;
      }
    } else {
      pretick();
      glasscell->Instruction = ReadMemory(glasscell->InstructionPointer, 3);
      glasscell->DataIn = ReadMemory(glasscell->MemoryAddress, 3);
      if(glasscell->WriteEnable) {
        WriteMemory(glasscell->MemoryAddress, glasscell->DataOut, 3);
      }
      tick(++tc);
    }

    BeginDrawing();
    ClearBackground({0x0F, 0x0F, 0x0F, 0xFF});



    EndDrawing();
  }

  tfp->close();
  CloseWindow();
  return 0;
}
