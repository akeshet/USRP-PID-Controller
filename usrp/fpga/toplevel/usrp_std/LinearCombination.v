/*

	Linear Combination module
	Aviv Keshet, 2009

	Create a linear combination of input1 and input 2, 
	and output it to outputWire.
*/

module LinearCombination(
	input wire clk64,
	input wire signed [13:0] input1,
	input wire signed [13:0] input2,
	input wire signed [20:0] gain1,
	input wire signed [20:0] gain2,
	output wire signed [13:0] outputWire);


reg signed [35:0] largeOutputReg;
reg signed [34:0] intermedReg1, intermedReg2;

reg signed [13:0] input1Reg, input2Reg; // add 1 cycle of latency.
										// but helps satisfy FPGA timing constraints

always @(posedge clk64) begin

	input1Reg<=input1;
	input2Reg<=input2;

	intermedReg1<=input1Reg * gain1;
	intermedReg2<=input2Reg * gain2;
	largeOutputReg<=intermedReg1 + intermedReg2;
end



	defparam shifterParameters.inLen 			= 36;
	defparam shifterParameters.outLen 			= 14;				
	defparam shifterParameters.rightShiftBits 	= 10;
	defparam shifterParameters.maxValue			= 8191;				// 2^13-1   
	defparam shifterParameters.minValue			= -8192;			// -(2^13) 
	// create shifter:
	SignedRightShiftingTruncator shifterParameters (.inWire(largeOutputReg), .outWire(outputWire));


endmodule
