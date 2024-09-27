`default_nettype none

module comparator(
  input[3:0] Operation,

  input[3:0] Flags,
  input[31:0] Operand1,
  input[31:0] Operand2,

  output Result
);

  logic ResImm;
  always_comb begin
    case(Operation)
      4'h0: ResImm = Operand1 == Operand2;
      4'h1: ResImm = Operand1 != Operand2;
      4'h2: ResImm = Operand1 >= Operand2;
      4'h3: ResImm = Operand1 >  Operand2;
      4'h4: ResImm = $signed(Operand1) >= $signed(Operand2);
      4'h5: ResImm = $signed(Operand1) >  $signed(Operand2);
      
      4'h8: ResImm = Flags[0];
      4'h9: ResImm = Flags[1];
      4'hA: ResImm = Flags[2];
      4'hB: ResImm = Flags[3];

      default: ResImm = 0;
    endcase
  end
  
  assign Result = ResImm;
endmodule
