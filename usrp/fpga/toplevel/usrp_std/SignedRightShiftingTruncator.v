/* Signed right-shifting value truncator.

Aviv Keshet 2009

I am a signed right-shifting truncator.
I take a signed input, and return a signed output which has the input right-shifted by rightShiftBits bits.
I am smart enough to make sure that the output value saturates at some max and min values.

You can set all these values by instantiating me with the parameters you want.
*/


module SignedRightShiftingTruncator(inWire, outWire);

// default parameter values are probably not what you want
parameter inLen = 10;
parameter outLen = 5;
parameter rightShiftBits = 2;
parameter maxValue;
parameter minValue;

input signed [inLen-1:0] inWire;
output signed [outLen-1:0] outWire;


assign outWire = ((inWire>>>rightShiftBits) > maxValue) ? maxValue : ( ((inWire>>>rightShiftBits) < minValue) ? minValue : inWire>>>rightShiftBits); 


endmodule

