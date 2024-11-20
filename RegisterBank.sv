`default_nettype none

module registerbank(
  input Clock,
  input Reset,
  input ActiveMode,
  
  input[3:0] Source1Address,
  input[3:0] Source2Address,
  input[3:0] TargetAddress,
  
  input TargetWriteEnable,
  input[31:0] TargetIn,
  
  output[31:0] Source1Out,
  output[31:0] Source2Out,

  output[31:0] InstructionPointerOut
);

  logic[31:0] RegisterBank[15:0];

  always_ff@(posedge Clock) begin
    if(Reset) begin
      for(int i = 0; i < 16; i = i + 1) begin
        RegisterBank[i] = '0;
      end
    end else begin
    	if(TargetWriteEnable && TargetAddress != 0) begin
    	  RegisterBank[TargetAddress] <= TargetIn;
    	end

    	if((TargetAddress != 15) && ActiveMode) begin
   	    RegisterBank[15] <= RegisterBank[15] + 4;
      end
    end
  end
  
  assign Source1Out = RegisterBank[Source1Address];
  assign Source2Out = RegisterBank[Source2Address];
  assign InstructionPointerOut = RegisterBank[15];
endmodule
