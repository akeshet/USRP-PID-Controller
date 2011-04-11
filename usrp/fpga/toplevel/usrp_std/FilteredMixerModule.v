/*

Mixer module with pre- and post- filtering.

Aviv Keshet, 2009.


*/


module FilteredMixerModule(
	input wire master_clk,
	output wire signed [13:0] tx_out, 
	input wire signed [11:0] rx_in, 
	input wire signed [15:0] gainRegIn, 
	input wire signed [5:0] phaseRegIn,
	input wire signed [5:0] OscCounter,
	input wire OscSign);
	
	parameter nPostFilterAverageSamples = 1024;
	parameter log2nPostFilterAverageSamples = 10;


	// We will DC-block the input.
	// By generating a low pass filtered verion of the input and subtracting it from the input.
	// ***************
	
	wire signed [20:0] prefilter_lowPassOutReg;					// output of low pass filter
	// filter parameters:
	defparam prefilter_lowPass.inBitDepth 				= 12;   // input to filter has 12 bit depth
	defparam prefilter_lowPass.outBitDepth				= 21;   // output has 9 extra bits
	defparam prefilter_lowPass.nAverageSamples			= 512;  // because it is a sum of 512 samples (=2^9)
	// create filter:
	RunningAverageLowPass prefilter_lowPass (.inWire(rx_in), .clock(master_clk), .outWire(prefilter_lowPassOutReg));
	
	// generate the DC-blocked version of the input
	reg signed [12:0] rx_intermediate;
	always @(posedge master_clk) begin
		rx_intermediate<= rx_in - (prefilter_lowPassOutReg>>>9);
		// (shift the low pass output by 9 to scale it appropriately)
	end




	// Mix the DC-blocked version with 1MHz oscillator
	// ********************
	
	defparam myMixer.inBitDepth = 13;
	defparam myMixer.counterBitDepth=6;
	
	wire signed [13:0] MixerOut;	// output of mixer has 1 bit more than input
	Mixer myMixer(
		.clk64(master_clk),
		.inWire(rx_intermediate), 
		.counterIn(OscCounter), 
		.outWire(MixerOut), 
		.phaseIn(phaseRegIn), 
		.signIn(OscSign));
   
   
   
	// Low pass the mixer output
	// *******************************
	wire signed [13+log2nPostFilterAverageSamples:0] lowPassOutReg;
	defparam lowPass.inBitDepth 				= 14;
	defparam lowPass.outBitDepth				= 14 + log2nPostFilterAverageSamples;
	defparam lowPass.nAverageSamples			= nPostFilterAverageSamples;
	RunningAverageLowPass lowPass (.inWire(MixerOut), .clock(master_clk), .outWire(lowPassOutReg));
   
	
	
	// Apply run-time selectable gain to output
	// ****************************
	
	// Note: This gain operation was first tried without using a register to shelve the data for
	// 1 cycle. But this produced glitches which apparently are timing glitches.
	// The disturbing thing is that this potential timing problem was not recognized or flagged by the timing analyzer.
	reg signed [29+log2nPostFilterAverageSamples:0] amplifiedLowPassOutReg;
	always @(posedge master_clk)
		amplifiedLowPassOutReg<=lowPassOutReg*gainRegIn;
	


	// Shift the amplified output to the right to scale it appropriately
	// **************************
	// shifter parameters:
	defparam shifterParameters.inLen 			= 30 + log2nPostFilterAverageSamples;
	defparam shifterParameters.outLen 			= 14;				
	defparam shifterParameters.rightShiftBits 	= 5 + log2nPostFilterAverageSamples;
	defparam shifterParameters.maxValue			= 8191;				// 2^13-1   
	defparam shifterParameters.minValue			= -8192;			// -(2^13) 
	// create shifter:
	SignedRightShiftingTruncator shifterParameters (.inWire(amplifiedLowPassOutReg), .outWire(tx_out));
	
endmodule
