module HighPassFilter(clkIn, inWire, outWire);

parameter inBitDepth;
parameter outBitDepth;
parameter rollOffCycles;
parameter outputBitShift;
parameter maximumOutputValue;
parameter minimumOutputValue;

input clkIn;
input signed [inBitDepth-1:0] inWire;
output signed [outBitDepth-1:0] outWire;


reg signed [inBitDepth+rollOffCycles:0] dReg;
reg signed [inBitDepth:0] history [rollOffCycles-1:0];

integer i;

always @(posedge clkIn) begin

	history[0]<=inWire;
	for (i=1; i<rollOffCycles; i=i+1) begin
		history[i]<=history[i-1];
	end
	
	dReg<=dReg + history[0] + history[rollOffCycles-1] - (history[((rollOffCycles+1)/2)+1]<<<1);
	
end


defparam shifterParameters.inLen 			= inBitDepth+rollOffCycles;
defparam shifterParameters.outLen 			= outBitDepth;				
defparam shifterParameters.rightShiftBits 	= outputBitShift;
defparam shifterParameters.maxValue			= maximumOutputValue;		
defparam shifterParameters.minValue			= minimumOutputValue;		

SignedRightShiftingTruncator shifterParameters (.inWire(dReg), .outWire(outWire));


endmodule
