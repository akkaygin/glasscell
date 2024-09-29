#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vsol32core.h"
#include "Vsol32core___024root.h"

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

void DrawTextRec(Font font, const char *text, Rectangle position, bool centered, Color tint) {
  Vector2 textSize = MeasureTextEx(font, text, position.height, 0);

  if(centered) {
    float centeredX = position.x + (position.width - textSize.x) / 2;
    float centeredY = position.y + (position.height - textSize.y) / 2;

    DrawTextEx(font, text, {centeredX, centeredY}, position.height, 0, tint);
  } else {

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
}
/* End of Raylib Extensions */

Vsol32core* glasscell;
VerilatedVcdC* tfp;

nat tc = 1;
bool StepMode = true;
nat StepsRemaining = 0;

Font BMTTF;
int BMTTFSpacing = -2;
Vector2 MeasuredFontDim;

MouseCursor Cursor;

void tick() {
  ++tc;
  glasscell->eval();
  tfp->dump(tc*10-2);

  glasscell->Clock = 1;
  glasscell->eval();
  tfp->dump(tc*10);

  glasscell->Clock = 0;
  glasscell->eval();
  tfp->dump(tc*10+5);
}

nat MemoryNAT32[] = {
  0x20000F00, // add r2 r0 r0 15
  0x11000100, // add r1 r1 r0 1
  0xF12FFFC1, // j-1 r1 != r2
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
  0x00000000, 0x00000000, 0x00000000, 0x00000000,
};

uint8_t* Memory = (uint8_t*)MemoryNAT32;

nat ReadMemory(nat Address, nat Width) {
  if(Address < 4*sizeof(MemoryNAT32)/sizeof(MemoryNAT32[0])) {
    switch(Width)
    {
    case 0: return Memory[Address];
    case 1: return Memory[Address] | (Memory[Address + 1] << 8);
    case 2: return Memory[Address] | (Memory[Address + 1] << 8)
                | (Memory[Address + 2] << 16) | (Memory[Address + 3] << 24);
    default: return 0;
    }
  } else {
    return 0;
  }
}

void WriteMemory(nat Address, nat Data, nat Width) {
  if(Address < 4*sizeof(MemoryNAT32)/sizeof(MemoryNAT32[0])) {
    switch(Width)
    {
    case 0:
        Memory[Address] = Data & 0xFF;
        break;
    case 1:
        Memory[Address] = Data & 0xFF;
        Memory[Address + 1] = (Data >> 8) & 0xFF;
        break;
    case 2:
        Memory[Address] = Data & 0xFF;
        Memory[Address + 1] = (Data >> 8) & 0xFF;
        Memory[Address + 2] = (Data >> 16) & 0xFF;
        Memory[Address + 3] = (Data >> 24) & 0xFF;
        break;
    }
  }
}

/* Blinkenlights */
void DrawBlinkenlights(uint32_t Data, nat Width, Rectangle Bounds, Color tintA, Color tintB) {
  for(nat i = 0; i < Width; i++) {
    if((Data >> (Width - 1 - i)) & 1)
      DrawRectangle(Bounds.x + (Bounds.width * i / Width),
        Bounds.y, Bounds.width / Width, Bounds.height, tintA);
    else
      DrawRectangle(Bounds.x + (Bounds.width * i / Width),
        Bounds.y, Bounds.width / Width, Bounds.height, tintB);
    
    DrawRectangleLinesEx({Bounds.x + (Bounds.width * i / Width),
      Bounds.y, Bounds.width / Width, Bounds.height}, 1.0f, {0x20, 0x20, 0x20, 0xFF});
  }
}

void DrawSRegisterBlinkenlights(Rectangle Bounds) {
  for(nat i = 0; i < 16; i++) {
    DrawBlinkenlights(glasscell->rootp->sol32core__DOT__SupervisorRegisterBank__DOT__RegisterBank[i],
        32, {Bounds.x, Bounds.y+Bounds.height*i/16, Bounds.width, Bounds.height/16}, RED, WHITE);
  }
}

void DrawURegisterBlinkenlights(Rectangle Bounds) {
  for(nat i = 0; i < 16; i++) {
    DrawBlinkenlights(glasscell->rootp->sol32core__DOT__UserRegisterBank__DOT__RegisterBank[i],
        32, {Bounds.x, Bounds.y+Bounds.height*i/16, Bounds.width, Bounds.height/16}, RED, WHITE);
  }
}

/* Button */
bool DrawButton(Rectangle Bounds, Color tintA, Color tintB) {
  if(CheckCollisionPointRec(GetMousePosition(), Bounds)) {
    Cursor = MOUSE_CURSOR_ARROW;

    if(IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
      return true;
    } else {
      DrawRectangleRec(Bounds, tintB);
      return false;
    }
  } else {
    DrawRectangleRec(Bounds, tintA);
    return false;
  }
}

/* Switches */
bool DrawSwitchH(Rectangle Bounds, bool state, Color tint) {
  DrawRectangleLines(Bounds.x, Bounds.y, Bounds.width, Bounds.height, tint);

  if(state) {
    Bounds = {Bounds.x + Bounds.width / 2, Bounds.y, Bounds.width / 2, Bounds.height};
  } else {
    Bounds = {Bounds.x, Bounds.y, Bounds.width / 2, Bounds.height};
  }

  if(CheckCollisionPointRec(GetMousePosition(), Bounds)) {
    Cursor = MOUSE_CURSOR_ARROW;

    if(IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
      state = !state;
    }
  }

  DrawRectangleRec(Bounds, tint);

  return state;
}

bool DrawSwitchV(Rectangle Bounds, bool state, Color tint) {
  DrawRectangleLines(Bounds.x, Bounds.y, Bounds.width, Bounds.height, tint);

  if(state) {
    Bounds = {Bounds.x, Bounds.y + Bounds.height / 2, Bounds.width, Bounds.height / 2};
  } else {
    Bounds = {Bounds.x, Bounds.y, Bounds.width, Bounds.height / 2};
  }

  if(CheckCollisionPointRec(GetMousePosition(), Bounds)) {
    Cursor = MOUSE_CURSOR_ARROW;

    if(IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
      state = !state;
    }
  }

  DrawRectangleRec(Bounds, tint);

  return state;
}

bool DrawSwitchT(Rectangle Bounds, bool state, Color tint) {
  DrawRectangleLines(Bounds.x, Bounds.y, Bounds.width, Bounds.height, tint);

  if(state) {
    DrawRectangleRec(Bounds, tint);
  }

  if(CheckCollisionPointRec(GetMousePosition(), Bounds)) {
    Cursor = MOUSE_CURSOR_ARROW;

    if(IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
      state = !state;
    }
  }

  return state;
}
/* End of Switches */

nat sw = 1024;
nat sh = 960;

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  glasscell = new Vsol32core;

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  glasscell->trace(tfp, 99);
  tfp->open("trace.vcd");

  glasscell->Instruction = ReadMemory(glasscell->InstructionPointer, 2);
  glasscell->Reset = 1;
  tick();

  SetConfigFlags(FLAG_MSAA_4X_HINT); 
  InitWindow(sw, sh, "sol32 Simulator");
  SetTargetFPS(15); // throttles cpu sim to XHz
  ShowCursor();
  SetWindowState(FLAG_WINDOW_UNDECORATED);

  BMTTF = LoadFontEx("BerkeleyMono.ttf", 24, 0, 250);
  SetTextLineSpacing(16);
  SetTextureFilter(BMTTF.texture, TEXTURE_FILTER_BILINEAR);
  MeasuredFontDim = MeasureTextEx(BMTTF, "0", BMTTF.baseSize, BMTTFSpacing);

  bool Reset = false;

  while(!WindowShouldClose()) {
    if(StepMode) {
      while(StepsRemaining > 0) {
        if(Reset) {
          glasscell->Reset = 1;
        } else {
          glasscell->Reset = 0;
        }

        glasscell->Instruction = ReadMemory(glasscell->InstructionPointer, 2);
        glasscell->DataIn = ReadMemory(glasscell->MemoryAddress, 2);
        if(glasscell->WriteEnable) {
          WriteMemory(glasscell->MemoryAddress, glasscell->DataOut, 2);
        }
        tick();
        
        StepsRemaining = StepsRemaining - 1;
      }
    } else {
      if(Reset) {
        glasscell->Reset = 1;
      } else {
        glasscell->Reset = 0;
      }

      glasscell->Instruction = ReadMemory(glasscell->InstructionPointer, 2);
      glasscell->DataIn = ReadMemory(glasscell->MemoryAddress, 2);
      if(glasscell->WriteEnable) {
        WriteMemory(glasscell->MemoryAddress, glasscell->DataOut, 2);
      }
      tick();
    }

    BeginDrawing();
    ClearBackground({0x0F, 0x0F, 0x0F, 0xFF});
    Cursor = MOUSE_CURSOR_DEFAULT;

    DrawTextRec(BMTTF, "Instruction Pointer", {20, 10, 16*20, 20}, false, WHITE);
    DrawBlinkenlights(glasscell->InstructionPointer >> 16, 16, {20, 30, 16*20, 10}, RED, WHITE);
    DrawBlinkenlights(glasscell->InstructionPointer & 0xFFFF, 16, {20, 40, 16*20, 10}, RED, WHITE);

    DrawTextRec(BMTTF, "Instruction", {20, 60, 16*20, 20}, false, WHITE);
    DrawBlinkenlights(glasscell->Instruction >> 16, 16, {20, 80, 16*20, 10}, RED, WHITE);
    DrawBlinkenlights(glasscell->Instruction & 0xFFFF, 16, {20, 90, 16*20, 10}, RED, WHITE);

    DrawTextRec(BMTTF, "Supervisor Register Set", {20, sh-190, 16*20, 20}, false, WHITE);
    DrawSRegisterBlinkenlights({20, sh-170, 320, 10*16});

    DrawTextRec(BMTTF, "Run / Step", {360, 10, 120, 20}, false, WHITE);
    StepMode = DrawSwitchH({360, 30, 120, 20}, StepMode, WHITE);

    DrawTextRec(BMTTF, "Step", {360, 60, 120, 20}, true, WHITE);
    if(StepMode) {
      if(DrawButton({360, 80, 60, 20}, WHITE, RED)) StepsRemaining = StepsRemaining + 1;
      if(DrawButton({420, 80, 30, 20}, {0xD0, 0xD0, 0xD0, 0xFF}, RED)) StepsRemaining = StepsRemaining + 4;
      if(DrawButton({450, 80, 30, 20}, {0xB0, 0xB0, 0xB0, 0xFF}, RED)) StepsRemaining = StepsRemaining + 16;

      DrawTextRec(BMTTF, "1", {360, 80, 60, 20}, true, BLACK);
      DrawTextRec(BMTTF, "4", {420, 80, 30, 20}, true, BLACK);
      DrawTextRec(BMTTF, "16", {450, 80, 30, 20}, true, BLACK);
    } else {
      DrawRectangleRec({360, 80, 120, 20}, {0xA0, 0xA0, 0xA0, 0xFF});
    }

    DrawTextRec(BMTTF, "Reset", {360, 110, 120, 20}, true, WHITE);
    Reset = !DrawSwitchT({360, 130, 120, 20}, !Reset, WHITE);

    SetMouseCursor(Cursor);
    EndDrawing();
  }

  tfp->close();
  CloseWindow();
  return 0;
}
