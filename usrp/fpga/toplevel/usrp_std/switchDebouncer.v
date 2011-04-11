module switchDebouncer(input wire clkIn, input wire buttonIn, output reg buttonOut);

reg [20:0] counter;

always @(posedge clkIn) begin
	if (buttonOut==buttonIn) begin
		counter<=0;
	end
	else begin
		if (counter==100000) begin
			counter<=0;
			buttonOut<=buttonIn;
		end
		else begin
			counter<=counter+1;
		end
	end
end


endmodule
