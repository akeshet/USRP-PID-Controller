module OneMHzOscillator(input wire clk64, output wire out, output wire signed [5:0] counter);

reg outReg;
reg signed [5:0] counReg;

assign out = outReg;
assign counter=counReg;

initial begin
	outReg<=0;
	counReg<=0;
end

always @(posedge clk64) begin
	counReg<=counReg+1;
	if (counReg==0) begin
		outReg<=0;
	end
	else if (counReg==-32) begin
		outReg<=1;
	end;
end

endmodule
