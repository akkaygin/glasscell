#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vglasscell.h"
#include "Vglasscell___024root.h"

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

Vglasscell* glasscell;
VerilatedVcdC* tfp;

nat CycleCount = 0;
bool StepMode = true;
nat StepsRemaining = 0;

Font BMTTF;
int BMTTFSpacing = -2;
Vector2 MeasuredFontDim;

MouseCursor Cursor;

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

nat ReadMemory(nat Address, nat Width) {
  if(Address < 4*sizeof(MemoryNAT32)/sizeof(MemoryNAT32[0])) {
    switch(Width)
    {
    case 0: return Memory[Address];
    case 1: return Memory[Address] | (Memory[Address + 1] << 8);
    case 2: printf("RD %08X AT ADDRESS %08X\n", Memory[Address] | (Memory[Address + 1] << 8)
                | (Memory[Address + 2] << 16) | (Memory[Address + 3] << 24), Address); return Memory[Address] | (Memory[Address + 1] << 8)
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
        printf("WR %08X AT ADDRESS %08X\n", Data, Address);
        break;
    }
  }
}

/* Terminal Emultaor */
/* End of Terminal Emultaor */

/* Blinkenlights */
Color BlinkenlightsOutlineColor = BLACK;
float BlinkenlightsOutlineThickness = 1.0f;
int BlinkenlightsDirection = 0;

void DrawBlinkenlights(uint32_t Data, nat Width, Rectangle Bounds, Color tintA, Color tintB) {
  for(nat i = 0; i < Width; i++) {
    if(BlinkenlightsDirection == 0) {
      if((Data >> (Width - 1 - i)) & 1)
        DrawRectangle(Bounds.x + (Bounds.width * i / Width),
          Bounds.y, Bounds.width / Width, Bounds.height, tintA);
      else
        DrawRectangle(Bounds.x + (Bounds.width * i / Width),
          Bounds.y, Bounds.width / Width, Bounds.height, tintB);
      
      DrawRectangleLinesEx({Bounds.x + (Bounds.width * i / Width),
        Bounds.y, Bounds.width / Width, Bounds.height}, BlinkenlightsOutlineThickness, BlinkenlightsOutlineColor);
    } else if(BlinkenlightsDirection == 1) {
      if((Data >> (Width - 1 - i)) & 1)
        DrawRectangle(Bounds.x, Bounds.y + (Bounds.height * i / Width),
            Bounds.width, Bounds.height / Width, tintA);
      else
        DrawRectangle(Bounds.x, Bounds.y + (Bounds.height * i / Width),
            Bounds.width, Bounds.height / Width, tintB);
      
      DrawRectangleLinesEx({Bounds.x, Bounds.y + (Bounds.height * i / Width),
            Bounds.width, Bounds.height / Width}, BlinkenlightsOutlineThickness, BlinkenlightsOutlineColor);
    }
  }
}

void DrawSRegisterBlinkenlights(Rectangle Bounds, Color tintA, Color tintB) {
  for(nat i = 0; i < 16; i++) {
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__Core__DOT__SupervisorRegisterBank__DOT__RegisterBank[i],
        32, {Bounds.x, Bounds.y+Bounds.height*i/16, Bounds.width, Bounds.height/16}, tintA, tintB);
  }
}

void DrawURegisterBlinkenlights(Rectangle Bounds, Color tintA, Color tintB) {
  for(nat i = 0; i < 16; i++) {
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__Core__DOT__SupervisorRegisterBank__DOT__RegisterBank[i],
        32, {Bounds.x, Bounds.y+Bounds.height*i/16, Bounds.width, Bounds.height/16}, tintA, tintB);
  }
}

void DrawMemoryBlinkenlights(nat Base, nat Range, Rectangle Bounds, Color tintA, Color tintB) {
  for(nat i = Base; i < Range; i++) {
    if(Base + i < sizeof(MemoryNAT32)/sizeof(MemoryNAT32[0])) {
      DrawBlinkenlights(MemoryNAT32[Base + i],
          32, {Bounds.x, Bounds.y+Bounds.height*i/Range, Bounds.width, Bounds.height/Range}, tintA, tintB);
    } else {
      DrawBlinkenlights(0,
          32, {Bounds.x, Bounds.y+Bounds.height*i/Range, Bounds.width, Bounds.height/Range}, tintA, tintB);
    }
  }
}
/* End of Blinkenlights */

/* Segment Displays */
enum sevensegmentarraydisplaymode {
  SSADM_HORDEC = 0,
  SSADM_HORHEX = 1,
  SSADM_VERDEC = 2,
  SSADM_VERHEX = 3,
};

int SevenSegmentMap[] = {
  0b1110111,

  0b0010010,
  0b1011101,
  0b1011011,
  0b0111010,
  0b1101011,
  0b1101111,
  0b1011010,
  0b1111111,
  
  0b1111011,
  0b1111110,
  0b0101111,
  0b1100101,
  0b0011111,
  0b1101101,
  0b1101100,
};

Color SegmentsOutlineColor = BLACK;
float SegmentsOutlineThickness = 0.5f;

float SegmentsHSegmentWCoeff = 0.60f;
float SegmentsHSegmentHCoeff = 0.20f;
float SegmentsVSegmentWCoeff = 0.20f;
float SegmentsVSegmentHCoeff = 0.5f;

void DrawSevenSegmentDisplay(nat Data, Rectangle Bounds, Color tintA, Color tintB) {
  float hSegmentW = Bounds.width  * SegmentsHSegmentWCoeff;
  float hSegmentH = Bounds.height * SegmentsHSegmentHCoeff;
  float vSegmentW = Bounds.width  * SegmentsVSegmentWCoeff;
  float vSegmentH = Bounds.height * SegmentsVSegmentHCoeff;

  Rectangle Segments[] = {
    { Bounds.x + vSegmentW, Bounds.y, hSegmentW, hSegmentH },
    { Bounds.x, Bounds.y, vSegmentW, vSegmentH },
    { Bounds.x + Bounds.width - vSegmentW, Bounds.y, vSegmentW, vSegmentH },

    { Bounds.x + vSegmentW, Bounds.y + vSegmentH - hSegmentH * 0.5f, hSegmentW, hSegmentH },
    
    { Bounds.x, Bounds.y + vSegmentH, vSegmentW, vSegmentH },
    { Bounds.x + Bounds.width - vSegmentW, Bounds.y + vSegmentH, vSegmentW, vSegmentH },
    { Bounds.x + vSegmentW, Bounds.y + Bounds.height - hSegmentH, hSegmentW, hSegmentH },
  };

  for (int i = 6; i >= 0; i--) {
    if ((SevenSegmentMap[Data] >> (6-i)) & 1) {
      DrawRectangleRec(Segments[i], tintA);
    } else {
      DrawRectangleRec(Segments[i], tintB);
    }
  }

  for(int i = 0; i < 7; i++) {
    DrawRectangleLinesEx(Segments[i], SegmentsOutlineThickness, SegmentsOutlineColor);
  }
}

sevensegmentarraydisplaymode SevenSegmentDisplayArrayMode = SSADM_HORDEC;
float SevenSegmentDisplayArraySpacingCoeff = 0.8f;

void DrawSevenSegmentDisplayArray(nat Data, nat Width, Rectangle Bounds, Color tintA, Color tintB) {
  for(int i = Width-1; i >= 0; i--) {
    Rectangle Bounds2;

    if(SevenSegmentDisplayArrayMode >> 1) {
      Bounds2 = { Bounds.x, Bounds.y + Bounds.height * i / Width, Bounds.width, (Bounds.height / Width) * SevenSegmentDisplayArraySpacingCoeff};
    } else {
      Bounds2 = { Bounds.x + Bounds.width * i / Width, Bounds.y, (Bounds.width / Width) * SevenSegmentDisplayArraySpacingCoeff, Bounds.height};
    }

    nat Data2;
    if(SevenSegmentDisplayArrayMode & 1) {
      Data2 = Data & 0xF;
      Data = Data >> 4;
    } else {
      Data2 = Data % 10;
      Data = Data / 10;
    }

    DrawSevenSegmentDisplay(Data2, Bounds2, tintA, tintB);
  }
}
/* End of Segment Displays */

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

nat sw = 800;
nat sh = 900;

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  glasscell = new Vglasscell;

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  glasscell->trace(tfp, 99);
  tfp->open("trace.vcd");

  // system ram
  //glasscell->rootp->glasscell__DOT__MainMemory__DOT__Memory

  SetConfigFlags(FLAG_MSAA_4X_HINT); 
  InitWindow(sw, sh, "sol32 Simulator");
  SetTargetFPS(15);
  ShowCursor();

  BMTTF = LoadFontEx("BerkeleyMono.ttf", 24, 0, 250);
  SetTextLineSpacing(16);
  SetTextureFilter(BMTTF.texture, TEXTURE_FILTER_BILINEAR);
  MeasuredFontDim = MeasureTextEx(BMTTF, "0", BMTTF.baseSize, BMTTFSpacing);

  bool Reset = false;
  nat MemoryBLBase = 0;
  nat MemoryBLRange = 32;
  SevenSegmentDisplayArrayMode = SSADM_HORHEX;

  while(!WindowShouldClose()) {
    if(!StepMode) {
      StepsRemaining = 8000; 
    }

    if(Reset) {
      glasscell->Reset = 1;
      ClockPosedge();
      ClockNegedge();
      glasscell->Reset = 0;
      Reset = false;
    }

    while(StepsRemaining > 0) {
      glasscell->eval();
      ClockPosedge();
      ClockNegedge();
      glasscell->eval();
      
      StepsRemaining = StepsRemaining - 1;
    }

    BeginDrawing();
    ClearBackground({0x0F, 0x0F, 0x0F, 0xFF});
    Cursor = MOUSE_CURSOR_DEFAULT;

    DrawTextRec(BMTTF, "Instruction Pointer", {16, 10, 368, 20}, false, WHITE);
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__InstructionAddress >> 16, 16, {16, 30, 368, 10}, RED, WHITE);
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__InstructionAddress & 0xFFFF, 16, {16, 40, 368, 10}, RED, WHITE);

    DrawTextRec(BMTTF, "Instruction", {16, 60, 368, 20}, false, WHITE);
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__L1InstrcutionCache__DOT___Instruction >> 16, 16, {16, 80, 368, 10}, RED, WHITE);
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__L1InstrcutionCache__DOT___Instruction & 0xFFFF, 16, {16, 90, 368, 10}, RED, WHITE);
    
    DrawTextRec(BMTTF, "Core Control Register", {24, 110, 352, 20}, false, WHITE);
    DrawBlinkenlights(glasscell->rootp->glasscell__DOT__Core__DOT__CoreControlRegister, 32, {24, 130, 352, 20}, GREEN, WHITE);

    DrawTextRec(BMTTF, "Cycle Count", {520, 840, 120, 20}, false, WHITE);
    DrawSevenSegmentDisplayArray(CycleCount, 6, {520, 860, 120, 20}, GREEN, {50, 50, 50, 255});

    DrawTextRec(BMTTF, "Run / Step", {20, 840, 120, 20}, false, WHITE);
    StepMode = DrawSwitchH({20, 860, 120, 20}, StepMode, WHITE);

    DrawTextRec(BMTTF, "Step", {160, 840, 120, 20}, true, WHITE);
    if(StepMode) {
      if(DrawButton({160, 860, 60, 20}, WHITE, RED)) StepsRemaining = StepsRemaining + 1;
      if(DrawButton({220, 860, 30, 20}, {0xD0, 0xD0, 0xD0, 0xFF}, RED)) StepsRemaining = StepsRemaining + 4;
      if(DrawButton({250, 860, 30, 20}, {0xB0, 0xB0, 0xB0, 0xFF}, RED)) StepsRemaining = StepsRemaining + 16;

      DrawTextRec(BMTTF, "1", {160, 860, 60, 20}, true, BLACK);
      DrawTextRec(BMTTF, "4", {220, 860, 30, 20}, true, BLACK);
      DrawTextRec(BMTTF, "16", {250, 860, 30, 20}, true, BLACK);
    } else {
      DrawRectangleRec({160, 860, 120, 20}, {0xA0, 0xA0, 0xA0, 0xFF});
    }

    DrawTextRec(BMTTF, "Reset", {660, 840, 120, 20}, true, WHITE);
    Reset = DrawButton({660, 860, 120, 20}, WHITE, RED);

    SetMouseCursor(Cursor);
    EndDrawing();
  }
  
  tfp->close();
  CloseWindow();
  return 0;
}
