`default_nettype none

module alu2(
  input[3:0] Operation,

  input[31:0] Operand1,
  input[31:0] Operand2,

  output[3:0]  Flags,
  output[31:0] Result
);

  logic[3:0]  FlagsImm;
  logic[31:0] ResImm;
  always_comb begin
    FlagsImm[2] = 0;
    case(Operation)
      4'h0: {FlagsImm[2], ResImm} = Operand1 + Operand2;
      4'h8: {FlagsImm[2], ResImm} = {1'b0, Operand1} - {1'b0, Operand2};
      4'h4: ResImm = Operand1 << Operand2[4:0];
      4'hC: ResImm = Operand1 >> Operand2[4:0];

      4'h1: ResImm = Operand1 & Operand2;
      4'h2: ResImm = Operand1 | Operand2;
      4'hA: ResImm = Operand1 ^ Operand2;
      4'h9: ResImm = Operand1 & ~Operand2;
      
      4'hB: ResImm = Operand1 >>> Operand2[4:0];

      4'h7: ResImm = Operand1 * Operand2; // temp until mdu
      4'hF: ResImm = Operand1 / Operand2; // temp until mdu
      default: ResImm = '0;
    endcase
  end

  // Doesn't work?
  always_comb begin : NEGMagic
    logic NEGMagic1;
    NEGMagic1 = ((Operation == 0) && (Operand1[31] == Operand2[31])) // ADD
             || ((Operation == 1) && (Operand1[31] != Operand2[31]));// SUB
    FlagsImm[1] = ResImm[31] ^ ((Operand1[31] != ResImm[31]) && NEGMagic1);
  end

  always_comb begin : OVFMagic
    logic OVFMagic1;
    OVFMagic1 = ((Operation == 0) && (Operand1[31] == Operand2[31])) // ADD
             || ((Operation == 1) && (Operand1[31] != Operand2[31])) // SUB
             || (Operation == 3) // SL
             || (Operation == 4);// SR
    FlagsImm[3] = (Operand1[31] != ResImm[31]) && OVFMagic1;
  end

  assign Flags  = FlagsImm;
  assign Result = ResImm;
endmodule
