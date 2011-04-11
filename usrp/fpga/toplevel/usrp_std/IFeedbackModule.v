/*
		I Feedback verilog module
		
		This is a slimmed-down modification of the PID Feedback module.
		This module only has I gain, which is all you need most of the time.
		As a result, it can be somewhat faster and take up less FPGA real estate.
		
		Aviv Keshet, 2009		
		*/
				

module Ifeedback
(
	input wire  clock,
	input wire signed  [11:0] measSignalIn,
	input wire signed [11:0] setpointSignalIn,
	output wire signed [13:0] controlSignalOut,
	input wire signed [20:0] iGainIn,
	input wire intReset,
	input wire intHold,
	output wire signed [13:0] errorMonitorOut
);


/// PARAMETERS
/// ********************************
// this parameter sets the number of cycles over which the D term "averages" the derivative.

parameter iGainAdjust = 20; // the I term will be right-shifted by this number of bits before being added to the 
						   // control signal register. Increase this number to decrease I gain.

parameter dGainAdjust = 5; // the D term will be right shifted by this number of bits before being added to the 
							// control signal register. Increase this number to decrease D gain.
							
parameter totalGainAdjust = 2; // the PID terms will all be right-shifted by this amount before being connected to the 
							   // control signal output.
							   


parameter controlSignalRegisterSize = 51; // bit depth of the intermediate register for computing 
									      // control signal output


/// CODE
/// *******************************


// the following wires are redundant, but I leave them in for now
// they should make no different at all to the synthesized bit code
wire signed [11:0] signedMeasIn, signedSetIn;
assign signedMeasIn = measSignalIn;
assign signedSetIn = setpointSignalIn;

// error is 12 bits in size, since it is the difference of two 11 bit numbers.
// I am trying everywhere to ensure that overflows are impossible.
reg signed [12:0] error /*= signedSetIn - signedMeasIn*/; 

// monitor output for error signal. 13 bits wide to 
assign errorMonitorOut = error <<< 1;


// register in which the total control signal is calculated
reg signed [controlSignalRegisterSize-1:0] controlSignal;

reg signed [controlSignalRegisterSize-2:0] iAccum;
reg signed [controlSignalRegisterSize-2:0] iAccum2;

wire antiWindupIntDisable;
assign antiWindupIntDisable = 	((controlSignalOut==8191) &&(error>0)&&(iAccum>0)) ||
								((controlSignalOut==-8192)&&(error<0)&&(iAccum<0));

always @(posedge clock) begin

	error <= signedSetIn - signedMeasIn;

    // CALCULATE I term
	if ((intReset) | (iGainIn==0)) begin // reset the intergrator if the I gain
		iAccum<=0;						 // is set to zero, or if the I reset input goes high
		iAccum2<=0; 
	end
	else 
	if (~intHold) begin	
		iAccum<= iAccum + iAccum2;
		
	// new version of integrator with smart anti-windup
		if (~antiWindupIntDisable) begin
			iAccum2<= error*iGainIn;
		end	
		else begin
			iAccum2<=0;
		end
	
	// old version of integrator with natural decay rate.
	/*
		iAccum<=iAccum2 + iGainIn * error;
		// the following line of code gives the integrator a slow natural decay
		// to eliminate the possibility of integrator overflow
		// (ie at the very maximum value of the integrator, and the very maximum I gain and the very maximum error signal,
		// the amount of decay exactly cancels the amount of integration. I think. In reality we should never get to such
		// extreme conditions so I'm pretty sure we are overflow proof here)
		// for the current controlSignalRegisterSize of 51, the time constant of integrator decay is ~ 2 ms.
		// this is probably good enough for most of the things we will be controlling, but we may need to reconsider
		iAccum2<=iAccum - (iAccum >>> (controlSignalRegisterSize - 34));
		*/
		
	end	
	
	
	// Add everything up.
	// this is pipelined in such a way that it should work at 64 MHz.
	// this is verified by examining the timing report after compiling and making
	// sure that there are no unmet timing constaints in the 
	// "Classic Timing Analysis" report
	controlSignal <= (iAccum>>>iGainAdjust);
end


// the following code right-shifts the value of controlSignal by rightShiftBits bits, and then assigns it to controlSignalOut
// it does so in such a way as to intelligently handle overflow conditions by saturing the controlSignalOut
// value to lie between -8192 and + 8191.
defparam shifterParameters.inLen 			= controlSignalRegisterSize;
defparam shifterParameters.outLen 			= 14;				// controlSignalOutLength bit depth is 14
defparam shifterParameters.rightShiftBits 	= totalGainAdjust;
defparam shifterParameters.maxValue			= 8191;				// 2^13-1   , since controlSignalOut is a 14bit signed number
defparam shifterParameters.minValue			= -8192;			// -(2^13) 

SignedRightShiftingTruncator shifterParameters (.inWire(controlSignal), .outWire(controlSignalOut));


endmodule
