/*

Triangle Wave Generator module
Aviv Keshet, 2009.


Outputs are 14 bit triangle wave, with run-time settable
maximum value, minimum value, and ramp speed.

Also creates a 1-bit digital sync ouptut, suitable for sending to a scope.

*/


module TriangleWaveGenerator(
	input wire clock,
	input wire signed [31:0] stepSize, 
	input wire signed [13:0] maxOut, 
	input wire signed [13:0] minOut,
	input wire reset,
	output wire signed [13:0] out,
	output wire sync
	);
	

reg signed [34:0] counter;
reg signed up;


always @(posedge clock) begin

	if (reset) begin
		counter<=(minOut<<<20);
		up<=1;
	end
	else begin
		if (up) begin
			if (((maxOut<<<20)-counter)<stepSize) begin
				up<=0;
			end
			else begin
				counter<=counter+stepSize;
			end
		end
		else begin
			if ((counter-(minOut<<<20))<stepSize) begin
				up<=1;
			end
			else begin
				counter<=counter-stepSize;
			end
		end
	end
end

defparam shifterParameters.inLen 			= 35;
defparam shifterParameters.outLen 			= 14;				
defparam shifterParameters.rightShiftBits 	= 20;
defparam shifterParameters.maxValue			= 8191;				// 2^13-1   
defparam shifterParameters.minValue			= -8192;			// -(2^13) 
// create shifter:
SignedRightShiftingTruncator shifterParameters (.inWire(counter), .outWire(out));
	
// sync pulse goes high halfway through the ramp
// this is more convenient than at the top or bottom of the ramp, for scope
// viewing purposes.
assign sync = (out > ((maxOut + minOut)>>>1));

endmodule
