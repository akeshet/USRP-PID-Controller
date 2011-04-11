

module setting_reg
  ( input clock, input reset, input strobe, input wire [6:0] addr,
    input wire [31:0] in, output reg [31:0] out, output reg changed,
    input wire overrideStrobe, input wire[31:0] overrideIn);
   parameter my_addr = 0;
   
   always @(posedge clock)
     if(reset) begin
	  out <= 0;
	  changed <= 1;
     end
     else if(strobe & (my_addr==addr)) begin
	    out <= in;
	    changed <= 1;
	 end else if (overrideStrobe) begin
			out<=overrideIn;
			changed<=1;
		end
	 else
		changed <= 0;
   
endmodule // setting_reg
