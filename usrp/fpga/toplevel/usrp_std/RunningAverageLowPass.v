module RunningAverageLowPass(clock, inWire, outWire);

parameter inBitDepth;
parameter outBitDepth;
parameter nAverageSamples;

input wire clock;
input wire signed [inBitDepth-1:0] inWire;
output wire signed [outBitDepth-1:0] outWire;

reg signed [outBitDepth-1:0] outReg;
assign outWire = outReg;

reg signed [inBitDepth-1:0] shiftRegister [nAverageSamples-2:0];

integer i;

always @(posedge clock) begin

	shiftRegister[0]<=inWire;
	for (i=1; i<(nAverageSamples-1); i=i+1) begin
		shiftRegister[i]<=shiftRegister[i-1];
	end
	
	outReg<=outReg + inWire - shiftRegister[nAverageSamples-2];
	
end


endmodule
