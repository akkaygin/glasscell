`default_nettype none

module datacache(
  input Clock,
  input Reset,

  output ReadComplete,
  output WriteComplete,

  input ReadEnable,
  input WriteEnable,

  input[1:0] DataWidth,
  output[31:0] DataToCore,
  input[31:0] DataFromCore,
  input[31:0] DataAddress
);

endmodule