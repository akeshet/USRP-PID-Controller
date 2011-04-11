module LowPassFilter(clkIn, inWire, outWire);

parameter inBitDepth;
parameter outBitDepth;
parameter decayBitShift;
parameter outputBitShift;
parameter maximumOutputValue;
parameter minimumOutputValue;

parameter iAccumSize = outBitDepth+outputBitShift;

input clkIn;
input signed [inBitDepth-1:0] inWire;
output signed [outBitDepth-1:0] outWire;

reg signed [iAccumSize:0] iAccum;

always @(posedge clkIn) begin
	iAccum<=iAccum + inWire - (iAccum>>>decayBitShift);
end


defparam shifterParameters.inLen 			= outBitDepth-1+outputBitShift+1;
defparam shifterParameters.outLen 			= outBitDepth;				
defparam shifterParameters.rightShiftBits 	= outputBitShift;
defparam shifterParameters.maxValue			= maximumOutputValue;		
defparam shifterParameters.minValue			= minimumOutputValue;		

SignedRightShiftingTruncator shifterParameters (.inWire(iAccum), .outWire(outWire));


endmodule
