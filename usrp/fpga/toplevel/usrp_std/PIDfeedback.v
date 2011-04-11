/*
		PID Feedback verilog module
		
		Aviv Keshet, 2009		
		*/
		
		
	
/*
		This version of the PID controller supports analog input of both the measured and the setpoint.
*/	

/*  All inputs and outputs are expected to be 2-s complement signed numbers
	
	The USRP's DACs and ADCs have built-in support for 2-s complement.
	See the AD9862 data sheet for more info.
	The relevant registers than must be written to are registers 5 and 18.
	
*/


/* A few words on latency:
		
		in addition to the ADC and DAC latency (a total of 16 cycles), this module introduces:
		
		1 cycle of latency for the D term.
		2 cycles of latency for the P term.
		3 cycles of latency for the I term.
		
		*/
		
/* The gain inputs are treated as signed 21 bit numbers,
   despite the fact that making them negative makes no sense.
   The reason is that in verilog, you only get signed arithmetic if all the 
   terms in your arithmetic are signed.
   
   The maximum value for any of the gains is 2^20-1. Going above this will 
   create a positive feedback controller, which is an abomination.
   */
   
   
/* A word for the wise.

	This module makes extensive use of the arithmetic right shift operator >>>.
	This operator is not to be confused with the plain old vanilla right shift operator >>.
	
	>>>, when faced with a signed 2's complement number, knows how to intelligently deal with shifting the sign bit around.
	>> is just a bit shifter, with no smarts whatsoever, and will turn your
	math into garbage if you give it a negative 2's complement number.
	*/

module PIDfeedback
(
	input wire  clock,
	input wire signed  [11:0] measSignalIn,
	input wire signed [11:0] setpointSignalIn,
	output wire signed [13:0] controlSignalOut,
	input wire signed [13:0] overrideControlSignalIn,
	input wire signed [20:0] pGainIn,
	input wire signed [20:0] iGainIn,
	input wire signed [20:0] dGainIn,
	input wire intReset,
	input wire intHold,
	input wire intSetValueFromOverride,
	output wire signed [13:0] errorMonitorOut
);


/// PARAMETERS
/// ********************************
// this parameter sets the number of cycles over which the D term "averages" the derivative.
parameter dRegDelay = 24; // if you change this, you should also change the width of the dReg register to be 
						  // 14 + 21 + log2(dRegDelay) + 1 bits wide. 
						  // dRegDelay should be an even number.
						  // making this bigger effectively reduces the frequency cutoff of the D term

parameter dRegMiddle = (dRegDelay)/2;

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
reg signed [controlSignalRegisterSize-2:0] PIterms;
reg signed [controlSignalRegisterSize-2:0] dReg;
reg signed [controlSignalRegisterSize-2:0] pTerm;

// an array of registers used for calculating the D term
// side complaint: the syntax for dealing with arrays in verilog sux!

// D TERM CURRENTLY DISABLED FOR REDUCED FOOTPRINT AND FASTER COMPILATION
 reg signed [34:0] dErrorHist [dRegDelay:0];

reg signed [20:0] olddGainIn;

integer i;

wire antiWindupIntDisable;

assign antiWindupIntDisable = 	((controlSignalOut==8191) &&(error>0)&&(iAccum>0)) ||
								((controlSignalOut==-8192)&&(error<0)&&(iAccum<0));
								

always @(posedge clock) begin

	error <= signedSetIn - signedMeasIn;

	// CALCULATE D term
	olddGainIn<=dGainIn;
	if ((dGainIn==0)|(dGainIn!=olddGainIn)) begin // reset all the D-related registers if the dGain is set to 0
												  // or if it has just changed
		for (i=0; i<(dRegDelay+1); i=i+1) begin
			dErrorHist[i]<=0;                     // aside: see how sucky the verilog array syntax is?
											      // doesn't this line invite confusion about if we are
												  // dereferencing and array element, or a specific bit of the variable?
		end
		dReg<=0;
	end
	else begin
		dErrorHist[0]<=dGainIn * error;         // pop in the latest error term to the D history register
		for (i=1; i<dRegDelay+1; i=i+1) begin  // and shift the whole array of D history registers
			dErrorHist[i]<=dErrorHist[i-1];
		end
		
		// this line is basically the impulse response of the D term.
		// when hit with a unit 1-sample long impulse, the D term will
		// go high to dGain*1, stay there for dRegMiddle+1 cycles,
		// then go low to -dGain*1 and stay there for another dRegMiddle cycles+1
		// and then go back to 0.
		// The following is a handy and compact way to implement this simplified "finite bandwidth derivative" response.
		// There are probably smarter ways.
		dReg<=dReg + dErrorHist[0] + dErrorHist[dRegDelay] - (dErrorHist[dRegMiddle]<<<1);
		//dReg<= dErrorHist[0] - dErrorHist[dRegDelay];
	end




    // CALCULATE I term
    if (intSetValueFromOverride) begin
		iAccum <= (overrideControlSignalIn <<< (iGainAdjust + totalGainAdjust));
	end else 
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
		
		/* // old version of integrator with natural decay
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
	
	pTerm <= pGainIn * error;
	// Add everything up.
	// this is pipelined in such a way that it should work at 64 MHz.
	// this is verified by examining the timing report after compiling and making
	// sure that there are no unmet timing constaints in the 
	// "Classic Timing Analysis" report
	PIterms <= pTerm + (iAccum>>>iGainAdjust);
	controlSignal <= (dReg>>>dGainAdjust) + PIterms;
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
