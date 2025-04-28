`default_nettype none

module alu1(
  input[3:0] Operation,

  input[31:0] Operand1,

  output[3:0]  Flags,
  output[31:0] Result
);
  logic[31:0] ResImm;
  always_comb begin
    case(Operation)
      default: ResImm = 0;
    endcase
  end

  assign Flags  = 0;
  assign Result = ResImm;
endmodule
