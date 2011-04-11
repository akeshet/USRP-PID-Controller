/*

Mixer module.

Aviv Keshet, 2009.




The output is either + or - the input, depending on
the sign and phase of the oscillator.
The sign and phase information enter this module through the 
signIn and counterIn inputs.
User settable phase of mixer is set by phaseIn input.
Optional invert signal is fed in throughb invertIn input.

*/


module Mixer(clk64, inWire, signIn, counterIn, phaseIn, outWire);

	parameter inBitDepth;
	parameter counterBitDepth;

	input wire clk64;
	input wire signed [inBitDepth-1:0] inWire;
	input wire signIn;
	input wire [counterBitDepth-1:0] phaseIn;
	input wire [counterBitDepth-1:0] counterIn;
	output wire signed [inBitDepth:0] outWire;		// output can in principle have 1 bit more
													// than input (ie -(-8192) = 8192 == 14 bit signed number


reg internalSign;
reg signed [inBitDepth:0] outReg;
assign outWire = outReg;


always @(posedge clk64) begin

	// whenever the oscillator phase matches the user-set phase, then
	// take the oscillator's value and stick it in the local sign register
	if (counterIn==phaseIn) begin
		internalSign<= signIn;
	end


	// now, assign either + or - the input to the output,
	// depending on  the internal sign register.
	if (internalSign) begin
		outReg <= (inWire);
	end
	else begin
		outReg <= -(inWire);
	end
end



endmodule


// old non-parameterized version of mixer.
// with fixed input and output width
// and with extra output bits for no real reason
/*
module Mixer(
	input wire clk64,
	input wire signed [11:0] inWire, 
	input wire signIn, 
	input wire [4:0] counterIn, 
	input wire [4:0] phaseIn,
	input wire invertIn,
	output wire signed [22:0] outWire);

reg internalSign;
reg signed [22:0] iAccum;
assign outWire = iAccum;


always @(posedge clk64) begin

	// whenever the oscillator phase matches the user-set phase, then
	// take the oscillator's value and stick it in the local sign register
	if (counterIn==phaseIn) begin
		internalSign<= invertIn ? (~signIn) : (signIn);
	end


	// now, assign either + or - the input to the output,
	// depending on  the internal sign register.
	if (internalSign) begin
		iAccum <= (inWire<<<10);
	end
	else begin
		iAccum <= -(inWire<<<10);
	end
end

endmodule
*/